USE PharmaDB;
GO

CREATE OR ALTER VIEW dbo.vw_InventoryActions
AS

SELECT
    IR.MedicineId,
    IR.MedicineName,
    IR.Brand,
    IR.Category,
    IR.CurrentStock,
    IR.UnitCost,
    IR.SellingPrice,
    IR.ExpiryDate,
    IR.DaysUntilExpiry,
    IR.InventoryCostValue,
    IR.InventoryRetailValue,
    IR.InventoryStatus,
    ID.UnitsSoldLast90Days,
    ID.AverageDailyDemand,
    ID.EstimatedDaysOfSupply,
    ID.StockDemandStatus,
    ID.DataCutoffDate,

    CASE
        WHEN IR.InventoryStatus = 'Expired'
            THEN 'Critical'

        WHEN IR.InventoryStatus = 'Expiring Within 30 Days'
         AND ID.StockDemandStatus IN
             ('No Recent Demand', 'Potential Overstock')
            THEN 'Critical'

        WHEN IR.InventoryStatus LIKE 'Expiring%'
            THEN 'High'

        WHEN ID.StockDemandStatus = 'No Recent Demand'
            THEN 'High'

        WHEN ID.StockDemandStatus = 'Potential Overstock'
            THEN 'Medium'

        WHEN IR.InventoryStatus = 'Low Stock'
            THEN 'Medium'

        ELSE 'Low'
    END AS RiskPriority,

    CASE
        WHEN IR.InventoryStatus = 'Expired'
            THEN 'Quarantine expired stock and review disposal or supplier return'

        WHEN IR.InventoryStatus LIKE 'Expiring%'
         AND ID.StockDemandStatus IN
             ('No Recent Demand', 'Potential Overstock')
            THEN 'Review approved stock transfer, supplier return, or replenishment hold'

        WHEN IR.InventoryStatus LIKE 'Expiring%'
            THEN 'Monitor closely and prioritize safe utilization before expiry'

        WHEN ID.StockDemandStatus = 'No Recent Demand'
            THEN 'Review demand, suspend replenishment, and investigate inactive stock'

        WHEN ID.StockDemandStatus = 'Potential Overstock'
            THEN 'Reduce replenishment and review future purchase quantities'

        WHEN IR.InventoryStatus = 'Low Stock'
            THEN 'Monitor demand and evaluate reorder requirement'

        ELSE 'No immediate action'
    END AS RecommendedAction

FROM dbo.vw_InventoryRisk IR
INNER JOIN dbo.vw_InventoryDemand ID
    ON IR.MedicineId = ID.MedicineId;
GO


SELECT
    RiskPriority,
    COUNT(*) AS MedicineCount,
    SUM(CurrentStock) AS StockUnits,
    SUM(InventoryCostValue) AS InventoryCostValue
FROM dbo.vw_InventoryActions
GROUP BY RiskPriority
ORDER BY
    CASE RiskPriority
        WHEN 'Critical' THEN 1
        WHEN 'High' THEN 2
        WHEN 'Medium' THEN 3
        ELSE 4
    END;