/*
Data exploration using the most recent data from https://ourworldindata.org/covid-deaths

Skills used: CTE's, Temp Tables, Joins, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

Select *
from [Portfolio project_Covid].dbo.CovidDeaths
where continent is not NULL
order by 3,4

--Select *
--from [Portfolio project_Covid]..CovidVaccinations
--order by 3,4

Select location, date, total_cases, new_cases, total_deaths, population
from CovidDeaths order by 1,2


--Total cases against total deaths
--This shows the likelihood of dying if you contract covid in your country, largely calculated on a daily basis

Select location, date = convert(date, date), total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
from CovidDeaths 
Where location in ('Nigeria', 'United States')
order by 1,2


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date = convert(date, date), total_cases, population, Round((total_cases/population)*100,2) AS CasePercentage
from CovidDeaths 
--Where location in ('Nigeria')
order by location, CasePercentage desc


--This compares countries with highest infection rate to its population

Select Location, max(total_cases) as TotalCases, population, Round((Max(total_cases)/population)*100,2) AS CasePercentage
from CovidDeaths 
--Where location in ('Nigeria', 'United States')
group by location, population
order by CasePercentage desc


--This lists the countries with hightest deaths per population

Select Location, total_cases, max(convert(int,total_deaths)) as TotalDeaths, Round((Max(Convert(int,total_deaths))/total_cases)*100,2) AS PercentageDeath
from CovidDeaths 
--Where location in ('Nigeria', 'United States')
group by location, total_cases
order by PercentageDeath desc

Select Location, max(cast(total_deaths as int)) as TotalDeaths
from CovidDeaths 
--Where location in ('Nigeria', 'United States')
where continent is not NULL
group by location
order by TotalDeaths desc

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--The below gives a 'continent' perspective of the Covid data

Select continent, max(cast(total_deaths as int)) as TotalDeaths
from CovidDeaths 
--Where location in ('Nigeria', 'United States')
where continent is not NULL
group by continent
order by TotalDeaths desc

Select date = EOMONTH(date), sum(cast(new_cases as int)) as TotalCases, sum(cast(new_deaths as int)) as TotalDeaths, sum(cast(new_deaths as int))/sum(cast(new_cases as int)) as PercentageDeaths
from CovidDeaths
where continent is not NULL
group by EOMONTH(date)
order by date

Select sum(cast(new_cases as int)) as TotalCases, sum(cast(new_deaths as int)) as TotalDeaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as PercentageDeaths
from CovidDeaths
where continent is not NULL
--group by EOMONTH(date)
--order by date

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from CovidDeaths dea join CovidVaccinations vac on dea.date = vac.date and dea.location = vac.location
--where dea.continent is not NULL
where dea.continent is not NULL and dea.location = 'Nigeria'
Order by 2,3

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Use of CTE

With PopVsVac (Continent, Location, Date, population, New_vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, sum(convert(int,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from CovidDeaths dea join CovidVaccinations vac on dea.date = vac.date and dea.location = vac.location
where dea.continent is not NULL
--Order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
from PopVsVac


--Temporary table

Drop table if exists #PercentPopulationVaccinated
Create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric,
)
Insert into #PercentPopulationVaccinated

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, sum(convert(int,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from CovidDeaths dea join CovidVaccinations vac on dea.date = vac.date and dea.location = vac.location
--where dea.continent is not NULL
--Order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
from #PercentPopulationVaccinated

Create view ContinentalDeaths as
Select continent, max(cast(total_deaths as int)) as TotalDeaths
from CovidDeaths 
--Where location in ('Nigeria', 'United States')
where continent is not NULL
group by continent
--order by TotalDeaths desc

Select *
from ContinentalDeaths