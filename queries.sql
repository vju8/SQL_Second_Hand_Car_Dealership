-- 1) Read the data. Display the tables
SELECT * FROM project_portfolio.cars;
SELECT * FROM project_portfolio.fuel_prices;

-- 2) Describe the tables
DESCRIBE cars;
DESCRIBE fuel_prices;

-- 3) Get the count of total records of cars
SELECT COUNT(*) AS count_records FROM project_portfolio.cars;

-- 4) What are the records with limited information (NULL values present)? => Potential to improve data quality
SELECT * FROM cars WHERE consumption IS NULL;
	-- 4.1) How many of those cars with unsufiecient information are there? 
SELECT COUNT(*) AS count_little_info
FROM cars
WHERE consumption IS NULL;


-- 5) Investigate the distinct values in each field (where it makes sense: year, fuel, seller_type, transmission, owner, seats)
SELECT DISTINCT(year) FROM project_portfolio.cars;
SELECT DISTINCT(fuel) FROM project_portfolio.cars;
SELECT DISTINCT(seller_type) FROM project_portfolio.cars;
SELECT DISTINCT(transmission) FROM project_portfolio.cars;
SELECT DISTINCT(owner) FROM project_portfolio.cars;
SELECT DISTINCT(seats) FROM project_portfolio.cars;


-- 6) Data cleaning: Adjust the values in the transmission column. Space before first letter doubles the distinct values
	-- 6.1) Update the value from " Manual" to "Manual"
UPDATE project_portfolio.cars
SET transmission = "Manual"
WHERE transmission = " Manual";
	-- 6.2) Update the value from " Automatic" to "Automatic"
UPDATE project_portfolio.cars
SET transmission = "Automatic"
WHERE transmission = " Automatic";
	-- 6.3) Recheck the distinct values in the transmission field
SELECT DISTINCT(transmission) FROM project_portfolio.cars;


-- 7) Data cleaning: convert currency from indian rupee to euro => (1 INR = 0.0113 EUR)
UPDATE  project_portfolio.cars 
SET selling_price = selling_price * 0.0113;


-- 8) Rename the column mileage to consumption 
ALTER TABLE project_portfolio.cars
RENAME COLUMN mileage TO consumption;


-- 9) Check how many cars are available in 2020, 2021, 2022, 2023 in total and per year
SELECT COUNT(*) FROM project_portfolio.cars WHERE year IN (2020, 2021, 2022, 2023);   -- total of the cars in those years
SELECT COUNT(*) FROM project_portfolio.cars WHERE year = 2020;   -- 74
SELECT COUNT(*) FROM project_portfolio.cars WHERE year = 2021;   -- 7
SELECT COUNT(*) FROM project_portfolio.cars WHERE year = 2022;   -- 7
SELECT COUNT(*) FROM project_portfolio.cars WHERE year = 2023;   -- 5
SELECT year, COUNT(*) FROM project_portfolio.cars WHERE year IN (2020, 2021, 2022, 2023) GROUP BY year; 


-- 10) Check how many diesel and petrol cars are there from year 2020
SELECT COUNT(*) FROM cars WHERE (fuel in ("Diesel", "Petrol")) AND (year = 2020); 


-- 11) Check how many cars per year are there with respect to the fuel
SELECT year, fuel, COUNT(*) FROM cars WHERE fuel = "Petrol" GROUP BY year; 
SELECT year, fuel, COUNT(*) FROM cars WHERE fuel = "Diesel" GROUP BY year; 
SELECT year, fuel, COUNT(*) FROM cars WHERE fuel = "CNG" GROUP BY year; 
SELECT year, fuel, COUNT(*) FROM cars WHERE fuel = "LPG" GROUP BY year; 
SELECT year, fuel, COUNT(*) FROM cars GROUP BY year, fuel;     -- GROUP BY combined version


-- 12) Select the years for which there are more than 200 cars available
SELECT  year, COUNT(*) FROM cars GROUP BY year HAVING COUNT(*) > 200; 


-- 13) Select the car count for cars beween 2015 and 2023 and order the records by year
SELECT year, COUNT(*) FROM cars WHERE year >= 2015 AND year <= 2023 GROUP BY year; 
SELECT year, COUNT(*) FROM cars WHERE year BETWEEN 2015 AND 2023 GROUP BY year;    -- same thing


-- 14) Select the detailed car overview for cars beween 2015 and 2023
SELECT * FROM cars WHERE year >= 2015 AND year <= 2023 ORDER BY year; 


