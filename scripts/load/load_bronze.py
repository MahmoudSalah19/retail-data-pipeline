"""
Loads all cleaned source dataframes into their corresponding bronze-schema
tables in SQL Server, replacing existing rows while preserving DDL structure.
"""
import os
import yaml
import urllib
from dotenv import load_dotenv
from sqlalchemy import create_engine,Text
from extract_from_files import read_files, name_path_dict

# --- database configuration ---
with open(r'scripts\config.yaml', 'r') as f:
    config = yaml.safe_load(f)

db_config = config['database']
driver = db_config['driver']
server = db_config['server']
database = db_config['database']

# --- credentials (kept out of source control via .env) ---
load_dotenv()
username = os.getenv('DB_USERNAME')
password = os.getenv('DB_PASSWORD')

# --- build connection string and engine ---
params = urllib.parse.quote_plus(
    f"DRIVER={driver};"
    f"SERVER={server};"
    f"DATABASE={database};"
    f"UID={username};"
    f"PWD={password};"
    f"TrustServerCertificate=yes;"
)
connection_string = f"mssql+pyodbc:///?odbc_connect={params}"
engine = create_engine(connection_string, fast_executemany=True)

# --- read source dataframes ---
name_df_dict = read_files(name_path_dict, custom_na_keys=["stores"])
customers = name_df_dict['customers']
loyalty_program = name_df_dict['loyalty_program']
products = name_df_dict['products']
order_lines = name_df_dict['order_lines']
returns_log = name_df_dict['returns_log']
sales_transactions = name_df_dict['sales_transactions']
shipping_details = name_df_dict['shipping_details']
employees = name_df_dict['employees']
stores = name_df_dict['stores']



# --- rename source columns to match bronze table column names ---
customers = customers.rename(columns={'CustomerID': 'customer_id', 'FullName': 'full_name'})
loyalty_program = loyalty_program.rename(columns={
    'LoyaltyID': 'loyalty_id', 'CustomerID': 'customer_id', 'Tier': 'tier', 'Points': 'points'
})
products = products.rename(columns={'unitPrice': 'unit_price'})  # id, name, category already match source
order_lines = order_lines.rename(columns={
    'OrderLineID': 'order_line_id', 'TransactionID': 'transaction_id', 'ProductID': 'product_id',
    'Quantity': 'quantity', 'UnitPrice': 'unit_price', 'Discount': 'discount', 'LineTotal': 'line_total'
})
returns_log = returns_log.rename(columns={
    'ReturnID': 'return_id', 'TransactionID': 'transaction_id', 'OrderLineID': 'order_line_id',
    'ReturnDate': 'return_date', 'Reason': 'reason'
})
sales_transactions = sales_transactions.rename(columns={
    'TransactionID': 'transaction_id', 'Date': 'date', 'CustomerID': 'customer_id', 'StoreID': 'store_id',
    'EmployeeID': 'employee_id', 'PromotionID': 'promotion_id', 'PaymentMethod': 'payment_method',
    'TotalAmount': 'total_amount'
})
shipping_details = shipping_details.rename(columns={
    'ShipmentID': 'shipment_id', 'TransactionID': 'transaction_id', 'Carrier': 'carrier',
    'ShipDate': 'ship_date', 'DeliveryDate': 'delivery_date'
})
employees = employees.rename(columns={'EmployeeID': 'employee_id', 'FullName': 'full_name', 'StoreID': 'store_id'})
# stores: id, name, city, region. already match source column names, no rename needed


#get data from open meteo api and store it in coordinates df
from extract_from_meteo_api import get_data_from_meteo,region_country_map
cities = stores['city']
region = stores['region']
city_region_iter = zip(cities, region)
city_region_map = dict(city_region_iter) 
unique_cities = cities.unique()
coordinates=get_data_from_meteo(unique_cities,city_region_map,region_country_map)


#get data from PublicHolidays api and store it in holidays df
from extract_from_holidays_api import get_years_from_sales,get_holidays
years=get_years_from_sales(sales_transactions)
country_codes=coordinates['country_code'].unique()
holidays=get_holidays(years,country_codes)


# --- rename apis source columns to match bronze table column names ---
#coordinates: city,matched_city,country,country_code,latitude,longitude. already match source column names, no rename needed
holidays=holidays.rename(columns={'countryCode':'country_code','types':'type'})

#--- cast the datatype of the col 'types' from object to str
holidays = holidays.astype({'type': str})


SCHEMA = 'bronze'


# dataframes keyed by their target table name, post-rename
table_dataframes = {
    'customers': customers,
    'loyalty_program': loyalty_program,
    'products': products,
    'order_lines': order_lines,
    'returns_log': returns_log,
    'sales_transactions': sales_transactions,
    'shipping_details': shipping_details,
    'employees': employees,
    'stores': stores,
    'city_coordinates':coordinates,
    'holidays':holidays
}


def insert(dataframe, table_name, engine, schema):
    """Delete existing rows and insert fresh data, preserving the table's DDL structure."""
    with engine.begin() as connection:
        dataframe.to_sql(
            name=table_name,
            con=connection,
            schema=schema,
            if_exists='delete_rows',
            index=False,
            chunksize=1000,
        )
    print(f"{table_name} data loaded successfully")


def load_bronze():
    """Load every dataframe in table_dataframes into its matching bronze table."""
    for table_name, dataframe in table_dataframes.items():
        insert(dataframe, table_name, engine, SCHEMA)


# --- run ---
load_bronze()













