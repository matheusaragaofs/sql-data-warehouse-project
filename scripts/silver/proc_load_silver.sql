/*
===============================================================================
Stored Procedure or Script: Load and Clean Customer Data (Bronze -> Silver)
===============================================================================
Script Purpose:
    This script loads cleaned and standardized customer data from the bronze layer 
    into the silver layer (table: silver.crm_cust_info). It ensures data consistency 
    and quality through the following steps:
    
    - Trims unwanted spaces from string fields (first name, last name, etc.)
    - Standardizes coded values such as gender and marital status
    - Handles missing or unrecognized values by assigning a default ('n/a')
    - Removes duplicates by selecting the most recent record per customer ID
    - Ensures only one record per customer is inserted

Parameters:
    None.

Usage Example:
    EXEC Silver.load_silver;

===============================================================================
*/

INSERT INTO silver.crm_cust_info (
cst_id,
cst_key,
cst_firstname,
cst_lastname,
cst_marital_status,
cst_gndr,
cst_create_date
) 
SELECT 
cst_id,
cst_key,
TRIM(cst_firstname) AS cst_firstname,
TRIM(cst_lastname) AS cst_lastname,
CASE 
	WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
	WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
	ELSE 'n/a'
END cst_marital_status,
CASE 
	WHEN UPPER(TRIM(cst_gndr)) ='F' then 'Female'
	WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
	ELSE 'n/a' -- not available
END AS cst_gndr,
cst_create_date
FROM (
	SELECT 
	*,
	ROW_NUMBER() OVER (
	PARTITION BY cst_id
	ORDER BY cst_create_date DESC) as flag_last
	FROM bronze.crm_cust_info
	WHERE cst_id IS NOT NULL
) t WHERE flag_last = 1;