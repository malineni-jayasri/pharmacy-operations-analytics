USE PharmaDB;
GO

CREATE OR ALTER VIEW dbo.vw_ReturnAnalytics
AS

SELECT
    R.Id AS ReturnId,
    R.InvoiceNo,
    R.ReturnDate,

    CASE
        WHEN R.CustomerName IS NULL
          OR LTRIM(RTRIM(R.CustomerName)) = ''
        THEN 'CUST-UNKNOWN'
        ELSE CONCAT(
            'CUST-',
            LEFT(
                CONVERT(
                    VARCHAR(64),
                    HASHBYTES(
                        'SHA2_256',
                        LOWER(LTRIM(RTRIM(R.CustomerName)))
                    ),
                    2
                ),
                12
            )
        )
    END AS CustomerKey,

    R.MedicineId,
    M.Name AS MedicineName,
    M.Brand,
    M.Category,

    R.ReturnedQty,
    R.UnitPrice,
    R.RefundAmount,

    OS.OriginalSaleDate,
    OS.OriginalUnitsSold,
    OS.OriginalNetSales,

    DATEDIFF(
        DAY,
        OS.OriginalSaleDate,
        R.ReturnDate
    ) AS DaysToReturn,

    CASE
        WHEN OS.OriginalUnitsSold = 0 THEN 0
        ELSE
            CAST(R.ReturnedQty AS DECIMAL(18,4))
            / OS.OriginalUnitsSold
    END AS QuantityReturnRate

FROM dbo.Returns R

INNER JOIN dbo.Medicines M
    ON R.MedicineId = M.Id

OUTER APPLY
(
    SELECT
        MIN(S.SaleDate) AS OriginalSaleDate,
        SUM(S.Quantity) AS OriginalUnitsSold,
        SUM(S.GrandTotal) AS OriginalNetSales
    FROM dbo.Sales S
    WHERE S.InvoiceNo = R.InvoiceNo
      AND S.MedicineId = R.MedicineId
) OS;
GO

SELECT
    COUNT(*) AS ReturnRows,
    COUNT(DISTINCT InvoiceNo) AS InvoicesWithReturns,
    SUM(ReturnedQty) AS UnitsReturned,
    SUM(RefundAmount) AS TotalRefundAmount,
    AVG(CAST(DaysToReturn AS DECIMAL(10,2)))
        AS AverageDaysToReturn,
    SUM(CASE
        WHEN ReturnedQty > OriginalUnitsSold
        THEN 1 ELSE 0
    END) AS OverReturnedRows
FROM dbo.vw_ReturnAnalytics;