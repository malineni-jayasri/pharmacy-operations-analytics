USE PharmaDB;
GO

CREATE OR ALTER VIEW dbo.vw_InventoryDemand
AS

WITH AnalysisDate AS
(
    SELECT MAX(SaleDate) AS DataCutoffDate
    FROM dbo.Sales
),

RecentDemand AS
(
    SELECT
        S.MedicineId,
        SUM(S.Quantity) AS UnitsSoldLast90Days
    FROM dbo.Sales S
    CROSS JOIN AnalysisDate AD
    WHERE S.SaleDate >
          DATEADD(DAY, -90, AD.DataCutoffDate)
      AND S.SaleDate <= AD.DataCutoffDate
    GROUP BY S.MedicineId
)

SELECT
    M.Id AS MedicineId,
    M.Name AS MedicineName,
    M.Brand,
    M.Category,
    AD.DataCutoffDate,
    M.Stock AS CurrentStock,

    ISNULL(RD.UnitsSoldLast90Days, 0)
        AS UnitsSoldLast90Days,

    CAST(
        ISNULL(RD.UnitsSoldLast90Days, 0) / 90.0
        AS DECIMAL(18,4)
    ) AS AverageDailyDemand,

    CASE
        WHEN ISNULL(RD.UnitsSoldLast90Days, 0) = 0
        THEN NULL
        ELSE
            M.Stock /
            (RD.UnitsSoldLast90Days / 90.0)
    END AS EstimatedDaysOfSupply,

    M.Stock * M.BuyingPrice
        AS InventoryCostValue,

    CASE
        WHEN ISNULL(RD.UnitsSoldLast90Days, 0) = 0
            THEN 'No Recent Demand'

        WHEN M.Stock /
             (RD.UnitsSoldLast90Days / 90.0) < 30
            THEN 'Reorder Risk'

        WHEN M.Stock /
             (RD.UnitsSoldLast90Days / 90.0) > 180
            THEN 'Potential Overstock'

        ELSE 'Balanced'
    END AS StockDemandStatus

FROM dbo.Medicines M
CROSS JOIN AnalysisDate AD
LEFT JOIN RecentDemand RD
    ON M.Id = RD.MedicineId;
GO

SELECT
    StockDemandStatus,
    COUNT(*) AS MedicineCount,
    SUM(CurrentStock) AS CurrentStockUnits,
    SUM(InventoryCostValue) AS InventoryCostValue
FROM dbo.vw_InventoryDemand
GROUP BY StockDemandStatus
ORDER BY MedicineCount DESC;