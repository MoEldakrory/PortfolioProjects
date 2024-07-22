--Table Creation and Data Insertion
CREATE TABLE Car_Prices
(
    year int,
    make text,
    model text,
    trim text,
    body text,
    transmission text,
    vin text,
    state text,
    condition int,
    odometer int,
    color text,
    interior text,
    seller text,
    mmr int,
    sellingprice int,
    saledate varchar(40)
);

COPY Car_Prices
FROM 'C:\Users\moeld\Desktop\SQL learning\csv_files\car_prices.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');


--Data Cleaning

--Rearranged some shifted rows where the transmission column had incorrect data.

UPDATE car_prices
SET body = transmission,
    transmission = vin,
    vin = state,
    state = condition,
    condition = odometer,
    odometer = color::int,
    color = interior,
    interior = seller,
    seller = mmr,
    mmr = sellingprice,
    sellingprice = saledate::int,
    saledate = null
WHERE lower(transmission) = 'sedan';


--Added a new column dateofsale with a timestamp data type and populated it with values from saledate.

ALTER TABLE car_prices
ADD COLUMN dateofsale timestamp;

UPDATE car_prices
SET dateofsale = left(saledate, 24)::timestamp;


--Added a new column short_make to standardize car make names.

ALTER TABLE car_prices
ADD COLUMN short_make text;

UPDATE car_prices
SET short_make = CASE
    WHEN upper(make) LIKE 'DODGE%' THEN 'DODGE'
    WHEN upper(make) LIKE 'FORD%' THEN 'FORD'
    WHEN upper(make) LIKE 'GMC%' THEN 'GMC'
    WHEN upper(make) LIKE 'HYUNDAI%' THEN 'HYUNDAI'
    WHEN upper(make) = 'LANDROVER' THEN 'LAND ROVER'
    WHEN upper(make) LIKE 'MAZDA%' THEN 'MAZDA'
    WHEN upper(make) LIKE 'MERCEDES%' THEN 'MERCEDES'
    WHEN upper(make) LIKE 'CHEV%' THEN 'CHEVROLET'
    ELSE upper(make)
END;

--Data Analysis and Reporting

--Sales Count by Make for 2014 and 2015

SELECT count(short_make) AS Sales_Quantity, short_make AS Make, extract(year FROM dateofsale) AS Year
FROM car_prices
WHERE extract(year FROM dateofsale) = 2014 OR extract(year FROM dateofsale) = 2015 AND short_make IS NOT NULL
GROUP BY extract(year FROM dateofsale), short_make
ORDER BY Make;

--Percentage Growth of Car Sales by Make

SELECT short_make,
(COUNT(CASE WHEN extract(year FROM dateofsale) = 2015 THEN 1 END) -
 COUNT(CASE WHEN extract(year FROM dateofsale) = 2014 THEN 1 END)) /
COUNT(CASE WHEN extract(year FROM dateofsale) = 2014 THEN 1 END) * 100
FROM car_prices
WHERE short_make IS NOT NULL
GROUP BY short_make
HAVING COUNT(CASE WHEN extract(year FROM dateofsale) = 2014 THEN 1 END) > 25
AND COUNT(CASE WHEN extract(year FROM dateofsale) = 2015 THEN 1 END) > 25;

--Top 3 Sold Makes

SELECT short_make, COUNT(*) AS counting
FROM car_prices
GROUP BY short_make
ORDER BY counting DESC
LIMIT 3;

--Top 3 Car-High-Selling States

SELECT state, COUNT(*) AS counting
FROM car_prices
GROUP BY state
ORDER BY counting DESC
LIMIT 3;

--Comparing Sales of Automatic and Manual Cars

SELECT transmission, COUNT(*) AS counting
FROM car_prices
WHERE transmission IS NOT NULL AND extract(year FROM dateofsale) IS NOT NULL
GROUP BY transmission
ORDER BY counting DESC;

--Number of Sales by Each Month

SELECT extract(month FROM dateofsale) AS month, COUNT(*) AS counting
FROM car_prices
GROUP BY month
ORDER BY counting DESC;

--Number of Sales and Percentage by Transmission

SELECT transmission, COUNT(*) AS sales_number,
COUNT(*) * 100 / (SELECT COUNT(*) FROM car_prices WHERE transmission IS NOT NULL) AS percentage
FROM car_prices
WHERE transmission IS NOT NULL
GROUP BY transmission
ORDER BY sales_number DESC;

--Most Sold Car Makes

SELECT make, COUNT(*) AS number
FROM car_prices
WHERE transmission = 'manual'
GROUP BY make
ORDER BY number DESC;

--Selling Price Pivot Table by Makes and Colors

