/* Creates a continuous calendar covering the source-data date range. */
USE Olist_Ecommerce_Analytics;
GO

DROP TABLE IF EXISTS dbo.dim_date;
GO

CREATE TABLE dbo.dim_date (
    date_key DATE NOT NULL PRIMARY KEY,
    calendar_year INT NOT NULL,
    calendar_quarter INT NOT NULL,
    month_number INT NOT NULL,
    month_name NVARCHAR(20) NOT NULL,
    year_month CHAR(7) NOT NULL,
    day_of_month INT NOT NULL,
    day_name NVARCHAR(20) NOT NULL,
    week_of_year INT NOT NULL
);
GO

DECLARE @start_date DATE = '2016-09-04';
DECLARE @end_date DATE = '2020-04-09';

;WITH calendar AS (
    SELECT @start_date AS date_key
    UNION ALL
    SELECT DATEADD(DAY, 1, date_key)
    FROM calendar
    WHERE date_key < @end_date
)
INSERT INTO dbo.dim_date (
    date_key, calendar_year, calendar_quarter, month_number,
    month_name, year_month, day_of_month, day_name, week_of_year
)
SELECT
    date_key,
    YEAR(date_key),
    DATEPART(QUARTER, date_key),
    MONTH(date_key),
    DATENAME(MONTH, date_key),
    CONVERT(CHAR(7), date_key, 120),
    DAY(date_key),
    DATENAME(WEEKDAY, date_key),
    DATEPART(ISO_WEEK, date_key)
FROM calendar
OPTION (MAXRECURSION 0);
GO

SELECT MIN(date_key) AS first_date, MAX(date_key) AS last_date, COUNT(*) AS date_count
FROM dbo.dim_date;
GO
