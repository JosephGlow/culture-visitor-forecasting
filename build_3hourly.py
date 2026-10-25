import datetime as dt
import json
import sys
from collections import Counter
from statistics import mean
from zoneinfo import ZoneInfo
import os

import mysql.connector
from sshtunnel import SSHTunnelForwarder

with open('db_config.json') as f:
    DB_CFG = json.load(f)

tunnel = SSHTunnelForwarder((DB_CFG["ssh_host"], int(DB_CFG["ssh_port"])), ssh_username=DB_CFG["ssh_user"], ssh_pkey=os.path.expanduser(DB_CFG["ssh_pkey"]), remote_bind_address=("127.0.0.1", 3306))
tunnel.start()
mydb = mysql.connector.connect(host="127.0.0.1", port=tunnel.local_bind_port, user=DB_CFG["db_user"], database=DB_CFG.get("db_name", "nml"))

def query(sql):
    """Query database with SQL syntax as a string (or fstring)."""
    cursor = mydb.cursor()
    cursor.execute(sql)
    return(cursor.fetchall())

REBUILD = False #True ignores what's already there and redoes everything
BATCH = 5000
BLOCK = 3
MIN_HOURS = BLOCK - 1
LOCAL_TZ = ZoneInfo('Europe/London')
SOURCES = json.dumps(["Derived from weather_hourly"])

AREAS = ['waterfront', 'williambrownst', 'sudleyhouse', 'portsunlight']
NUMERIC = ['temp_c', 'feels_like_c', 'dew_point_c', 'visibility_m', 'clouds_pct',
           'wind_speed_ms', 'wind_gust_ms', 'rain_1h_mm', 'snow_1h_mm']
SUMMED = {'rain_1h_mm', 'snow_1h_mm'}
COLS = ['start_dt', 'area'] + NUMERIC + ['weather_id', 'weather_desc', 'sources']

INSERT = (f"INSERT INTO weather_3hourly ({','.join(COLS)}) "
          f"VALUES ({','.join(['%s'] * len(COLS))}) ON DUPLICATE KEY UPDATE "
          + ','.join(f"{c}=VALUES({c})" for c in COLS if c not in ('start_dt', 'area')))


def to_local(utc):
    return utc.replace(tzinfo=dt.timezone.utc).astimezone(LOCAL_TZ)


def midnight_utc(d):
    return (dt.datetime.combine(d, dt.time()).replace(tzinfo=LOCAL_TZ)
            .astimezone(dt.timezone.utc).replace(tzinfo=None))

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


def blocks_for_year(area, year, cutoff):
    """All complete 3-hour blocks whose local date falls in `year`."""
    rows = query(f"SELECT dt,{','.join(NUMERIC)},weather_id,weather_desc "
                 f"FROM weather_hourly WHERE area = '{area}' "
                 f"AND dt >= '{midnight_utc(dt.date(year, 1, 1))}' "
                 f"AND dt < '{midnight_utc(dt.date(year + 1, 1, 1))}' ORDER BY dt")
    buckets = {}
    for r in rows:
        local = to_local(r[0]).replace(tzinfo=None)
        key = local.replace(hour=local.hour // BLOCK * BLOCK, minute=0, second=0)
        buckets.setdefault(key, []).append(r)

    out, short = [], 0
    for key, hours in sorted(buckets.items()):
        if key + dt.timedelta(hours=BLOCK) > cutoff:
            continue
        if len(hours) < MIN_HOURS:
            short += 1
            continue
        out.append(tuple([key, area] + summarise(hours) + [SOURCES]))
    return out, short


def main():
    cutoff = dt.datetime.now(LOCAL_TZ).replace(tzinfo=None)
    written = skipped = 0

    try:
        for area in AREAS:
            span = query(f"SELECT MIN(dt), MAX(dt) FROM weather_hourly "
                         f"WHERE area = '{area}'")[0]
            if span[0] is None:
                print(f"{area}: no hourly data")
                continue
            first, last = to_local(span[0]).year, to_local(span[1]).year

            if not REBUILD:
                done = query(f"SELECT MAX(start_dt) FROM weather_3hourly "
                             f"WHERE area = '{area}'")[0][0]
                if done is not None:
                    first = max(first, done.year)      # redo the part-built year

            for year in range(first, last + 1):
                rows, short = blocks_for_year(area, year, cutoff)
                for i in range(0, len(rows), BATCH):
                    cursor = mydb.cursor()
                    cursor.executemany(INSERT, rows[i:i + BATCH])
                    mydb.commit()
                written += len(rows)
                skipped += short
                print(f"{area} {year}: {len(rows):5d} blocks"
                      + (f", {short} short" if short else ""), flush=True)

        print(f"\ndone: {written} blocks written, {skipped} skipped as too short")
        return 0
    except Exception:
        import traceback
        traceback.print_exc()
        return 1
    finally:
        mydb.close()
        tunnel.stop()


if __name__ == '__main__':
    sys.exit(main())
