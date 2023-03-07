
-- You can run the command below to see the data on the table;
SELECT [SSN], [Salary] FROM [HR].[Employees];
GO

-- You can also run the below queries against the system catalog views that contain key metadata.
SELECT * FROM sys.column_master_keys;
SELECT * FROM sys.column_encryption_keys
SELECT * FROM sys.column_encryption_key_values


-- You can also run the below query against sys.columns to retrieve column-level encryption metadata for the two encrypted columns
SELECT
[name]
, [encryption_type]
, [encryption_type_desc]
, [encryption_algorithm_name]
, [column_encryption_key_id]
FROM sys.columns
WHERE [encryption_type] IS NOT NULL;


-- Execute the below query, which filters data by the encrypted SSN column. The query should return one row containing plaintext values.
DECLARE @SSN [char](11) = '795-73-9838'
SELECT [SSN], [Salary] FROM [HR].[Employees]
WHERE [SSN] = @SSN