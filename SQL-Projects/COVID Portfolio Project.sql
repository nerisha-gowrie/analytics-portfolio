/* =======================================================
COVID-19 DATA EXPLORATION (SQL Server)
Dataset: CovidDeaths, CovidVaccinations
Database: PortfolioProject

Goal:
- Explore cases, deaths, infection rates
- Compare death % and infection % by country
- Summarise global numbers
- Analyse vaccination progress using window functions
- Provide outputs usable for visualisation (View)

Notes:
- Filtering out rows where continent IS NULL removes 
aggregate like "World", "European Union", etc.
======================================================= */


/* ======================================================= 

1. QUICK DATA CHECK

======================================================= */

SELECT *
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent is NOT NULL
ORDER BY 3, 4;

--SELECT *
--FROM PortfolioProject.dbo.CovidVaccinations
--ORDER BY 3, 4


/* ======================================================= 

2. SELECT VARIABLES USED MOST OFTEN

======================================================= */

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent is NOT NULL
ORDER BY 1, 2;


/* ======================================================= 

3. TOTAL CASES vs TOTAL DEATHS
Likelihood of dying if you contract Covid (South Africa)

======================================================= */

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE location = 'South Africa'
AND continent IS NOT NULL
ORDER BY 1, 2;


/* ======================================================= 

4. TOTAL CASES vs POPULATION
% of population infected (South Africa)

======================================================= */

SELECT location, date, total_cases, population, (total_cases/population)*100 AS PopulationPercentageInfected
FROM PortfolioProject.dbo.CovidDeaths
WHERE location = 'South Africa'
AND continent is NOT NULL
ORDER BY 1, 2;


/* ======================================================= 

5. COUNTRIES WITH HIGHEST DEATH COUNT

======================================================= */

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PopulationPercentageInfected
FROM PortfolioProject.dbo.CovidDeaths
--WHERE location = 'South Africa'
--AND continent is NOT NULL
GROUP BY location, population
ORDER BY PopulationPercentageInfected DESC;


/* ======================================================= 

6. COUNTRIES WITH HIGHEST DEATH COUNT

======================================================= */

SELECT location, MAX(CAST(total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;


/* ======================================================= 

7. CONTINENTS WITH HIGHEST DEATH COUNT

======================================================= */

SELECT continent, MAX(CAST(total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;


/* ======================================================= 

8. GLOBAL NUMBERS

======================================================= */

SELECT SUM(new_cases) AS Total_Cases, SUM(CAST(new_deaths as int)) AS Total_Deaths, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1, 2;


/* ======================================================= 

9. TOTAL POPULATION vs VACCINATIONS (Rolling Total)
Window Function: SUM() OVER (PARTITION BY ...)

======================================================= */

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations )) OVER (Partition BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject.dbo.CovidDeaths dea
JOIN PortfolioProject.dbo.CovidVaccinations vac 
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2 ,3;


/* ======================================================= 

10. CTE: % POPULATION VACCINATED

======================================================= */

With PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations )) OVER (Partition BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject.dbo.CovidDeaths dea
JOIN PortfolioProject.dbo.CovidVaccinations vac 
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2 ,3
)
Select *, (RollingPeopleVaccinated/population)*100
FROM PopvsVac;


/* ======================================================= 

11. TEMP TABLE: % POPULATION VACCINATED

======================================================= */

DROP TABLE IF EXISTS #PercentPopulationVaccinated

CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar (255),
location nvarchar (255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
);

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations )) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject.dbo.CovidDeaths dea
JOIN PortfolioProject.dbo.CovidVaccinations vac 
	ON dea.location = vac.location
	AND dea.date = vac.date;
--WHERE dea.continent IS NOT NULL
--ORDER BY 2 ,3

SELECT *, (RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated;


/* ======================================================= 

12 VIEW: STORE DATA FOR VISUALISATIONS

======================================================= */

--If you re-run your script often, this prevents "already exists" errors

DROP VIEW IF EXISTS PortfolioProject.dbo.PercentPopulationVaccinated;

CREATE VIEW PortfolioProject.dbo.PercentPopulationVaccinated
AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations )) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject.dbo.CovidDeaths dea
JOIN PortfolioProject.dbo.CovidVaccinations vac 
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2 ,3

SELECT *
FROM PortfolioProject.dbo.PercentPopulationVaccinated;


/* ======================================================= 

13. KEY INSIGHTS

- Infection and death rates vary significantly across countries, indicating differences in healthcare systems and response strategies
- Countries with large populations show higher total cases but not necessarily higher infection percentages
- Vaccination rollout shows a consistent upward trend, reflecting global efforts to control the pandemic


======================================================= */

