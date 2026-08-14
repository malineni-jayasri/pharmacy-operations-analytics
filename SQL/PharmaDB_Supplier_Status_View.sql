USE PharmaDB;

SELECT
    S.Id AS SupplierId,
    S.Name AS SupplierName,

    COUNT(SP.StockInId) AS StockTransactions,
    COUNT(DISTINCT SP.MedicineId) AS MedicinesSupplied,

    ISNULL(SUM(SP.UnitsReceived), 0)
        AS UnitsReceived,

    ISNULL(SUM(SP.PurchaseValue), 0)
        AS TotalPurchaseValue,

    MIN(SP.StockDate) AS FirstDeliveryDate,
    MAX(SP.StockDate) AS LastDeliveryDate,

    CASE
        WHEN COUNT(SP.StockInId) = 0
        THEN 'Inactive'
        ELSE 'Active'
    END AS SupplierStatus

FROM dbo.Suppliers S

LEFT JOIN dbo.vw_StockPurchases SP
    ON S.Id = SP.SupplierId

GROUP BY
    S.Id,
    S.Name

ORDER BY
    TotalPurchaseValue DESC,
    SupplierName;