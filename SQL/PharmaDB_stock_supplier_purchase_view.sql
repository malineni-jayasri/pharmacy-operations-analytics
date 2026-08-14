USE PharmaDB;
GO

CREATE OR ALTER VIEW dbo.vw_StockPurchases
AS

SELECT
    SI.Id AS StockInId,
    SI.DateAdded,
    CAST(SI.DateAdded AS DATE) AS StockDate,

    SI.MedicineId,
    M.Name AS MedicineName,
    M.Brand,
    M.Category,

    SI.SupplierId,
    SUP.Name AS SupplierName,

    SI.Quantity AS UnitsReceived,
    SI.BuyingPrice AS PurchaseUnitCost,

    SI.Quantity * SI.BuyingPrice
        AS PurchaseValue

FROM dbo.StockIn SI

INNER JOIN dbo.Medicines M
    ON SI.MedicineId = M.Id

INNER JOIN dbo.Suppliers SUP
    ON SI.SupplierId = SUP.Id;
GO

SELECT
    COUNT(*) AS StockTransactions,
    COUNT(DISTINCT MedicineId) AS MedicinesPurchased,
    COUNT(DISTINCT SupplierId) AS ActiveSuppliers,
    SUM(UnitsReceived) AS UnitsReceived,
    SUM(PurchaseValue) AS TotalPurchaseValue,
    MIN(StockDate) AS FirstStockDate,
    MAX(StockDate) AS LastStockDate
FROM dbo.vw_StockPurchases;