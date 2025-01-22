/*
Exploring Covid 19 Data

Skills used include: Joins, CTEs, Temp Tables, Windows Functions, Aggregate Functions, Converting Data Types, Creating Views

*/

SELECT *
FROM CovidPortifolio..CovidDeaths$
WHERE continent is not NULL -- This is to make sure the location only has Countries in it
ORDER BY 3,4

-- Select Data to explore first

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidPortifolio..CovidDeaths$
WHERE continent is not NULL
ORDER BY 1,2


-- Looks at Total Cases vs Total Deaths
-- Shows the likelihood of dying if you contract Covid in your country

SELECT location, date, total_cases, total_deaths, ROUND((total_deaths/total_cases)*100,2) AS DeathPercentage
FROM CovidPortifolio..CovidDeaths$
WHERE location LIKE '%Zambia%'
ORDER BY 1,2


-- Shows Total Cases vs Population
-- Shows what percentage of the population infected with COVID

SELECT location, date, population, total_cases, (total_cases/population)*100 AS InfectedPercentage
FROM CovidPortifolio..CovidDeaths$
WHERE location LIKE '%Zambia%'
ORDER BY 1,2


-- Looks at Countries with Highest Infection Rate compared to Population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentagePopulationInfected
FROM CovidPortifolio..CovidDeaths$
GROUP BY location, population
ORDER BY PercentagePopulationInfected DESC


-- Shows Countries with the Highest Death Count per Population

SELECT location, MAX(CAST(total_deaths as int)) AS TotalDeathCount
FROM CovidPortifolio..CovidDeaths$
WHERE continent is not NULL
GROUP BY location
ORDER BY TotalDeathCount DESC


-- Breaking things down by Continent
-- Shows Continents with the highest death count per population

SELECT continent, MAX(CAST(total_deaths as int)) AS TotalDeathCount
FROM CovidPortifolio..CovidDeaths$
WHERE continent is not NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC


-- Add Continent to all the previous code chunks to drill down for Visualization with Tableau
-- GLOBAL NUMBERS (looking at the numbers without Continent, Countries, or location)

SELECT date, SUM(new_cases) as total_cases, SUM(CAST(new_deaths as int)) As total_deaths, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
FROM CovidPortifolio..CovidDeaths$
WHERE continent is not NULL
GROUP BY date
ORDER BY 1,2


-- Looks at Total Population vs Vaccinations
-- Shows the Percentage of the Population that has received at least one COVID-19 vaccine

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM CovidPortifolio..CovidDeaths$ dea
join CovidPortifolio..CovidVaccinations$ vac
	on dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not NULL
ORDER BY 2,3


-- Using CTE to perform Calculations on Partition By in the Previous query

with PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location,
dea.date) AS RollingPeopleVaccinated
FROM CovidPortifolio..CovidDeaths$ dea
join CovidPortifolio..CovidVaccinations$ vac
	on dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not NULL
-- ORDER BY 2,3
)
SELECT *, ROUND((RollingPeopleVaccinated/population)*100, 2) AS PercentagePeopleVaccinated
FROM PopvsVac


-- Use TEMP TABLE to perform Calculations on Partition By in the Previous query

DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccination numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location,
dea.date) AS RollingPeopleVaccinated
FROM CovidPortifolio..CovidDeaths$ dea
join CovidPortifolio..CovidVaccinations$ vac
	on dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not NULL 
-- ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/population)*100 AS PercentagePeopleVaccinated
FROM #PercentPopulationVaccinated


-- Create View to store data for visualizations

CREATE VIEW PercentPopulationVaccinated as 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location,
dea.date) AS RollingPeopleVaccinated
FROM CovidPortifolio..CovidDeaths$ dea
join CovidPortifolio..CovidVaccinations$ vac
	on dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not NULL 


