--CREATING THE covid_vaccinations TABLE

CREATE TABLE covid_vaccinations(
			iso_code VARCHAR(255),
			continent VARCHAR(255),
			location VARCHAR(255),
			date DATE,
			new_tests BIGINT,
			total_tests BIGINT,
			total_tests_per_thousand DECIMAL(10,3),
			new_tests_per_thousand DECIMAL(10,3),
			new_tests_smoothed INT,
			new_tests_smoothed_per_thousand DECIMAL(10,3),
			positive_rate DECIMAL(10,3),
			tests_per_case DECIMAL(10,1),
			tests_units VARCHAR(255),
			total_vaccinations BIGINT,
			people_vaccinated BIGINT,
			people_fully_vaccinated BIGINT,
			new_vaccinations BIGINT,
			new_vaccinations_smoothed BIGINT,
			total_vaccinations_per_hundred DECIMAL(10,2),
			people_vaccinated_per_hundred DECIMAL(10,2),
			people_fully_vaccinated_per_hundred DECIMAL(10,2),
			new_vaccinations_smoothed_per_million BIGINT,
			stringency_index DECIMAL (10,2),
			population_density DECIMAL (10,3),
			median_age DECIMAL (10,1),
			aged_65_older DECIMAL (10,3),
			aged_70_older DECIMAL (10,3),
			gdp_per_capita DECIMAL (10,3),
			extreme_poverty DECIMAL (10,1),
			cardiovasc_death_rate DECIMAL (10,3),
			diabetes_prevalence DECIMAL (10,2),
			female_smokers DECIMAL (10,1),
			male_smokers DECIMAL (10,1),
			handwashing_facilities DECIMAL (10,3),
			hospital_beds_per_thousand DECIMAL (10,3),
			life_expectancy DECIMAL (10,2),
			human_development_index DECIMAL (10,3)
			)

select * from covid_vaccinations limit 1

drop table covid_vaccinations

--CREATING THE covid_deaths TABLE


CREATE TABLE covid_deaths 
	(
    iso_code VARCHAR(255),
    continent VARCHAR(255),
    location VARCHAR(255),
    date DATE,
    population BIGINT,
    total_cases BIGINT,
    new_cases BIGINT,
    new_cases_smoothed DECIMAL(10,3),
    total_deaths BIGINT,
    new_deaths BIGINT,
    new_deaths_smoothed DECIMAL(10,3),
    total_cases_per_million DECIMAL(10,3),
    new_cases_per_million DECIMAL(10,3),
    new_cases_smoothed_per_million DECIMAL(10,3),
    total_deaths_per_million DECIMAL(10,3),
    new_deaths_per_million DECIMAL(10,3),
    new_deaths_smoothed_per_million DECIMAL(10,3),
    reproduction_rate DECIMAL(10,3),
    icu_patients BIGINT,
    icu_patients_per_million DECIMAL(10,3),
    hosp_patients BIGINT,
    hosp_patients_per_million DECIMAL(10,3),
    weekly_icu_admissions DECIMAL(10,3),
    weekly_icu_admissions_per_million DECIMAL(10,3),
    weekly_hosp_admissions DECIMAL(10,3),
    weekly_hosp_admissions_per_million DECIMAL(10,3)
	);

drop table covid_deaths

select * FROM covid_deaths
----------------------------------------------------------------------THE END OF TABLE CREATION



--select data that we are going to using

SELECT location, date, population, total_cases, new_cases, total_deaths FROM covid_deaths
WHERE continent IS NOT NULL
ORDER BY location, date

--looking at total_cases vs total_deaths	eleg az egyik tenyezot ::numeric-e alakitani->DECIMAL

SELECT location, date, population, total_cases, total_deaths, 
(total_deaths::numeric/total_cases)*100 AS death_percentage FROM covid_deaths
WHERE continent IS NOT NULL
ORDER BY location, date

--looking at my country
--shows likelyhood of dying if you contact covid in your country

SELECT location, date, population, total_cases, total_deaths, 
(total_deaths::numeric/total_cases)*100 AS death_percentage FROM covid_deaths
WHERE location='Hungary' AND continent IS NOT NULL
ORDER BY location, date

