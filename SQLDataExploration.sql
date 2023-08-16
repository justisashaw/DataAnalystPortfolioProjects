SELECT *
  FROM [PortfolioProject].[dbo].[CovidDeaths$]
  Where continent is not null
  Order by 3, 4 

-- Ensure both data sets work (they do)

SELECT *
  FROM [PortfolioProject].[dbo].[CovidDeaths$]
  Order by 3, 4 

  SELECT *
  FROM [PortfolioProject].[dbo].[CovidVaccinations$]
  Order by 3, 4 

  -- Select Data that we are going to be using

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths$
order by 1, 2

-- Looking at Total Cases vs Total Deaths 
-- Rough estimate of chance of dying based on country (bad data).
Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths$
Where location like '%states%'
order by 1,2

-- Looking at Total Cases vs Population 
-- Shows what percentage of population got Covid

Select Location, date, total_cases, population, (total_cases/population)*100 as InfectionPercentage
From PortfolioProject..CovidDeaths$
Where location like '%states%'
order by 1,2

-- Looking at Countries with Highest Infection Rate compared to Population 

Select Location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as InfectionPercentage
From PortfolioProject..CovidDeaths$
--Where location like '%states%'
GROUP BY location, population
order by InfectionPercentage desc

-- Showing Countries with Highest Death Count per Population 

Select Location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths$
--Where location like '%states%'
Where continent is not null
GROUP BY Location
order by TotalDeathCount desc

-- Showing Continents with Highest Death Count per Population

Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths$
--Where location like '%states%'
Where continent is not null
GROUP BY continent
order by TotalDeathCount desc


-- Global Numbers 

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths$
--Where location like '%states%'
where continent is not null
--Group by date
order by 1,2

-- Beginning Vaccination Numbers 
-- Looking at Total Population vs Vaccinations

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as rollingvaccinations
From PortfolioProject..CovidVaccinations$ vac
Join PortfolioProject..CovidDeaths$ dea
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- Using CTE to aggregate data
-- Percentage of rolling vaccinated of population

With PopvsVac (Continent, Location, Date, Population, new_vaccinations, rollingvaccinations)
as 
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as rollingvaccinations
From PortfolioProject..CovidVaccinations$ vac
Join PortfolioProject..CovidDeaths$ dea
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)

Select *, (rollingvaccinations/Population)*100 as rollingvacpercent
From PopvsVac	

-- Creating a Temp Table 
-- Percentage of rolling vaccinated of population

Create Table #PercentPopulationVaccinated
(Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric, 
new_vaccinations numeric,
rollingvacpercent numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as rollingvaccinations
From PortfolioProject..CovidVaccinations$ vac
Join PortfolioProject..CovidDeaths$ dea
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
--order by 2,3

Select *, (rollingvacpercent/Population)*100
From #PercentPopulationVaccinated

-- Creating View to store data for later visualizations 

Create View PercentPopulationVaccinated as 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as rollingvaccinations
From PortfolioProject..CovidVaccinations$ vac
Join PortfolioProject..CovidDeaths$ dea
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
--order by 2,3

Select *
From PercentPopulationVaccinated