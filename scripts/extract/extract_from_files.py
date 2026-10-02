import pandas as pd
from pathlib import Path
from pandas._libs.parsers import STR_NA_VALUES
# pandas treat default NA markers as NaN,
# since "NA" is a real region code (North America) in our source data 'stores',
# so we tell python : treaat NA marker as a code not NaN -or- don't convert NA markers into NaN ,keep it NA
NA_VALUES = STR_NA_VALUES - {"NA"}

"""change the file paths according to their location on your pc"""
name_path_dict = {
    "customers":         Path(r"C:\Users\musta\Desktop\the big project\dataset\customers\PNRao_SalesRetail_Customer_Master.csv"),
    "loyalty_program":   Path(r"C:\Users\musta\Desktop\the big project\dataset\customers\PNRao_SalesRetail_Loyalty_Program.csv"),
    "products":          Path(r"C:\Users\musta\Desktop\the big project\dataset\products & inventory\PNRao_SalesRetail_Product_Master.csv"),
    "order_lines":       Path(r"C:\Users\musta\Desktop\the big project\dataset\sales & orders\PNRao_SalesRetail_Order_Lines.xlsx"),
    "returns_log":       Path(r"C:\Users\musta\Desktop\the big project\dataset\sales & orders\PNRao_SalesRetail_Returns_Log.xlsx"),
    "sales_transactions": Path(r"C:\Users\musta\Desktop\the big project\dataset\sales & orders\PNRao_SalesRetail_Sales_Transactions.xlsx"),
    "shipping_details":  Path(r"C:\Users\musta\Desktop\the big project\dataset\sales & orders\PNRao_SalesRetail_Shipping_Details.xlsx"),
    "employees":         Path(r"C:\Users\musta\Desktop\the big project\dataset\store & employee\PNRao_SalesRetail_Employee_Master.csv"),
    "stores":            Path(r"C:\Users\musta\Desktop\the big project\dataset\store & employee\PNRao_SalesRetail_Store_Master.csv"),
}


def read_files(name_path_dict: dict, custom_na_keys: list = None) -> dict:
    """
    Reads a dict of {table_name: file_path} into {table_name: DataFrame}.
    Tables listed in custom_na_keys preserve the literal string "NA"
    instead of treating it as null (needed for the 'stores.region' column).
    """
    # if user doesn't pass a custom_na_keys ,make it empty list
    custom_na_keys = custom_na_keys or []
    name_df_dict = {}

    for name, path in name_path_dict.items():
        suffix = path.suffix.lower()
        na_kwargs = {"keep_default_na": False,
                    "na_values": NA_VALUES} if name in custom_na_keys else {}

        if suffix == '.xlsx':
            # ** unpacks a dict into keyword arguments: func(**{"a": 1, "b": 2}) → func(a=1, b=2)
            name_df_dict[name] = pd.read_excel(path, **na_kwargs)
        elif suffix == '.csv':
            name_df_dict[name] = pd.read_csv(path, **na_kwargs)
        else:
            raise ValueError(f"Unsupported file type for {name}: {path}")

    return name_df_dict













