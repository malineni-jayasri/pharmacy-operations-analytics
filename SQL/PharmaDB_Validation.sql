USE PharmaDB;

SELECT
    COUNT(*) AS TotalSalesRows,

    SUM(CASE WHEN M.Id IS NULL THEN 1 ELSE 0 END)
        AS UnmatchedSalesRows,

    COUNT(DISTINCT CASE
        WHEN M.Id IS NULL THEN S.MedicineName
    END) AS UnmatchedMedicineNames,

    SUM(CASE WHEN S.Quantity <= 0 THEN 1 ELSE 0 END)
        AS InvalidQuantityRows,

    SUM(CASE WHEN S.GrandTotal < 0 THEN 1 ELSE 0 END)
        AS NegativeSalesRows,

    SUM(CASE
        WHEN ABS(S.TotalPrice - (S.Quantity * S.UnitPrice)) > 0.01
        THEN 1 ELSE 0
    END) AS PriceCalculationErrors

FROM dbo.Sales S
LEFT JOIN dbo.Medicines M
    ON LOWER(LTRIM(RTRIM(S.MedicineName)))
     = LOWER(LTRIM(RTRIM(M.Name)));

-- Actual number of rows in Sales
SELECT COUNT(*) AS ActualSalesRows
FROM dbo.Sales;

-- Sales medicine names that do not match the medicine master
SELECT
    S.MedicineName,
    COUNT(*) AS AffectedSalesRows
FROM dbo.Sales S
WHERE NOT EXISTS (
    SELECT 1
    FROM dbo.Medicines M
    WHERE LOWER(LTRIM(RTRIM(M.Name)))
        = LOWER(LTRIM(RTRIM(S.MedicineName)))
)
GROUP BY S.MedicineName;

-- Duplicate medicine names in the medicine master
SELECT
    LOWER(LTRIM(RTRIM(Name))) AS StandardizedMedicineName,
    COUNT(*) AS DuplicateCount
FROM dbo.Medicines
GROUP BY LOWER(LTRIM(RTRIM(Name)))
HAVING COUNT(*) > 1;


-- Find possible Q-Fol medicine-master matches
SELECT
    Id,
    Name,
    Brand,
    Category,
    Price,
    Stock,
    ExpiryDate,
    BuyingPrice
FROM dbo.Medicines
WHERE LOWER(Name) LIKE '%q%fol%'
   OR LOWER(Brand) LIKE '%q%fol%';

-- Inspect the four unmatched sales records
SELECT *
FROM dbo.Sales
WHERE LOWER(LTRIM(RTRIM(MedicineName))) = 'Entacyd';

Select * 
from dbo.Medicines
where LOWER(LTRIM(RTRIM(Name))) = 'Entacyd';

--Adding medicineId column to sales table

IF COL_LENGTH('dbo.Sales', 'MedicineId') IS NULL
BEGIN
    ALTER TABLE dbo.Sales
    ADD MedicineId INT NULL;
END;

SELECT TOP 5
    Id,
    InvoiceNo,
    MedicineName,
    MedicineId
FROM dbo.Sales

--Populating sales medicineID using medicinename
WITH NormalizedMedicines AS
(
    SELECT
        Id,
        LOWER(LTRIM(RTRIM(Name))) AS CleanMedicineName,
        COUNT(*) OVER (
            PARTITION BY LOWER(LTRIM(RTRIM(Name)))
        ) AS NameCount
    FROM dbo.Medicines
)

UPDATE S
SET S.MedicineId = M.Id
FROM dbo.Sales S
JOIN NormalizedMedicines M
    ON LOWER(LTRIM(RTRIM(S.MedicineName)))
     = M.CleanMedicineName
WHERE M.NameCount = 1
  AND S.MedicineId IS NULL;

SELECT @@ROWCOUNT AS SalesRowsMatched;
--Inspecting rows
SELECT
    MedicineName,
    UnitPrice,
    COUNT(*) AS UnmatchedRows
FROM dbo.Sales
WHERE MedicineId IS NULL
GROUP BY MedicineName, UnitPrice
ORDER BY MedicineName, UnitPrice;


-- Match Entacyd products using name and price

UPDATE S
SET S.MedicineId = M.Id
FROM dbo.Sales S
JOIN dbo.Medicines M
    ON LOWER(LTRIM(RTRIM(S.MedicineName)))
     = LOWER(LTRIM(RTRIM(M.Name)))
   AND ABS(S.UnitPrice - M.Price) <= 0.01
WHERE S.MedicineId IS NULL;

SELECT @@ROWCOUNT AS EntacydRowsMatched;

-- Map Q-Fol sales to Q-Fol 400 mg, Medicine ID 78
UPDATE dbo.Sales
SET MedicineId = 78
WHERE MedicineId IS NULL
  AND LOWER(LTRIM(RTRIM(MedicineName))) = 'q-fol'
  AND UnitPrice = 30.00;

SELECT @@ROWCOUNT AS QFolRowsMatched;


--Validating rows finally
SELECT
    COUNT(*) AS TotalSalesRows,
    COUNT(MedicineId) AS MatchedRows,
    SUM(CASE WHEN MedicineId IS NULL THEN 1 ELSE 0 END)
        AS UnmatchedRows,
    SUM(CASE WHEN M.Id IS NULL THEN 1 ELSE 0 END)
        AS InvalidMedicineIdRows
FROM dbo.Sales S
LEFT JOIN dbo.Medicines M
    ON S.MedicineId = M.Id;

--Creating official foreign-key relationship:

IF NOT EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE name = 'FK_Sales_Medicines_MedicineId'
)
BEGIN
    ALTER TABLE dbo.Sales WITH CHECK
    ADD CONSTRAINT FK_Sales_Medicines_MedicineId
        FOREIGN KEY (MedicineId)
        REFERENCES dbo.Medicines(Id);

    ALTER TABLE dbo.Sales
    CHECK CONSTRAINT FK_Sales_Medicines_MedicineId;
END;