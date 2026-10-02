/*
===============================================================================
DDL Script: Create Bronze Tables
===============================================================================
Script Purpose:
    This script creates tables in the 'bronze' schema, dropping existing tables 
    if they already exist.
    Run this script to re-define the DDL structure of 'bronze' Tables.

Note:
    All columns are typed as NVARCHAR regardless of apparent data type.
    Bronze must accept raw source data as-is, including blanks, #N/A, and
    malformed values. Type casting and validation happen in Silver.
===============================================================================
*/


USE retail_data_pipeline;
GO



--drop table 'bronze.customers' if exist and recreate it
IF OBJECT_ID('bronze.customers', 'U') IS NOT NULL
    DROP TABLE bronze.customers;
GO

CREATE TABLE bronze.customers (
    customer_id     NVARCHAR(50)  NULL,
    full_name       NVARCHAR(100) NULL
);
GO




--drop table 'bronze.loyalty_program' if exist and recreate it
IF OBJECT_ID('bronze.loyalty_program', 'U') IS NOT NULL
    DROP TABLE bronze.loyalty_program;
GO

CREATE TABLE bronze.loyalty_program (
    loyalty_id      NVARCHAR(50)  NULL,
    customer_id     NVARCHAR(50)  NULL,
    tier            NVARCHAR(50)  NULL,
    points          NVARCHAR(50)  NULL
);
GO




--drop table 'bronze.products' if exist and recreate it
IF OBJECT_ID('bronze.products', 'U') IS NOT NULL
    DROP TABLE bronze.products;
GO

CREATE TABLE bronze.products (
    id              NVARCHAR(50)  NULL,
    name            NVARCHAR(100) NULL,
    category        NVARCHAR(50)  NULL,
    unit_price      NVARCHAR(50)  NULL
);
GO




--drop table 'bronze.order_lines' if exist and recreate it
IF OBJECT_ID('bronze.order_lines', 'U') IS NOT NULL
    DROP TABLE bronze.order_lines;
GO

CREATE TABLE bronze.order_lines (
    order_line_id   NVARCHAR(50)  NULL,
    transaction_id  NVARCHAR(50)  NULL,
    product_id      NVARCHAR(50)  NULL,
    quantity        NVARCHAR(50)  NULL,
    unit_price      NVARCHAR(50)  NULL,
    discount        NVARCHAR(50)  NULL,
    line_total      NVARCHAR(50)  NULL
);
GO




--drop table 'bronze.returns_log' if exist and recreate it
IF OBJECT_ID('bronze.returns_log', 'U') IS NOT NULL
    DROP TABLE bronze.returns_log;
GO

CREATE TABLE bronze.returns_log (
    return_id       NVARCHAR(50)  NULL,
    transaction_id  NVARCHAR(50)  NULL,
    order_line_id   NVARCHAR(50)  NULL,
    return_date     NVARCHAR(50)  NULL,
    reason          NVARCHAR(150) NULL
);
GO




--drop table 'bronze.sales_transactions' if exist and recreate it
IF OBJECT_ID('bronze.sales_transactions', 'U') IS NOT NULL
    DROP TABLE bronze.sales_transactions;
GO

CREATE TABLE bronze.sales_transactions (
    transaction_id  NVARCHAR(50)  NULL,
    date            NVARCHAR(50)  NULL,
    customer_id     NVARCHAR(50)  NULL,
    store_id        NVARCHAR(50)  NULL,
    employee_id     NVARCHAR(50)  NULL,
    promotion_id    NVARCHAR(50)  NULL,
    payment_method  NVARCHAR(50)  NULL,
    total_amount    NVARCHAR(50)  NULL
);
GO




--drop table 'bronze.shipping_details' if exist and recreate it
IF OBJECT_ID('bronze.shipping_details', 'U') IS NOT NULL
    DROP TABLE bronze.shipping_details;
GO

CREATE TABLE bronze.shipping_details (
    shipment_id     NVARCHAR(50)  NULL,
    transaction_id  NVARCHAR(50)  NULL,
    carrier         NVARCHAR(50)  NULL,
    ship_date       NVARCHAR(50)  NULL,
    delivery_date   NVARCHAR(50)  NULL
);
GO




--drop table 'bronze.employees' if exist and recreate it
IF OBJECT_ID('bronze.employees', 'U') IS NOT NULL
    DROP TABLE bronze.employees;
GO

CREATE TABLE bronze.employees (
    employee_id     NVARCHAR(50)  NULL,
    full_name       NVARCHAR(100) NULL,
    store_id        NVARCHAR(50)  NULL
);
GO




--drop table 'bronze.stores' if exist and recreate it
IF OBJECT_ID('bronze.stores', 'U') IS NOT NULL
    DROP TABLE bronze.stores;
GO

CREATE TABLE bronze.stores (
    id              NVARCHAR(50)  NULL,
    name            NVARCHAR(100) NULL,
    city            NVARCHAR(50)  NULL,
    region          NVARCHAR(50)  NULL
);
GO



--drop table 'bronze.city_coordinates' if exist and recreate it
IF OBJECT_ID('bronze.city_coordinates', 'U') IS NOT NULL
    DROP TABLE bronze.city_coordinates;
GO

CREATE TABLE bronze.city_coordinates (
    city              NVARCHAR(50)  NULL,
    matched_name      NVARCHAR(100) NULL,
    country           NVARCHAR(50)  NULL,
    country_code      NVARCHAR(50)  NULL,
    latitude          NVARCHAR(50)  NULL,
    longitude         NVARCHAR(50)  NULL
);
GO


--drop table 'bronze.holidays' if exist and recreate it
IF OBJECT_ID('bronze.holidays', 'U') IS NOT NULL
    DROP TABLE bronze.holidays;
GO

CREATE TABLE bronze.holidays (
    name             NVARCHAR(150)  NULL,
    date             NVARCHAR(50)   NULL,
    country_code     NVARCHAR(20)  NULL,
    type             NVARCHAR(100)   NULL

);
GO
