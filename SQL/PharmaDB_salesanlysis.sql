USE PharmaDB;
GO

CREATE OR ALTER VIEW dbo.vw_SalesAnalytics
AS

SELECT
    S.Id AS SaleId,
    S.InvoiceNo,
    S.SaleDate,

    CASE
        WHEN S.CustomerName IS NULL
          OR LTRIM(RTRIM(S.CustomerName)) = ''
        THEN 'CUST-UNKNOWN'
        ELSE CONCAT(
            'CUST-',
            LEFT(
                CONVERT(
                    VARCHAR(64),
                    HASHBYTES(
                        'SHA2_256',
                        LOWER(LTRIM(RTRIM(S.CustomerName)))
                    ),
                    2
                ),
                12
            )
        )
    END AS CustomerKey,

    S.MedicineId,
    M.Name AS MedicineName,
    M.Brand,
    M.Category,

    S.Quantity,
    S.UnitPrice,
    S.TotalPrice AS GrossSalesAmount,
    S.Discount AS RecordedDiscount,
    S.TotalPrice - S.GrandTotal AS DiscountAmount,

    CASE
        WHEN S.TotalPrice = 0 THEN 0
        ELSE (S.TotalPrice - S.GrandTotal) / S.TotalPrice
    END AS EffectiveDiscountRate,

    S.GrandTotal AS NetSalesAmount,

    M.BuyingPrice AS CurrentUnitCost,
    S.Quantity * M.BuyingPrice AS EstimatedCOGS,

    S.GrandTotal -
        (S.Quantity * M.BuyingPrice)
        AS EstimatedGrossProfit,

    CASE
        WHEN S.GrandTotal = 0 THEN 0
        ELSE
            (
                S.GrandTotal -
                (S.Quantity * M.BuyingPrice)
            ) / S.GrandTotal
    END AS EstimatedGrossMargin

FROM dbo.Sales S

INNER JOIN dbo.Medicines M
    ON S.MedicineId = M.Id;
GO

SELECT
    COUNT(*) AS SalesRows,
    COUNT(DISTINCT InvoiceNo) AS TotalInvoices,
    SUM(Quantity) AS UnitsSold,
    SUM(GrossSalesAmount) AS GrossSales,
    SUM(DiscountAmount) AS TotalDiscounts,
    SUM(NetSalesAmount) AS NetSales,
    SUM(EstimatedCOGS) AS EstimatedCOGS,
    SUM(EstimatedGrossProfit) AS EstimatedGrossProfit
FROM dbo.vw_SalesAnalytics;