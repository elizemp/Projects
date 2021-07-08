-- Data exploration of the dataset on Covid-19 deaths (https://ourworldindata.org/covid-deaths) using SQL

SELECT *
FROM covid_deaths
WHERE continent IS NOT NULL;

SELECT *
FROM covid_vac;

-- select the data that i'm going to use

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM covid_deaths
ORDER BY 1,2;

-- looking at total case vs. total deaths or in other word what is your percentage to die
-- from the covid in a particular country
SELECT location, date, total_cases, total_deaths, (total_deaths / total_cases) * 100 AS death_percentage
FROM covid_deaths
-- for example what is your death percentage in Russia?
WHERE location = 'Russia' -- this filter is able to show the likelihood of dying from the covid in your country
ORDER BY 1, 2;

-- looking at total cases vs population
-- shows what percentage of population has a covid
SELECT location, date, total_cases, population, (total_cases/population) * 100 AS infected_percentage
FROM covid_deaths
WHERE location = 'Russia'
ORDER BY infected_percentage DESC; -- as we can see the biggest number has its place in 23 of july in 2021

-- looking at the highest infection rates compared to population
SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX((total_cases/population) * 100) AS percent_infected
FROM covid_deaths
GROUP BY location, population
ORDER BY percent_infected DESC;

-- showing countries with highest death count per population
SELECT location, MAX(total_deaths) AS total_death_count
FROM covid_deaths
WHERE total_deaths IS NOT NULL AND continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC;

-- showing continent with highest death count per population
SELECT location, MAX(total_deaths) AS total_death_count_continent
FROM covid_deaths
WHERE total_deaths IS NOT NULL AND continent IS NULL
GROUP BY location
ORDER BY total_death_count_continent DESC;

-- global numbers
SELECT date, SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_death,
       (SUM(CAST(new_deaths AS int)) / SUM(new_cases)) * 100 AS global_death_percent
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY global_death_percent DESC;

-- overall number of deaths and infected cases
SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_death,
       (SUM(CAST(new_deaths AS int)) / SUM(new_cases)) * 100 AS global_death_percent
FROM covid_deaths
WHERE continent IS NOT NULL;


-- looking at the total population vs vaccination
-- use cte
WITH pop_vs_vac (continent, location, date, population, new_vaccination, rolling_people_vaccinated) AS
         (
             SELECT dea.location,
                    dea.continent,
                    dea.date,
                    dea.population,
                    vac.new_vaccinations,
                    SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY
                        dea.location, dea.date) AS rolling_people_vaccinated
-- rolling_people_vaccinated/population
             FROM covid_deaths dea
                      JOIN covid_vac vac
                           ON dea.location = vac.location
                               AND dea.date = vac.date
             WHERE dea.continent IS NOT NULL
               AND vac.new_vaccinations IS NOT NULL
)
SELECT *, (rolling_people_vaccinated/population) * 100 AS percent_of_vaccinated
FROM pop_vs_vac;

-- use temp table
DROP TABLE IF EXISTS PercentPeopleVaccinated
CREATE TEMP TABLE PercentPeopleVaccinated
(
    continent varchar(255),
    location varchar(255),
    date text,
    population numeric,
    new_vaccination numeric,
    rolling_people_vaccinated numeric
)
INSERT INTO PercentPeopleVaccinated
SELECT DISTINCT dea.location, dea.continent, dea.date, dea.population, vac.new_vaccinations,
        SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY
        dea.location, dea.date) AS rolling_people_vaccinated
FROM covid_deaths dea
    JOIN covid_vac vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
SELECT *, (rolling_people_vaccinated/population) * 100 AS Percent_People_Vaccinated
FROM PercentPeopleVaccinated;

-- create a view for a later visualization
CREATE VIEW Perc_People_Vac AS
    SELECT dea.location,
                    dea.continent,
                    dea.date,
                    dea.population,
                    vac.new_vaccinations,
                    SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY
                        dea.location, dea.date) AS rolling_people_vaccinated
-- rolling_people_vaccinated/population
             FROM covid_deaths dea
                      JOIN covid_vac vac
                           ON dea.location = vac.location
                               AND dea.date = vac.date
             WHERE dea.continent IS NOT NULL
               AND vac.new_vaccinations IS NOT NULL;








