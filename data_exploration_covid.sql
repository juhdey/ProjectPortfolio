USE covid_data;
SELECT * 
FROM covid_death_data;

/* 
Data Exploration 
*/

-- Select relevant data
SELECT location, date, total_cases, total_deaths, new_cases, new_deaths, population
FROM covid_death_data
ORDER BY 1, 2 DESC;


-- Looking at Total Cases vs Total Deaths
SELECT location, date, total_cases, total_deaths, (total_deaths / total_cases) * 100 AS death_per_cases
FROM covid_death_data
WHERE continent != '0' AND location NOT IN ('High income', 'Upper middle income', 
						'Lower middle income', 'Low income')
ORDER BY location DESC;

-- Looking at location specific death rates (in the United States)
SELECT location, date, total_cases, total_deaths, (total_deaths / total_cases) * 100 AS death_per_cases
FROM covid_death_data
WHERE location LIKE '%states'
ORDER BY 2 DESC;

-- Exploring Total Cases vs. Population 
SELECT location, date, total_cases, population, (total_cases / population) * 100 AS popuation_death_rate
FROM covid_death_data
WHERE location LIKE '%states'
ORDER BY (total_cases / population) * 100 DESC;

-- Exploring special values such as having no death cases
SELECT location, SUM(total_deaths) AS total_deaths
FROM covid_death_data
WHERE continent != '0' AND location NOT IN ('High income', 'Upper middle income', 
						'Lower middle income', 'Low income')
GROUP BY location
HAVING total_deaths = 0;

-- How countries' infection rate changes by year and then by month
SELECT location, population, date_format(date, '%Y/%m'), MAX(total_cases) AS top_infection, 
		MAX((total_cases / population) * 100) AS infection_rate
FROM covid_death_data
WHERE continent != '0' AND location NOT IN ('High income', 'Upper middle income', 
						'Lower middle income', 'Low income')
GROUP BY location, population, date_format(date, '%Y/%m')
ORDER BY location DESC;


-- Looking at Countries with Highest Infection Rate based on population
SELECT location, population, 
		MAX(total_cases) AS top_infection_count, 
		MAX((total_cases / population) * 100) AS top_infection_rate
FROM covid_death_data
WHERE continent != '0' AND location NOT IN ('High income', 'Upper middle income', 
						'Lower middle income', 'Low income')
GROUP BY location, population
ORDER BY top_infection_rate DESC;

-- Countries with Highest Death Rate
SELECT location, MAX(total_deaths) AS top_death_count
FROM covid_death_data
WHERE location NOT IN ('High income', 'Upper middle income', 
						'Lower middle income', 'Low income',
                        'World', 'Europe', 'Asia', 'North America', 'South America',
                        'European Union', 'Africa')
GROUP BY location
ORDER BY top_death_count DESC;

-- Break Down Death Count By Continents
SELECT continent, MAX(total_deaths) AS top_death_count	
FROM covid_death_data
WHERE continent != '0'
GROUP BY continent
ORDER BY top_death_count DESC;

-- Aggregate numbers globally 
SELECT date, SUM(new_cases) AS global_new_cases, SUM(new_deaths) AS global_new_deaths, 
			SUM(new_deaths)/SUM(new_cases) * 100 AS global_death_rate
FROM covid_death_data
WHERE continent != '0' AND location NOT IN ('High income', 'Upper middle income', 
						'Lower middle income', 'Low income')
GROUP BY date
ORDER BY global_death_rate DESC;

-- Breakdown global numbers by year
SELECT year(date) AS year, SUM(new_cases) AS global_total_cases, SUM(new_deaths) AS global_total_deaths,
		SUM(new_deaths)/SUM(new_cases) * 100 AS global_death_rate
FROM covid_death_data
WHERE continent != '0' AND location NOT IN ('High income', 'Upper middle income', 
						'Lower middle income', 'Low income')
GROUP BY year(date)
ORDER BY global_death_rate DESC;

-- Check for values that may not align with queries
SELECT continent, location
FROM covid_death_data
WHERE continent = '0'
ORDER BY location DESC;

-- Total vaccinations per location by date
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
		SUM(vac.new_vaccinations) OVER 
        (PARTITION BY location
        ORDER BY dea.location, dea.date) AS rolling_total_of_vacs
FROM covid_death_data dea
JOIN covid_vac_data vac
ON dea.location = vac.location AND
	dea.date = vac.date
WHERE dea.continent != '0' AND dea.location NOT IN ('High income', 'Upper middle income', 
						'Lower middle income', 'Low income')
ORDER BY 2, 3 DESC;