--total cases VS population
--shows what percentage of population got covid
SELECT location, date, population, total_cases, total_deaths,
(total_deaths::numeric/total_cases)*100 AS death_percentage,
(total_cases::numeric/population)*100 AS population_infected_pct
FROM covid_deaths
WHERE location='Hungary' AND continent IS NOT NULL
ORDER BY location, date

--country with highest infection rate compared to poulation (population_infected_pct)
SELECT location, population, MAX(total_cases) AS highest_infection_count,
MAX(total_cases::numeric/population)*100 AS population_infected_pct
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY population_infected_pct DESC

--highest dead count per population from covid
--continents are in the list, and where continent column = NULL --> location=continent, WE DON'T WANT THIS

SELECT location, MAX(total_deaths) AS total_death_count
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC

--LET'S BREAK THIS DOWN BY CONTINENT
--showing continent with the highest death count per population

SELECT location, MAX(total_deaths) AS total_death_count
FROM covid_deaths
WHERE continent IS NULL				--only seeing the continents
GROUP BY location
ORDER BY total_death_count DESC

--GLOBAL NUMBERS

SELECT date, SUM(new_cases) AS total_new_cases, SUM(new_deaths) AS total_new_deaths, SUM(new_deaths)/SUM(new_cases)*100 AS new_death_pct
FROM covid_deaths 
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date, total_new_cases

--JOINING THE TWO TABLES

SELECT * FROM covid_deaths dea
JOIN covid_vaccinations vac
ON dea.location=vac.location AND dea.date=vac.date

--looking at Total Polulations VS Vaccinations (we found out we need CTE (down there))

SELECT dea.continent, dea.location, dea.date, population, vac.new_vaccinations, 
SUM(new_vaccinations) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) 
AS cumulative_people_vaccinated --rolling total and with order by it will be a cummulative number
--(cumulative_people_vaccinated/population)*100 AS vaccination_rate_pct
FROM covid_deaths dea
JOIN covid_vaccinations vac
ON dea.location=vac.location AND dea.date=vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date

--USE CTE 	OR...	

WITH pop_vs_vac(continent, location, date, population, new_vaccinations, cumulative_people_vaccinated)--you can let it out()
AS(
SELECT dea.continent, dea.location, dea.date, population, vac.new_vaccinations, 
SUM(new_vaccinations) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) 
AS cumulative_people_vaccinated --rolling total and with order by it will be a cummulative number
--(cumulative_people_vaccinated/population)*100 AS vaccination_rate_pct
FROM covid_deaths dea
JOIN covid_vaccinations vac
ON dea.location=vac.location AND dea.date=vac.date
WHERE dea.continent IS NOT NULL)

SELECT *,
(cumulative_people_vaccinated/population)*100 AS vaccination_rate_pct
FROM pop_vs_vac

--USE TEMP TABLES

CREATE TEMP TABLE pct_population_vaccinated(
continent VARCHAR(255), 
location VARCHAR(255), 
date DATE, 
population INT, 
new_vaccinations INT,
cumulative_people_vaccinated INT
);										--FONTOS ITT MÁR A ";" jel a query végére
INSERT INTO pct_population_vaccinated
SELECT dea.continent, dea.location, dea.date, population, vac.new_vaccinations, 
SUM(new_vaccinations) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) 
AS cumulative_people_vaccinated --rolling total and with order by it will be a cummulative number
--(cumulative_people_vaccinated/population)*100 AS vaccination_rate_pct
FROM covid_deaths dea
JOIN covid_vaccinations vac
ON dea.location=vac.location AND dea.date=vac.date
WHERE dea.continent IS NOT NULL;

SELECT *,
(cumulative_people_vaccinated/population)*100 AS vaccination_rate_pct
FROM pct_population_vaccinated

--IF YOU HAVE TO ALTER IT USE--> 
DROP TABLE IF EXISTS pct_population_vaccinated

--EARLIER QUERY, WE ARE MAKING VIEW FROM THIS--> FOR VISUALISATIONS

CREATE VIEW vaccination_rate_pct AS
SELECT dea.continent, dea.location, dea.date, population, vac.new_vaccinations, 
SUM(new_vaccinations) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) 
AS cumulative_people_vaccinated --rolling total and with order by it will be a cummulative number
--(cumulative_people_vaccinated/population)*100 AS vaccination_rate_pct
FROM covid_deaths dea
JOIN covid_vaccinations vac
ON dea.location=vac.location AND dea.date=vac.date
WHERE dea.continent IS NOT NULL