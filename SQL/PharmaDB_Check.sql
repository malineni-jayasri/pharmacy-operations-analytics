USE PharmaDB;

SELECT 'Medicines' AS TableName, COUNT(*) AS [RowCount]
FROM dbo.Medicines

UNION ALL

SELECT 'Sales', COUNT(*)
FROM dbo.Sales

UNION ALL

SELECT 'StockIn', COUNT(*)
FROM dbo.StockIn

UNION ALL

SELECT 'Suppliers', COUNT(*)
FROM dbo.Suppliers

UNION ALL

SELECT 'Returns', COUNT(*)
FROM dbo.Returns;


SELECT
    MIN(SaleDate) AS FirstSaleDate,
    MAX(SaleDate) AS LastSaleDate,
    COUNT(DISTINCT InvoiceNo) AS TotalInvoices,
    COUNT(DISTINCT MedicineName) AS MedicinesSold,
    SUM(Quantity) AS UnitsSold,
    SUM(GrandTotal) AS TotalRevenue
FROM dbo.Sales;

SELECT
    MIN(DateAdded) AS FirstStockDate,
    MAX(DateAdded) AS LastStockDate,
    SUM(Quantity) AS UnitsReceived,
    COUNT(DISTINCT MedicineId) AS MedicinesPurchased,
    COUNT(DISTINCT SupplierId) AS SuppliersUsed
FROM dbo.StockIn;
