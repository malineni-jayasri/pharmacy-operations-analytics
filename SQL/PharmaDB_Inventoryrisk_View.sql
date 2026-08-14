USE PharmaDB;
GO

CREATE OR ALTER VIEW dbo.vw_InventoryRisk
AS

SELECT
    M.Id AS MedicineId,
    M.Name AS MedicineName,
    M.Brand,
    M.Category,
    M.Stock AS CurrentStock,
    M.BuyingPrice AS UnitCost,
    M.Price AS SellingPrice,
    M.ExpiryDate,

    DATEDIFF(
        DAY,
        CAST(GETDATE() AS DATE),
        M.ExpiryDate
    ) AS DaysUntilExpiry,

    M.Stock * M.BuyingPrice
        AS InventoryCostValue,

    M.Stock * M.Price
        AS InventoryRetailValue,

    M.Stock * (M.Price - M.BuyingPrice)
        AS PotentialInventoryProfit,

    CASE
        WHEN M.Price = 0 THEN 0
        ELSE (M.Price - M.BuyingPrice) / M.Price
    END AS PotentialMarginRate,

    CASE
        WHEN M.Stock = 0
            THEN 'Out of Stock'

        WHEN M.ExpiryDate < CAST(GETDATE() AS DATE)
            THEN 'Expired'

        WHEN M.ExpiryDate <=
             DATEADD(DAY, 30, CAST(GETDATE() AS DATE))
            THEN 'Expiring Within 30 Days'

        WHEN M.ExpiryDate <=
             DATEADD(DAY, 60, CAST(GETDATE() AS DATE))
            THEN 'Expiring Within 60 Days'

        WHEN M.ExpiryDate <=
             DATEADD(DAY, 90, CAST(GETDATE() AS DATE))
            THEN 'Expiring Within 90 Days'

        WHEN M.Stock <= 10
            THEN 'Low Stock'

        ELSE 'Healthy'
    END AS InventoryStatus

FROM dbo.Medicines M;
GO

SELECT
    COUNT(*) AS TotalMedicines,
    SUM(CurrentStock) AS CurrentStockUnits,
    SUM(InventoryCostValue) AS InventoryCostValue,
    SUM(InventoryRetailValue) AS InventoryRetailValue,
    SUM(CASE WHEN InventoryStatus = 'Expired' THEN 1 ELSE 0 END)
        AS ExpiredMedicines,
    SUM(CASE WHEN InventoryStatus LIKE 'Expiring%' THEN 1 ELSE 0 END)
        AS ExpiringWithin90Days,
    SUM(CASE WHEN InventoryStatus = 'Low Stock' THEN 1 ELSE 0 END)
        AS LowStockMedicines,
    SUM(CASE
        WHEN InventoryStatus = 'Expired'
          OR InventoryStatus LIKE 'Expiring%'
        THEN InventoryCostValue
        ELSE 0
    END) AS ExpiryRiskCost
FROM dbo.vw_InventoryRisk;