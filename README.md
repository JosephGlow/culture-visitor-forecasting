# Forecasting National Museums Liverpool Venue Visits

Code for my MSc Data Science and Artificial Intelligence project (COMP702, University of Liverpool, 2026; graded A). It builds a MariaDB database of National Museums Liverpool (NML) visits, weather and school term dates, then trains and evaluates forecasting models on the 2025/26 financial year.

- **Dissertation (PDF):** [v1.0-msc release](https://github.com/JosephGlow/culture-visitor-forecasting/releases/tag/v1.0-msc)
- **Submitted version of the code:** tag [`v1.0-msc`](https://github.com/JosephGlow/culture-visitor-forecasting/tree/v1.0-msc). Work after the MSc continues on `main`.

The data is not included. Section 4 explains where each dataset comes from.

## 1. Results

Ridge, Random Forest, XGBoost, LSTM, SARIMA and Prophet models were tested on FY 2025/26 against naive and seasonal-naive baselines.

| Forecast horizon | Tuned XGBoost (nRMSE) | Seasonal-naive baseline (nRMSE) |
| - | :-: | :-: |
| 1 day ahead | 13.2% | 37.6% |
| 4 weeks ahead | 16.8% | 45.6% |

- The organisation-level forecast was more accurate than NML's own monthly KPI targets.
- LSTM was as accurate as XGBoost but less stable across random seeds, and harder to explain.
- Individual venues were harder to forecast: none met the project's 15% acceptance threshold.
- **Weather barely matters.** Boruta selected no weather features, and removing weather changed forecast error by less than one percentage point. Removing school holidays cost up to 3.3 points, and whether a day was a Saturday alone carried 18.5 times the importance of all weather features combined.

Visits are driven mainly by day of the week, recent visits and school holidays. Accurate, explainable forecasts can be built from data NML already holds plus free or low-cost sources, using only open-source software.

## 2. Files

| File | Purpose |
| - | - |
| `main.ipynb` | All experiments and results. Saved with the outputs from the final run, so results can be read without running it. |
| `Import visits to database.ipynb` | Loads NML visitor data (FOI workbooks) into the database, with a dry run and a check on each hourly sheet. |
| `Import weather to database.ipynb` | Loads the OpenWeather bulk CSV, sets missing rain and snow to 0.00, and builds `weather_daily` on UK local time. |
| `build_3hourly.py` | Builds `weather_3hourly` from `weather_hourly`. |
| `owapi.py` | Nightly cron job: fills gaps in `weather_hourly` from the One Call 3.0 API and updates the daily and 3-hourly tables. |
| `nml_schema.sql` | Schema of the final database: 10 tables and 2 views, no data. This is a MariaDB 11.8 dump; delete its first line to load it into Oracle MySQL. |
| `db_config.example.json` | Template for your database connection details. |
| `requirements.txt` | Python packages. |

## 3. Setup

1. Install Python 3 and the packages: `pip install -r requirements.txt`

2. Create a MariaDB database called `nml` and load the schema: `mariadb nml < nml_schema.sql`

3. Copy `db_config.example.json` to `db_config.json` and edit it with your own connection details:

   ```json
   {"ssh_host": "your-server", "ssh_port": 22, "ssh_user": "user",
    "ssh_pkey": "~/.ssh/id_ed25519", "db_user": "user", "db_name": "nml"}
   ```

   The notebooks connect through an SSH tunnel. For a database on your own machine, use `localhost` as `ssh_host`, with an SSH server running locally. `db_config.json` is in `.gitignore`, so your details stay local.

4. Put the data files (section 4) in a `data/` folder next to the notebooks, using the file names shown.

## 4. Data sources

| Data | Source | File in `data/` |
| - | - | :-: |
| NML visits (daily from 2007, hourly from 2023) and venue KPIs | Freedom of Information requests to NML, February and September 2026 | `FOI.26.09 - data.xlsx` (February), `FOI No.26.38 - data.xlsx` (September) |
| Hourly weather from 1 Jan 1979, four areas | OpenWeather History Bulk CSV (purchased), then the One Call 3.0 API (needs an API key) | `openweatherhistoric.csv` |
| School term dates, six Liverpool City Region authorities | Council FOI responses and archived and live council websites (see the dissertation bibliography), compiled into a CSV | Imported into `term_dates` with MySQL Workbench |

The Dataverse query used for the dashboard needs a staff OAuth login, so it is not needed to reproduce the experiments.

## 5. Reproducing the experiments

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

## 6. Nightly weather collection

`owapi.py` runs on the server through cron at 03:00 (`0 3 * * * /usr/bin/python3 /srv/api/owapi.py`). It connects through the local MariaDB socket as the user set in `DB`, and reads the API key from `/srv/api/keys/owapikey.txt`.

## 7. Not included

- **Data:** see section 4.
- **Credentials:** your own `db_config.json`, the OpenWeather API key and SSH keys.

## 8. Copyright and data

© 2026 Joseph Glow. All rights reserved. The code is shared for viewing and assessment; please get in touch if you would like to reuse it.

NML visitor data was obtained through Freedom of Information requests, and OpenWeather data is used under the Open Database License with attribution. Neither is included in this repository.
