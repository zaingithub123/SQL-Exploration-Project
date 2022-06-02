select *
from project..CovidDeaths
where continent is not null


select Location, date, total_cases, new_cases, total_deaths
from project..CovidDeaths
order by 1,2

-- looking at total cases vs total deaths
-- shows the likelihood of dying if you contract covid in your country

select Location, date, total_cases,total_deaths, (total_deaths/total_cases) *100 as DeathPercentage
from project..CovidDeaths
WHERE Location like '%kingdom%'
order by 1,2

--looking at total cases vs population
--shows the percentage of people who got covid

select Location, date, Population, total_cases, (total_cases/population) * 100 as InfectionPercentage
from project..CovidDeaths
WHERE Location like '%kingdom%'
order by 1,2

--looking at countries with highest infection compared to population
-- we use max on total cases and population infected column to get the highest number.

select Location, Population, max(total_cases) as highestinfectioncount, max((total_cases/population)) * 100 as percentpopulationinfected
from project..CovidDeaths
where continent is not null 
group by location, Population
order by percentpopulationinfected desc -- descending order from highest to lowest

-- looking at the united kingdom highest infection rate 
-- uk had 6% of population infected with covid during its peak

select Location, Population, max(total_cases) as highestinfectioncount, max((total_cases/population)) * 100 as percentpopulationinfected
from project..CovidDeaths
where location = 'united kingdom'
group by location, Population


-- showing countries with the highest death count

select Location as Country, max(cast(total_deaths as int)) as totaldeaths -- casted the total deaths to an int because it was orignally nvarchar
from project..CovidDeaths
where continent is not null -- if not included, continents would also be included in country column
group by Location
order by totaldeaths desc

-- BREAKING IT DOWN INTO CONTINENT

-- showing continents with the highest death count

select continent, max(cast(total_deaths as int)) as totaldeaths
from project..CovidDeaths
where continent is not null 
group by continent
order by totaldeaths desc

--total of new cases and deaths per day with death percentage

select date, SUM(new_cases) as totalcases, SUM(cast(new_deaths as int)) as totaldeaths, SUM(cast(new_deaths as int))/sum(new_cases)*100 as deathpercent
from project..CovidDeaths
where continent is not null
group by date
order by 1,2

--total new cases and deaths ALTOGETHER

select SUM(new_cases) as totalcases, SUM(cast(new_deaths as int)) as totaldeaths, SUM(cast(new_deaths as int))/sum(new_cases)*100 as deathpercent
from project..CovidDeaths
where continent is not null
order by 1,2

-- death and vaccination tables joined

-- looking at total population vs vaccination with rolling number

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(cast(new_vaccinations as int)) OVER (PARTITION BY dea.location order by dea.date) as rollingepeoplevaccinated -- partition by to break down the location, needs to be ordered by date
from project..CovidDeaths as dea
join project..CovidVaccinations as vac
on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- i want to also add percentage of rolling people vaccinated
-- if i add rollingpeoplevaccinated/population * 100 it will give an error
-- because it is an invalid column name
--CTE/temp table can fix this problem

--CTE

With populationvsvaccination (continent, location, date, population, new_vaccinations, rollingpeoplevaccinated)
as (
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(cast(new_vaccinations as int)) OVER (PARTITION BY dea.location order by dea.date) as rollingepeoplevaccinated -- partition by to break down the location, needs to be ordered by date
from project..CovidDeaths as dea
join project..CovidVaccinations as vac
on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
select *, (rollingpeoplevaccinated/population)*100 as percentagepopulationvaccinated
from populationvsvaccination


--temp table alterative solution
drop table if exists #percentpopulationvaccinated -- no error if i have to constantly edit this table
create table #percentpopulationvaccinated
(continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rollingpeoplevaccinated numeric)

insert into  #percentpopulationvaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(cast(new_vaccinations as int)) OVER (PARTITION BY dea.location order by dea.date) as rollingepeoplevaccinated -- partition by to break down the location, needs to be ordered by date
from project..CovidDeaths as dea
join project..CovidVaccinations as vac
on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
order by 2

select *, (rollingpeoplevaccinated/population)*100 as percentagepopulationvaccinated
from #percentpopulationvaccinated

--creating a view for visualizations

create view percentpopulationvaccinated as 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(cast(new_vaccinations as int)) OVER (PARTITION BY dea.location order by dea.date) as rollingepeoplevaccinated -- partition by to break down the location, needs to be ordered by date
from project..CovidDeaths as dea
join project..CovidVaccinations as vac
on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
--order by 2

CREATE VIEW highestcontinentdeaths as
select continent, max(cast(total_deaths as int)) as totaldeaths
from project..CovidDeaths
where continent is not null 
group by continent
--order by totaldeaths desc