SELECT
    short_make,
    AVG(CASE WHEN color = 'red' THEN sellingprice END) AS Red,
    AVG(CASE WHEN color = 'blue' THEN sellingprice END) AS Blue,
    AVG(CASE WHEN color = 'green' THEN sellingprice END) AS Green,
    AVG(CASE WHEN color = 'black' THEN sellingprice END) AS Black,
    AVG(CASE WHEN color = 'white' THEN sellingprice END) AS White,
    AVG(CASE WHEN color = 'beige' THEN sellingprice END) AS Beige,
    AVG(CASE WHEN color = 'brown' THEN sellingprice END) AS Brown,
    AVG(CASE WHEN color = 'burgundy' THEN sellingprice END) AS Burgundy,
    AVG(CASE WHEN color = 'charcoal' THEN sellingprice END) AS Charcoal,
    AVG(CASE WHEN color = 'gold' THEN sellingprice END) AS Gold,
    AVG(CASE WHEN color = 'gray' THEN sellingprice END) AS Gray,
    AVG(CASE WHEN color = 'lime' THEN sellingprice END) AS Lime,
    AVG(CASE WHEN color = 'off-white' THEN sellingprice END) AS OffWhite,
    AVG(CASE WHEN color = 'orange' THEN sellingprice END) AS Orange,
    AVG(CASE WHEN color = 'pink' THEN sellingprice END) AS Pink,
    AVG(CASE WHEN color = 'purple' THEN sellingprice END) AS Purple,
    AVG(CASE WHEN color = 'silver' THEN sellingprice END) AS Silver,
    AVG(CASE WHEN color = 'turquoise' THEN sellingprice END) AS Turquoise,
    AVG(CASE WHEN color = 'yellow' THEN sellingprice END) AS Yellow
FROM car_prices
GROUP BY short_make;

--Statistical Measures of Selling Prices

SELECT
    AVG(sellingprice) AS avg_price,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sellingprice) AS median_price,
    MIN(sellingprice) AS min_price,
    MAX(sellingprice) AS max_price
FROM Car_Prices;

--Monthly Sales Trends Over the Years

SELECT
    EXTRACT(YEAR FROM dateofsale) AS sale_year,
    EXTRACT(MONTH FROM dateofsale) AS sale_month,
    COUNT(*) AS num_sales
FROM Car_Prices
GROUP BY sale_year, sale_month
ORDER BY sale_year, sale_month;

--Average Selling Prices Across Different Conditions

SELECT
    condition,
    AVG(sellingprice) AS avg_price
FROM Car_Prices
GROUP BY condition
ORDER BY condition;

--Top 5 States Based on Total Sales Amount

SELECT
    state,
    SUM(sellingprice) AS total_sales_amount
FROM Car_Prices
GROUP BY state
ORDER BY total_sales_amount DESC
LIMIT 5;

--Average Ratio of MMR to Selling Price

SELECT
    AVG(CAST(mmr AS FLOAT) / sellingprice) AS avg_mmr_to_price_ratio
FROM Car_Prices
WHERE sellingprice > 0;

--Top 10 Sellers Based on Number of Cars Sold

SELECT
    seller,
    COUNT(*) AS num_cars_sold
FROM Car_Prices
GROUP BY seller
ORDER BY num_cars_sold DESC
LIMIT 10;

--Monthly Sales Trends Over a Specified Period

WITH MonthlySales AS (
    SELECT
        EXTRACT(YEAR FROM dateofsale) AS sale_year,
        EXTRACT(MONTH FROM dateofsale) AS sale_month,
        COUNT(*) AS num_sales
    FROM Car_Prices
    GROUP BY sale_year, sale_month
)
SELECT
    sale_year,
    sale_month,
    num_sales,
    LAG(num_sales) OVER (ORDER BY sale_year, sale_month) AS prev_month_sales,
    CASE
        WHEN LAG(num_sales) OVER (ORDER BY sale_year, sale_month) IS NULL THEN NULL
        ELSE (num_sales - LAG(num_sales) OVER (ORDER BY sale_year, sale_month)) / LAG(num_sales) OVER (ORDER BY sale_year, sale_month)
    END AS monthly_growth_rate
FROM MonthlySales
ORDER BY sale_year, sale_month;

--Top 10 Car-Year Sales

SELECT year, COUNT(*) AS num_sales
FROM car_prices
GROUP BY year
ORDER BY num_sales DESC
LIMIT 10;

--Most Sold Car Makes in Each State

WITH SalesCount AS (
    SELECT
        state,
        short_make AS make,
        COUNT(*) AS sales_count
    FROM car_prices
    GROUP BY state, short_make
),
RankedSales AS (
    SELECT
        state,
        make,
        sales_count,
        RANK() OVER (PARTITION BY state ORDER BY sales_count DESC) AS rank
    FROM SalesCount
)
SELECT
    state,
    make,
    sales_count
FROM RankedSales
WHERE rank = 1;
