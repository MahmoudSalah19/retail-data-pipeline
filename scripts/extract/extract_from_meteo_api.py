"""
Resolves each unique store city to its (latitude, longitude) using the
Open-Meteo Geocoding API, for later use in pulling historical weather data.
"""
import requests 
import pandas as pd
import sys
from extract_from_files import name_path_dict, read_files

# Reconfigure stdout to UTF-8 to correctly print non-ASCII city names.
sys.stdout.reconfigure(encoding="utf-8")

name_df_dict = read_files(name_path_dict, custom_na_keys=["stores"])

stores = name_df_dict['stores']
cities = stores['city']
region = stores['region']
city_region_iter = zip(cities, region)
city_region_map = dict(city_region_iter)  # Duplicate (city, region) pairs collapse automatically.

region_country_map = {
    "NA": ["United States", "Canada", "Mexico"],
    "EMEA": ["United Kingdom", "Germany", "France", "Spain", "Italy",
            "United Arab Emirates", "South Africa", "Netherlands"],
    # Extend with additional regions as the store list grows (e.g. "APAC": [...]).
}


unique_cities = cities.unique()


def get_data_from_meteo(distinct_cities: list, city_region_map: dict, region_country_map: dict) -> list:
    """Resolve each city to its best-match (latitude, longitude) via geocoding."""
    output_list = []
    for city in distinct_cities:
        response = requests.get(f"https://geocoding-api.open-meteo.com/v1/search?name={city}")

        if response.status_code != 200:
            print(f"Request failed for city '{city}'")
            continue
        print(f"Request succeeded for city '{city}'")

        data = response.json()
        if 'results' in data:
            data = data['results']
        else:
            print(f"No geocoding results found for '{city}'")
            continue

        # Narrow candidates to countries plausible for this city's region,
        # to disambiguate cities that share a name across multiple countries.
        filtered_list = []
        for item in data:
            if 'country' in item:
                plausible_countries = region_country_map.get(city_region_map[city], [])
                if item['country'] in plausible_countries:
                    filtered_list.append(item)
                    print(f"'{item['country']}' is a plausible country for region "
                            f"'{city_region_map[city]}'")
                else:
                    print(f"'{item['country']}' is not a plausible country for region "
                        f"'{city_region_map[city]}'")
            else:
                print(f"Candidate at index {data.index(item)} for '{city}' is missing a 'country' field")

        # If no candidate matched the expected region, fall back to all
        # candidates rather than dropping the city entirely.
        if not filtered_list:
            print(f"No region-matched candidate for '{city}'; falling back to all results ....")
            filtered_list = data

        # Among remaining candidates, select the most populous as the
        # most likely intended match.
        pop = [item.get('population', 0) for item in filtered_list]
        max_population_index=pop.index(max(pop))
        result = filtered_list[max_population_index]
        print(f"the final selected item's id : {result['id']}")
        print("*" * 70)

        final_result = {
            "city": city,                          # keep original input city too, for traceability
            "matched_name": result['name'],
            "country": result.get('country'),
            "country_code": result.get('country_code'),  # use .get() for safety, consistent with population handling
            "latitude": result['latitude'],
            "longitude": result['longitude'],
        }

        output_list.append(final_result)

    city_coordinates_df=pd.DataFrame(output_list)
    
    return city_coordinates_df


