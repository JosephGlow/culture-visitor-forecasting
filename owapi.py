import datetime as dt
import json
import logging
import sys
import threading
import time
from collections import Counter
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from statistics import mean
from zoneinfo import ZoneInfo

import MySQLdb
import requests

API_KEY = Path('/srv/api/keys/owapikey.txt').read_text().strip()
DB = dict(unix_socket='/run/mysqld/mysqld.sock', user='user', db='nml',
          charset='utf8mb4')
TIMEMACHINE = 'https://api.openweathermap.org/data/3.0/onecall/timemachine'
SOURCES = json.dumps(["OpenWeather"])
AGGREGATED_SOURCES = json.dumps(["Derived from weather_hourly"])   # same label as the import notebook and build_3hourly.py

HARD_LIMIT = 1000
WORKERS = 3
CHUNK = 100
RETRY_PAUSE = 5

LOCAL_TZ = ZoneInfo('Europe/London')
RECHECK_HOURS = 720
RECHECK_DAYS = 30
MAX_MISSING_HOURS = 6
DEFAULT_OPEN = range(10, 17)
BLOCK = 3

AREAS = {
    'waterfront':     ('53.40', '-3.00'),
    'williambrownst': ('53.41', '-2.98'),
    'sudleyhouse':    ('53.37', '-2.92'),
    'portsunlight':   ('53.36', '-3.00'),
}

COLS = ['dt', 'area', 'temp_c', 'feels_like_c', 'dew_point_c', 'visibility_m',
        'clouds_pct', 'wind_speed_ms', 'wind_gust_ms', 'rain_1h_mm',
        'snow_1h_mm', 'weather_id', 'weather_desc', 'sources']
NUMERIC = ['temp_c', 'feels_like_c', 'dew_point_c', 'visibility_m', 'clouds_pct',
           'wind_speed_ms', 'wind_gust_ms', 'rain_1h_mm', 'snow_1h_mm']
SUMMED = {'rain_1h_mm', 'snow_1h_mm'}
DAILY_COLS = (['date', 'area'] + NUMERIC + ['weather_id', 'weather_desc']
              + ['oh_' + c for c in NUMERIC] + ['oh_weather_id', 'oh_weather_desc']
              + ['sources'])
BLOCK_COLS = ['start_dt', 'area'] + NUMERIC + ['weather_id', 'weather_desc', 'sources']

log = logging.getLogger('owapi')
_local = threading.local()


def upsert(table, cols, keys):
    return (f"INSERT INTO {table} ({','.join(cols)}) "
            f"VALUES ({','.join(['%s'] * len(cols))}) ON DUPLICATE KEY UPDATE "
            + ','.join(f"{c}=VALUES({c})" for c in cols if c not in keys))


INSERT = upsert('weather_hourly', COLS, ('dt', 'area'))
DAILY_INSERT = upsert('weather_daily', DAILY_COLS, ('date', 'area'))
BLOCK_INSERT = upsert('weather_3hourly', BLOCK_COLS, ('start_dt', 'area'))


def query(db, sql, params=()):
    with db.cursor() as cur:
        cur.execute(sql, params)
        return cur.fetchall()


def write(db, sql, rows):
    with db.cursor() as cur:
        cur.executemany(sql, rows)
    db.commit()


def to_utc(local):
    return local.replace(tzinfo=LOCAL_TZ).astimezone(dt.timezone.utc).replace(tzinfo=None)


def to_local(utc):
    return utc.replace(tzinfo=dt.timezone.utc).astimezone(LOCAL_TZ)


def midnight_utc(d):
    return to_utc(dt.datetime.combine(d, dt.time()))


