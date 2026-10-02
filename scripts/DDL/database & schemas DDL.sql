/*
=============================================================
Create Database and Schemas
=============================================================
Script Purpose:
    This script creates a new database named 'retail_data_pipeline' after checking if it already exists. 
    If the database exists, it is dropped and recreated. Additionally, the script sets up three schemas 
    within the database: 'bronze', 'silver', and 'gold'.
	
WARNING:
    Running this script will drop the entire 'retail_data_pipeline' database if it exists. 
    All data in the database will be permanently deleted. Proceed with caution 
    and ensure you have proper backups before running this script.
*/

USE master;
GO

-- Drop and recreate the 'retail_data_pipeline' database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'retail_data_pipeline')
BEGIN
    ALTER DATABASE retail_data_pipeline SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE retail_data_pipeline;
END;
GO

-- Create the 'retail_data_pipeline' database
CREATE DATABASE retail_data_pipeline;
GO

--Use the 'retail_data_pipeline' database
USE retail_data_pipeline;
GO

-- Create Schemas
CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
GO