-- 15) Select the detailed car overview from year 2020, petrol as fuel, automatic transmission, minimum 4 seats and first owner only
SELECT * FROM cars 
WHERE (year = 2020) AND (fuel = "Petrol") AND (transmission = "Automatic") AND (seats >= 4) AND (owner = "First Owner");


-- 16) For each year, display the minimum, average and maximum selling price of each car having less than 100000 km driven
SELECT year as "Year", MIN(selling_price) AS "MinSellPrice", FLOOR(AVG(selling_price)) AS "AvgSellPrice", MAX(selling_price) AS "MaxSellPrice"
FROM project_portfolio.cars
WHERE km_driven < 100000
GROUP BY year
ORDER BY year ASC;


-- 17) Add the field 'brand' to the cars table
ALTER TABLE project_portfolio.cars 
ADD COLUMN IF NOT EXISTS brand VARCHAR(255) FIRST;
	-- 17.1) Populate the brand field with the 1st element of the splitted substring from the Name field
UPDATE project_portfolio.cars
SET brand = SUBSTRING_INDEX(Name,' ',1);
	-- 17.2) Adjust 'Land' Brand to 'Land Rover' (the only one in the list with this behavior)
UPDATE project_portfolio.cars
SET brand = 'Land Rover'
WHERE brand = 'Land';
	-- 17.3) Review the result
SELECT * FROM project_portfolio.cars;
 

-- 18) Elaborate how much kg or liters of fuel is needed per driven kilometer and calculate the price per driven km
	-- 18.1) Separate the number from the unit in the consumption field and add the field 'consumption_unit' to the cars table 
ALTER TABLE project_portfolio.cars 
ADD COLUMN IF NOT EXISTS consumption_unit VARCHAR(255) AFTER consumption;
	-- 18.2) Populate the consumption_unit field with the unit given by the splitted substring from the consumption field
UPDATE project_portfolio.cars
SET consumption_unit = SUBSTRING_INDEX(consumption,' ',-1);
	-- 18.3) Remove the unit in the consumption field and just leave the numeric value
UPDATE project_portfolio.cars
SET consumption = SUBSTRING_INDEX(consumption,' ',1);
	-- 18.4) For the LPG (liquified petroleum gas), adjust the unit from km/kg to km/l, since this fuel is liquid and pricing given that way. Converstion: 1 kg LPG = 1.96 l LPG
UPDATE project_portfolio.cars
SET consumption = consumption / 1.96  
WHERE fuel = "LPG";
	-- 18.5) Change the consumption unit of the newly adjusted consumption values for LPG to kmpl
UPDATE project_portfolio.cars
SET consumption_unit = "kmpl"
WHERE fuel = "LPG";
	-- 18.6) Change the unit for the consumption from kmpl to lpkm and from km/kg to kg/km (reverse the units)
UPDATE project_portfolio.cars
SET consumption = 1 / consumption
WHERE consumption != 0;
	-- 18.7) Change the consumption unit of the newly adjusted consumption values (kmpl => lpkm)
UPDATE project_portfolio.cars
SET consumption_unit = 'lpkm'
WHERE consumption_unit = 'kmpl';
	-- 18.8) Change the consumption unit of the newly adjusted consumption values (km/kg => kg/km)
UPDATE project_portfolio.cars
SET consumption_unit = 'kg/km'
WHERE consumption_unit = 'km/kg';
	-- 18.9) Introduce the field price_per_km and set data type as decimal
ALTER TABLE project_portfolio.cars 
ADD COLUMN IF NOT EXISTS price_per_km DECIMAL(4,3) AFTER seats;
	-- 18.10) Join the tables cars and fuel_prices and calculate the price per driven kilometer
UPDATE cars C
LEFT JOIN fuel_prices P
ON C.fuel = P.fuel
SET C.price_per_km = C.consumption * P.price; 
	-- 18.11) Review results
SELECT * FROM project_portfolio.cars;


-- 19) The customer requests the TOP 10 cars ordered by operating costs (price per km), which have at most 100000 km driven and the models aren't older than 2020
SELECT * 
FROM cars 
WHERE (price_per_km < 100000) AND (year > 2020)
ORDER BY price_per_km ASC;


-- 20) A family on budget is interested in a car with 7+ seats, automatic transmission and low aquisition price for their road trips. What are the TOP 10 dealer proposals?
SELECT * FROM cars
WHERE (seats >= 7) AND (transmission = "Automatic") AND (seller_type = 'Dealer')
ORDER BY selling_price ASC
LIMIT 10;