def day_length(d):
    """23 or 25 on the clock-change days."""
    return int((midnight_utc(d + dt.timedelta(days=1))
                - midnight_utc(d)).total_seconds() // 3600)


def default_open(d):
    return {to_utc(dt.datetime.combine(d, dt.time(h))) for h in DEFAULT_OPEN}


def fetch(area, when):
    if not hasattr(_local, 'session'):
        _local.session = requests.Session() #not thread-safe, so one each
    lat, lon = AREAS[area]
    r = _local.session.get(TIMEMACHINE, timeout=30, params={
        'lat': lat, 'lon': lon, 'units': 'metric', 'appid': API_KEY,
        'dt': int(when.replace(tzinfo=dt.timezone.utc).timestamp())})
    r.raise_for_status()
    d = r.json()['data'][0]
    w = (d.get('weather') or [{}])[0]
    # OpenWeather leaves out rain and snow for an hour with none, so null values are stored as 0.00.
    # Wind gust stays null when absent.
    rain, snow = d.get('rain') or {}, d.get('snow') or {}
    return (dt.datetime.fromtimestamp(d['dt'], dt.timezone.utc).replace(tzinfo=None),
            area, d.get('temp'), d.get('feels_like'), d.get('dew_point'),
            d.get('visibility'), d.get('clouds'), d.get('wind_speed'),
            d.get('wind_gust'), rain.get('1h', 0.0), snow.get('1h', 0.0),
            w.get('id'), w.get('description') or None, SOURCES)


def fetch_all(work):
    """work: [(area, hour)]. Returns (rows, [(area, hour, status)])."""
    rows, failed = [], []

    def one(job):
        area, when = job
        try:
            return job, fetch(area, when)
        except requests.HTTPError as e:
            return job, (e.response.status_code if e.response is not None else None)
        except requests.RequestException:
            return job, None

    with ThreadPoolExecutor(max_workers=WORKERS) as pool:
        for (area, when), result in pool.map(one, work):
            if isinstance(result, tuple):
                rows.append(result)
            else:
                failed.append((area, when, result))
    return rows, failed


def gaps(db, area, now):
    latest = query(db, "SELECT MAX(dt) FROM weather_hourly WHERE area = %s", (area,))[0][0]
    if latest is None:
        log.warning("%s: no rows to anchor to", area)
        return []
    start = min(latest + dt.timedelta(hours=1), now - dt.timedelta(hours=RECHECK_HOURS))
    have = {r[0] for r in query(
        db, "SELECT dt FROM weather_hourly WHERE area = %s AND dt >= %s", (area, start))}
    hours, t = [], start
    while t <= now:
        if t not in have:
            hours.append(t)
        t += dt.timedelta(hours=1)
    return hours


def backfill(db):
    now = dt.datetime.now(dt.timezone.utc).replace(minute=0, second=0, microsecond=0,
                                                   tzinfo=None)
    work = sorted(((a, h) for a in AREAS for h in gaps(db, a, now)), key=lambda j: j[1])
    if not work:
        log.info("hourly up to date")
        return
    log.info("%d hours missing, fetching %d", len(work), min(len(work), HARD_LIMIT))
    work, used = work[:HARD_LIMIT], 0

    for i in range(0, len(work), CHUNK):
        chunk = work[i:i + CHUNK]
        rows, failed = fetch_all(chunk)
        used += len(chunk)

        if failed and used + len(failed) <= HARD_LIMIT and not any(
                s == 429 for *_, s in failed):
            time.sleep(RETRY_PAUSE)
            more, failed = fetch_all([(a, h) for a, h, _ in failed])
            used += len(more) + len(failed)
            rows += more

        if rows:
            write(db, INSERT, rows)
        log.info("committed %d, failed %d, %d calls used", len(rows), len(failed), used)
        if failed:
            log.info("  %s, e.g. %s", Counter(s for *_, s in failed),
                     [str(h) for _, h, _ in failed[:3]])
        if any(s == 429 for *_, s in failed):
            log.warning("quota rejected, stopping")
            return


def summarise(rows):
    out = []
    for i, col in enumerate(NUMERIC, start=1):
        vals = [r[i] for r in rows if r[i] is not None]
        if not vals:
            out.append(None)
        else:
            out.append(round(sum(vals) if col in SUMMED else mean(vals), 2))
    ids = [r[-2] for r in rows if r[-2] is not None]
    if not ids:
        return out + [None, None]
    wid = Counter(ids).most_common(1)[0][0]
    return out + [wid, next(r[-1] for r in rows if r[-2] == wid)]


def rollup(db):
    today = dt.datetime.now(LOCAL_TZ).date()
    start = today - dt.timedelta(days=RECHECK_DAYS)

    for area in AREAS:
        by_day = {}
        for r in query(db, f"SELECT dt,{','.join(NUMERIC)},weather_id,weather_desc "
                           "FROM weather_hourly WHERE area = %s AND dt >= %s",
                       (area, midnight_utc(start))):
            by_day.setdefault(to_local(r[0]).date(), []).append(r)

        open_by_day = {}
        for (v,) in query(db, "SELECT DISTINCT v.datetime FROM visits_hourly v "
                              "JOIN venue ON venue.id = v.venue_id WHERE venue.area = %s "
                              "AND v.visits IS NOT NULL AND v.datetime >= %s",
                          (area, dt.datetime.combine(start, dt.time()))):
            open_by_day.setdefault(v.date(), set()).add(to_utc(v))

        rows, skipped, defaulted = [], 0, 0
        for d, hours in sorted(by_day.items()):
            if d >= today:
                continue
            if len(hours) < day_length(d) - MAX_MISSING_HOURS:
                skipped += 1
                continue
            open_hrs = open_by_day.get(d)
            if not open_hrs:
                open_hrs, defaulted = default_open(d), defaulted + 1
            oh = [h for h in hours if h[0] in open_hrs]
            rows.append(tuple([d, area] + summarise(hours)
                              + (summarise(oh) if oh else [None] * (len(NUMERIC) + 2))
                              + [AGGREGATED_SOURCES]))
        if rows:
            write(db, DAILY_INSERT, rows)
        log.info("%s: %d days aggregated, %d default hours, %d skipped",
                 area, len(rows), defaulted, skipped)


def rollup_3h(db):
    now = dt.datetime.now(LOCAL_TZ).replace(tzinfo=None)
    start = (now - dt.timedelta(days=RECHECK_DAYS)).date()

    for area in AREAS:
        blocks = {}
        for r in query(db, f"SELECT dt,{','.join(NUMERIC)},weather_id,weather_desc "
                           "FROM weather_hourly WHERE area = %s AND dt >= %s",
                       (area, midnight_utc(start))):
            local = to_local(r[0]).replace(tzinfo=None)
            key = local.replace(hour=local.hour // BLOCK * BLOCK, minute=0, second=0)
            blocks.setdefault(key, []).append(r)

        rows, skipped = [], 0
        for k, hours in sorted(blocks.items()):
            if k + dt.timedelta(hours=BLOCK) > now:
                continue
            if len(hours) < BLOCK - 1:
                skipped += 1
                continue
            rows.append(tuple([k, area] + summarise(hours) + [AGGREGATED_SOURCES]))
        if rows:
            write(db, BLOCK_INSERT, rows)
        log.info("%s: %d blocks aggregated, %d skipped", area, len(rows), skipped)


def main():
    logging.basicConfig(level=logging.INFO, stream=sys.stdout,
                        format='%(asctime)s %(levelname)s %(message)s',
                        datefmt='%Y-%m-%d %H:%M:%S')
    db = None
    try:
        db = MySQLdb.connect(**DB)
        backfill(db)
        rollup(db)
        rollup_3h(db)
        return 0
    except Exception:
        log.exception("run failed")
        return 1
    finally:
        if db is not None:
            db.close()


if __name__ == '__main__':
    sys.exit(main())
