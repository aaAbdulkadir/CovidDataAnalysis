-- 2 tables
SELECT *
FROM [Covid Project].dbo.['COVID-DEATHS$']
ORDER BY 3,4

SELECT *
FROM [Covid Project].dbo.['COVID-VACCINATIONS$']
ORDER BY 3,4

-- Data to be used, Table 1: Deaths
SELECT location, date, total_cases, new_cases, total_deaths, new_deaths, population
FROM [Covid Project].dbo.['COVID-DEATHS$']
ORDER BY 1, 2

-- percentage of total deaths per total cases in the uk
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases * 100) AS DeathsPerCase
FROM [Covid Project].dbo.['COVID-DEATHS$']
WHERE location = 'United Kingdom'
ORDER BY 1, 2

-- percentage of total cases per population in uk: shows the number of the population that has had covid
SELECT location, date, (total_cases/population * 100) AS TotalCasesPerPopulationPercentage
FROM [Covid Project].dbo.['COVID-DEATHS$']
WHERE location = 'United Kingdom'
ORDER BY 2

-- total cases and total deaths for each country up to date
SELECT location, SUM(total_cases) AS TotalCases, SUM(CAST(total_deaths as int)) AS TotalDeaths, ROUND((SUM(CAST(total_deaths as int))/SUM(total_cases))*100, 2) AS DeathPercentage
FROM [Covid Project].dbo.['COVID-DEATHS$']
WHERE continent IS NOT NULL -- gets rid of the continents and limits to countries
GROUP BY location
HAVING SUM(total_cases) > 0 AND  SUM(CAST(total_deaths as int)) > 0 -- gets rid of NULL
ORDER BY 3 DESC

-- country with the highest infection rate compared to population. This is the total cases measured up to date vs the population
SELECT location, MAX(total_cases) as MaximumCases, population, (MAX(total_cases)/population)*100 AS InfectionRate
FROM [Covid Project].dbo.['COVID-DEATHS$']
WHERE continent IS NOT NULL -- gets rid of the continents and limits to countries
GROUP BY location, population
HAVING SUM(total_cases) > 0 AND  SUM(CAST(total_deaths as int)) > 0 -- gets rid of NULL
ORDER BY 4 DESC

-- how many people have died up to date
SELECT location, MAX(CAST(total_deaths AS int)) as TotalDeathsUpToDate, population, (MAX(CAST(total_deaths AS int))/population)*100 AS TotalDeathPerPopulation
FROM [Covid Project].dbo.['COVID-DEATHS$']
WHERE continent IS NOT NULL -- gets rid of the continents and limits to countries
GROUP BY location, population
HAVING SUM(total_cases) > 0 AND  SUM(CAST(total_deaths as int)) > 0 -- gets rid of NULL
ORDER BY 2 DESC

-- Continental total death count
SELECT location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM [Covid Project].dbo.['COVID-DEATHS$']
WHERE continent IS NULL AND location NOT LIKE '%income%' AND location NOT LIKE '%European%' AND location NOT LIKE '%International%' AND location NOT LIKE '%World%'
GROUP BY location
ORDER BY 2 DESC

-- New cases and new deaths across the world vs day. Death percentage for that day
SELECT date, SUM(new_cases) AS TotalNewCases, SUM(CAST(new_deaths AS int)) AS TotalNewDeaths, (SUM(CAST(new_deaths AS int))/SUM(new_cases))*100 AS DeathPercentagePerInfected
FROM [Covid Project].dbo.['COVID-DEATHS$']
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2

-- World Total Cases And Death Cases
SELECT SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths AS int)) AS TotalDeaths, (SUM(CAST(new_deaths AS int))/SUM(new_cases))*100 AS DeathPercentage
FROM [Covid Project].dbo.['COVID-DEATHS$']
WHERE continent IS NOT NULL

-- Data to be used, Table 2: Vaccinations
SELECT * 
FROM [dbo].['COVID-VACCINATIONS$']
ORDER BY location, date

-- Joining (Full) Table 1 and Table 2:
SELECT *
FROM [Covid Project].dbo.['COVID-DEATHS$'] Deaths
JOIN [dbo].['COVID-VACCINATIONS$'] Vaccinations ON Deaths.location = Vaccinations.location AND Deaths.date = Vaccinations.date

-- Total population vs new_vaccinations
SELECT Deaths.continent, Deaths.location, Deaths.date, Deaths.population, Vaccinations.new_vaccinations
FROM [Covid Project].dbo.['COVID-DEATHS$'] Deaths
JOIN [dbo].['COVID-VACCINATIONS$'] Vaccinations ON Deaths.location = Vaccinations.location AND Deaths.date = Vaccinations.date
WHERE Deaths.continent IS NOT NULL
ORDER BY 2,3

-- add partition with a rolling count of the new vaccines i.e. add vaccines for each location 
SELECT Deaths.continent, Deaths.location, Deaths.date, Deaths.population, Vaccinations.new_vaccinations, SUM(CAST(Vaccinations.new_vaccinations AS bigint)) OVER (PARTITION BY Deaths.location ORDER BY Deaths.location, Deaths.date) AS RollingTotalVaccination
FROM [Covid Project].dbo.['COVID-DEATHS$'] Deaths
JOIN [dbo].['COVID-VACCINATIONS$'] Vaccinations ON Deaths.location = Vaccinations.location AND Deaths.date = Vaccinations.date
WHERE Deaths.continent IS NOT NULL
ORDER BY 2,3

-- use CTE to make rolling count a column to find percentage of people vaccinated
With PopulationVsVaccinations (Continent, Location, Date, Population, New_Vaccinations, RollingTotalVaccination)
AS 
(
	SELECT Deaths.continent, Deaths.location, Deaths.date, Deaths.population, Vaccinations.new_vaccinations, SUM(CAST(Vaccinations.new_vaccinations AS bigint)) OVER (PARTITION BY Deaths.location ORDER BY Deaths.location, Deaths.date) AS RollingTotalVaccination
	FROM [Covid Project].dbo.['COVID-DEATHS$'] Deaths
	JOIN [dbo].['COVID-VACCINATIONS$'] Vaccinations ON Deaths.location = Vaccinations.location AND Deaths.date = Vaccinations.date
	WHERE Deaths.continent IS NOT NULL
	--ORDER BY 2,3
)
SELECT *, (RollingTotalVaccination/Population)*100 AS VaccinationPercentage
FROM PopulationVsVaccinations
WHERE location = 'United Kingdom'
ORDER BY 2,3

-- vaccination percentages
SELECT Deaths.location, Deaths.population, MAX(Vaccinations.total_vaccinations) AS TotalVaccinations, ROUND((MAX(Vaccinations.total_vaccinations)/Deaths.population)*100, 2) AS VaccinationPercentage
FROM [Covid Project].dbo.['COVID-DEATHS$'] Deaths
JOIN [dbo].['COVID-VACCINATIONS$'] Vaccinations ON Deaths.location = Vaccinations.location AND Deaths.date = Vaccinations.date
WHERE Deaths.continent IS NOT NULL
GROUP BY Deaths.location, Deaths.population
ORDER BY 4 DESC
