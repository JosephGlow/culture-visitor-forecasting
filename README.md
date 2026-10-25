# Forecasting National Museums Liverpool Venue Visits

Code for the COMP702 MSc project. It builds a MariaDB database of NML visits, weather and school term dates, then trains and evaluates forecasting models on the 2025/26 financial year.

The data is not included. Section 3 explains where each dataset comes from.

## 1. Files

| File | Purpose |
| - | - |
| `main.ipynb` | All experiments and results. Saved with the outputs from the final run, so results can be read without running it. |
| `Import visits to database.ipynb` | Loads NML visitor data (FOI workbooks) into the database, with a dry run and a check on each hourly sheet. |
| `Import weather to database.ipynb` | Loads the OpenWeather bulk CSV, sets missing rain and snow to 0.00, and builds `weather_daily` on UK local time. |
| `build_3hourly.py` | Builds `weather_3hourly` from `weather_hourly`. |
| `owapi.py` | Nightly cron job: fills gaps in `weather_hourly` from the One Call 3.0 API and updates the daily and 3-hourly tables. |
| `nml_schema.sql` | Schema of the final database: 10 tables and 2 views, no data. This is a MariaDB 11.8 dump; delete its first line to load it into Oracle MySQL. |
| `requirements.txt` | Python packages. |


## 2. Setup

1. Install Python 3 and the packages: `pip install -r requirements.txt`

2. Create a MariaDB database called `nml` and load the schema: `mariadb nml < nml_schema.sql`

3. Edit `db_config.json` in this folder with your own connection details:

```
{"ssh_host": "your-server", "ssh_port": 22, "ssh_user": "user",
 "ssh_pkey": "~/.ssh/id_ed25519", "db_user": "user", "db_name": "nml"}
```

The notebooks connect through an SSH tunnel. For a database on your own machine, use `localhost` as `ssh_host`, with an SSH server running locally.

1. Put the data files (section 3) in a `data/` folder next to the notebooks, using the file names shown.

## 3. Data sources

| Data | Source | File in `data/` |
| - | - | :-: |
| NML visits (daily from 2007, hourly from 2023) and venue KPIs | Freedom of Information requests to NML, February and September 2026 | `FOI.26.09 - data.xlsx` (February), `FOI No.26.38 - data.xlsx` (September) |
| Hourly weather from 1 Jan 1979, four areas | OpenWeather History Bulk CSV (purchased), then the One Call 3.0 API (needs an API key) | `openweatherhistoric.csv` |
| School term dates, six Liverpool City Region authorities | Council FOI responses and archived and live council websites (see the dissertation bibliography), compiled into a CSV | Imported into `term_dates` with MySQL Workbench |


The Dataverse query used for the dashboard needs a staff OAuth login, so it is not needed to reproduce the experiments.

## 4. Reproducing the experiments

Run these in order, each with `DRY_RUN = True` first to check its report, then `DRY_RUN = False` to write:

1. `Import weather to database.ipynb`, with `IMPORT_CSV = True`. On a first load, uncomment the step 2 cell, which sets missing rain and snow in `weather_hourly` to 0.00. Without this, dry hours and 3-hour blocks stay NULL and are dropped by `main.ipynb`. The step is disabled in the saved notebook because the project database has already been fixed. It runs as a single large update, so allow time on slow hardware.

2. `build_3hourly.py`, with `REBUILD = True`

3. Import the term dates CSV into `term_dates`

4. `Import visits to database.ipynb`: already set up to use the September workbook, with World Museum's hourly data taken from the February workbook

5. `main.ipynb`, run from the top

The dissertation's results use the settings saved in `main.ipynb`:

| Setting | Value |
| - | - |
| Training data | Up to 31 March 2025 |
| Test year | FY 2025/26 |
| `DROP_DISRUPTED_DAYS` | `True` |
| 3-hourly weather blocks | All eight |


A full run takes about ten minutes on a modern desktop CPU; the LSTM, Boruta and ablation sections are the slowest.

## 5. Nightly weather collection

`owapi.py` runs on the server through cron at 03:00 (`0 3 * * * /usr/bin/python3 /srv/api/owapi.py`). It connects through the local MariaDB socket as the user set in `DB`, and reads the API key from `/srv/api/keys/owapikey.txt`.

## 6. Not included

- **Data:** see section 3.

- **Credentials:** your real `db_config.json connection details`, the OpenWeather API key and SSH keys.

