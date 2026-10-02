"""
Pulls public holidays (Nager.Date API) for every year covered by the
sales_transactions date range and every country where a store is located.
"""
import requests
import pandas as pd
from datetime import datetime
from extract_from_files import name_path_dict, read_files
from extract_from_meteo_api import get_data_from_meteo, unique_cities, city_region_map, region_country_map


def get_years_from_sales(sales_transactions: pd.DataFrame) -> list[int]:
    """Return the list of years spanned by sales_transactions' Date column."""
    #note if you run this file -->error as it should be sales_transactions["Date"] but we make it 'data' to call it from load_bronze.py file as we rename the cols to match the tables cols
    dates = sales_transactions["date"].str.strip()
    min_year = datetime.strptime(dates.min(), "%Y-%m-%d").year
    max_year = datetime.strptime(dates.max(), "%Y-%m-%d").year
    return list(range(min_year, max_year + 1))


def get_holidays(years: list[int], country_codes) -> pd.DataFrame:
    """Fetch public holidays for each year and country code from the Nager.Date API."""
    dfs = []
    for year in years:
        for code in country_codes:
            response = requests.get(
                f"https://date.nager.at/api/v3/PublicHolidays/{year}/{code}"
            )
            if response.status_code == 200:
                print(f"Request succeeded for year {year}/country code {code}")
                data = response.json()
                df = pd.DataFrame(data, columns=["name", "date", "countryCode", "types"])
                dfs.append(df)
            elif response.status_code == 204:
                print(f"No holidays available for {year}/{code}")
            elif response.status_code == 400:
                print(f"Invalid request for {year}/{code} holidays data")
            elif response.status_code == 404:
                print(f"Invalid country code for {year}/{code}")
            else:
                print(f"Error requesting {year}/{code} holidays data (status {response.status_code})")

    if not dfs:
        print("No holiday data retrieved.")
        return pd.DataFrame(columns=["name", "date", "countryCode", "types"])

    return pd.concat(dfs, ignore_index=True)

