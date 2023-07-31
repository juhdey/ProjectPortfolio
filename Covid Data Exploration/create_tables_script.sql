USE covid_data;

CREATE TABLE IF NOT EXISTS covid_death_data
(iso_code VARCHAR(50), 
continent VARCHAR(50), 
location VARCHAR(50), 
date DATE, 
population DOUBLE, 
new_cases DOUBLE,
total_deaths DOUBLE, 
new_deaths DOUBLE,
total_cases_per_million DOUBLE,
new_cases_per_million DOUBLE, 
total_deaths_per_million DOUBLE, 
new_deaths_per_million DOUBLE,
reproduction_rate DOUBLE, 
icu_patients DOUBLE,
icu_patients_per_million DOUBLE, 
hosp_patients DOUBLE,
hosp_patients_per_million DOUBLE, 
weekly_icu_admissions DOUBLE,
weekly_icu_admissions_per_million DOUBLE, 
weekly_hosp_admissions DOUBLE,
weekly_hosp_admissions_per_million DOUBLE, 
total_tests DOUBLE, 
total_cases DOUBLE
)
