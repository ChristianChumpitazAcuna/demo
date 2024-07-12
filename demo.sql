-- Total de casos confirmados:
SELECT
  SUM(cumulative_confirmed) AS total_cases_worldwide
FROM bigquery-public-data.covid19_open_data.covid19_open_data
WHERE date = "2020-04-15";

-- Zonas más afectadas:
SELECT
  COUNT(*) AS count_of_states
FROM bigquery-public-data.covid19_open_data.covid19_open_data
WHERE country_name = "United States of America"
  AND date = "2020-04-15"
  AND cumulative_deceased > 250;

-- Identificar puntos críticos:
SELECT
  COUNT(*) AS count_of_states
FROM (
    SELECT
      subregion1_name AS state,
      SUM(cumulative_deceased) AS death_count
    FROM bigquery-public-data.covid19_open_data.covid19_open_data
    WHERE country_name = "United States of America"
      AND date = '2020-04-10'
      AND subregion1_name IS NOT NULL
    GROUP BY subregion1_name
)
WHERE death_count > 1000;

-- Tasa de letalidad:
SELECT
  SUM(cumulative_confirmed) AS total_confirmed_cases,
  SUM(cumulative_deceased) AS total_deaths,
  (SUM(cumulative_deceased) / SUM(cumulative_confirmed)) * 100 AS case_fatality_ratio
FROM bigquery-public-data.covid19_open_data.covid19_open_data
WHERE country_name = "Italy"
AND date BETWEEN "2020-04-01" AND "2020-04-30";

-- Identificar día específico:
SELECT
  DATE(date) AS fecha_max_muertes
FROM bigquery-public-data.covid19_open_data.covid19_open_data
WHERE country_name = "Italy"
  AND cumulative_deceased = 8000
ORDER BY date
LIMIT 1;


-- Encontrar días con cero casos nuevos netos:
WITH india_cases_by_date AS (
  SELECT
    date,
    SUM(cumulative_confirmed) AS cases
  FROM
    bigquery-public-data.covid19_open_data.covid19_open_data
  WHERE
    country_name = "India"
    AND date BETWEEN '2020-02-23' AND '2020-03-12'
  GROUP BY
    date
  ORDER BY
    date ASC
),
india_previous_day_comparison AS (
  SELECT
    date,
    cases,
    LAG(cases) OVER(ORDER BY date) AS previous_day_cases,
    cases - LAG(cases) OVER(ORDER BY date) AS net_new_cases
  FROM
    india_cases_by_date
)
SELECT
  date,
  cases,
  previous_day_cases,
  net_new_cases
FROM
  india_previous_day_comparison;

-- Tasa de duplicación:

WITH us_cases_by_date AS (
    SELECT
      date,
      SUM(cumulative_confirmed) AS cases
    FROM
      bigquery-public-data.covid19_open_data.covid19_open_data
    WHERE
      country_code = "US"
      AND date BETWEEN '2020-03-22' AND '2020-04-20'
    GROUP BY
      date
    ORDER BY
      date ASC
  ),
  us_previous_day_comparison AS (
    SELECT
      date,
      cases AS Confirmed_Cases_On_Day,
      LAG(cases) OVER(ORDER BY date) AS Confirmed_Cases_Previous_Day,
      ((cases - LAG(cases) OVER(ORDER BY date)) / LAG(cases) OVER(ORDER BY date)) * 100 AS Percentage_Increase_In_Cases
    FROM
      us_cases_by_date
  )
  SELECT
    date AS Date,
    Confirmed_Cases_On_Day,
    Confirmed_Cases_Previous_Day,
    Percentage_Increase_In_Cases
  FROM
    us_previous_day_comparison
  WHERE
    Percentage_Increase_In_Cases > 20
  ORDER BY
    Date;

-- Tasa de recuperación:
SELECT
  country_name AS country,
  SUM(cumulative_recovered) AS recovered_cases,
  SUM(cumulative_confirmed) AS confirmed_cases,
  (SUM(cumulative_recovered) / SUM(cumulative_confirmed)) * 100 AS recovery_rate
FROM
  bigquery-public-data.covid19_open_data.covid19_open_data
WHERE
  date <= '2020-05-10'
GROUP BY
  country_name
HAVING
  SUM(cumulative_confirmed) > 50000
ORDER BY
  recovery_rate DESC
LIMIT 20;

-- CDGR - Tasa de crecimiento diario acumulada:
WITH france_cases AS (
    SELECT
        date,
        SUM(cumulative_confirmed) AS total_cases
    FROM
        bigquery-public-data.covid19_open_data.covid19_open_data
    WHERE
        country_name = 'France'
        AND date BETWEEN '2020-01-24' AND '2020-04-15'
    GROUP BY date
),
summary AS (
    SELECT
        total_cases AS first_day_cases,
        LEAD(total_cases) OVER(ORDER BY date) AS last_day_cases,
        DATE_DIFF(LEAD(date) OVER(ORDER BY date), date, DAY) AS days_diff
    FROM
        france_cases
    LIMIT 1
)
SELECT
    first_day_cases,
    last_day_cases,
    days_diff,
    POWER((last_day_cases / first_day_cases), (1 / days_diff)) - 1 AS cdgr
FROM
    summary;