-- Create CTE for rolling percentage 
WITH pop_vs_vac (Continent, Location, Date, Population, New_Vaccinations, Rolling_Total) 
AS (
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
		SUM(vac.new_vaccinations) OVER 
        (PARTITION BY location
        ORDER BY dea.location, dea.date) AS rolling_total_of_vacs
FROM covid_death_data dea
JOIN covid_vac_data vac
ON dea.location = vac.location AND
	dea.date = vac.date
WHERE dea.continent != '0' AND dea.location NOT IN ('High income', 'Upper middle income', 
						'Lower middle income', 'Low income')
)
SELECT *, (Rolling_Total / Population) * 100 AS Vac_Rate
FROM pop_vs_vac;
    
-- Create temp table to execute more queries
DROP TABLE IF EXISTS pop_vacced;

CREATE TEMPORARY TABLE pop_vacced (
	Continent varchar(50),
    Location varchar(50),
    Date date,
    Population DOUBLE,
    New_Vaccinations DOUBLE,
    Rolling_Total DOUBLE
);

INSERT INTO pop_vacced
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
		SUM(vac.new_vaccinations) OVER 
        (PARTITION BY location
        ORDER BY dea.location, dea.date) AS rolling_total_of_vacs
FROM covid_death_data dea
JOIN covid_vac_data vac
ON dea.location = vac.location AND
	dea.date = vac.date
WHERE dea.continent != '0' AND dea.location NOT IN ('High income', 'Upper middle income', 
						'Lower middle income', 'Low income');

-- Rolling Vaccination Rate
SELECT *, (Rolling_Total / Population) * 100 AS Vac_Rate
FROM pop_vacced;


-- Average Vaccination Rate Per Year
SELECT year(Date), MAX(Rolling_Total) AS total_vac, MAX(Population) AS population, 
		AVG((Rolling_Total / Population) * 100) AS vac_rate
FROM pop_vacced
GROUP BY year(Date);

/* 
Create Views for data visualizations 
*/

DROP VIEW IF EXISTS pop_vacced; 

CREATE VIEW pop_vacced AS
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
			SUM(vac.new_vaccinations) OVER 
			(PARTITION BY location
			ORDER BY dea.location, dea.date) AS rolling_total_of_vacs
	FROM covid_death_data dea
	JOIN covid_vac_data vac
	ON dea.location = vac.location AND
		dea.date = vac.date
	WHERE dea.continent != '0' AND dea.location NOT IN ('High income', 'Upper middle income', 
							'Lower middle income', 'Low income');

DROP VIEW IF EXISTS top_infec_rate;

CREATE VIEW top_infec_rate AS 
	SELECT location, population, 
		MAX(total_cases) AS top_infection_count, 
		MAX((total_cases / population) * 100) AS top_infection_rate
	FROM covid_death_data
	WHERE location NOT IN ('High income', 'Upper middle income', 
							'Lower middle income', 'Low income',
							'World', 'Europe', 'Asia', 'North America', 'South America',
							'European Union', 'Africa')
	GROUP BY location, population
	ORDER BY top_infection_rate DESC;

DROP VIEW IF EXISTS infec_rate_by_year_month;

CREATE VIEW infec_rate_by_year_month AS
	SELECT location, population, date_format(date, '%Y/%m'), MAX(total_cases) AS top_infection, 
			MAX((total_cases / population) * 100) AS infection_rate
	FROM covid_death_data
	WHERE continent != '0' AND location NOT IN ('High income', 'Upper middle income', 
							'Lower middle income', 'Low income')
	GROUP BY location, population, date_format(date, '%Y/%m');
    
DROP VIEW IF EXISTS top_death_by_continent;

CREATE VIEW top_death_by_continent AS 
	SELECT continent, MAX(total_deaths) AS top_death_count	
	FROM covid_death_data
	WHERE continent != '0'
	GROUP BY continent
	ORDER BY top_death_count DESC;
    
DROP VIEW IF EXISTS global_numbers_by_year;

CREATE VIEW global_numbers_by_year AS
	SELECT year(date) AS year, SUM(new_cases) AS global_new_cases, SUM(new_deaths) AS global_new_deaths,
		SUM(new_deaths)/SUM(new_cases) * 100 AS global_death_rate
	FROM covid_death_data
	WHERE continent != '0' AND location NOT IN ('High income', 'Upper middle income', 
							'Lower middle income', 'Low income')
	GROUP BY year(date)
	ORDER BY global_death_rate DESC;
    
DROP VIEW IF EXISTS vaccination_rate_by_year;

CREATE VIEW vaccination_rate_by_year AS
	SELECT year(date), MAX(rolling_total_of_vacs) AS total_vac, MAX(population) AS population, 
		AVG((rolling_total_of_vacs / population) * 100) AS vac_rate
	FROM pop_vacced
	GROUP BY year(Date);


SELECT *
FROM pop_vacced;

SELECT *
FROM global_numbers_by_year;

SELECT *
FROM top_death_by_continent;

SELECT *
FROM top_infec_rate;

SELECT * 
FROM vaccination_rate_by_year;

SELECT *
FROM infec_rate_by_year_month
ORDER BY location DESC;

    
    




                        
	


