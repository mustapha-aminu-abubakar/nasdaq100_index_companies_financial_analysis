-- Active: 1727863492809@@127.0.0.1@3307@ndx_comp
USE ndx_comp;


CREATE TABLE income_statement (
    `date` DATE,
    symbol VARCHAR(10),
    reportedCurrency VARCHAR(10),
    cik VARCHAR(20),
    fillingDate DATE,
    acceptedDate DATETIME,
    calendarYear YEAR,
    `period` VARCHAR(5),
    revenue BIGINT,
    costOfRevenue BIGINT,
    grossProfit BIGINT,
    grossProfitRatio FLOAT(3,2),
    researchAndDevelopmentExpenses BIGINT,
    generalAndAdministrativeExpenses BIGINT,
    sellingAndMarketingExpenses BIGINT,
    sellingGeneralAndAdministrativeExpenses BIGINT,
    otherExpenses BIGINT,
    operatingExpenses BIGINT,
    costAndExpenses BIGINT,
    interestIncome BIGINT,
    interestExpense BIGINT,
    depreciationAndAmortization BIGINT,
    ebitda BIGINT,
    ebitdaratio FLOAT(3,2),
    operatingIncome BIGINT,
    operatingIncomeRatio FLOAT(3,2),
    totalOtherIncomeExpensesNet BIGINT,
    incomeBeforeTax BIGINT,
    incomeBeforeTaxRatio FLOAT(3,2),
    incomeTaxExpense BIGINT,
    netIncome BIGINT,
    netIncomeRatio FLOAT(3,2),
    eps FLOAT(10,2),
    epsdiluted FLOAT(10,2),
    weightedAverageShsOut BIGINT,
    weightedAverageShsOutDil BIGINT,
    `link` VARCHAR(150),
    finalLink VARCHAR(150),
    rateUSD FLOAT(10,5)
);

--Which companies in the NDX100 have the highest and lowest netIncome over the latest period?
SELECT 
    symbol,
    YEAR(fillingDate) AS year,
    netIncome,
    reportedCurrency,
    rateUSD,
    ROUND(`netIncome` * `rateUSD`,0) as `netIncomeUsd`,
    DENSE_RANK() OVER(ORDER BY `netIncomeUsd` DESC) as `netIncomeUsdRank`
FROM income_statement
WHERE YEAR(fillingDate) = 2024
ORDER BY 7 ASC
LIMIT 5
;

--How does the revenue growth rate vary across companies in the NDX100?
WITH revenue_by_symbol AS (
SELECT 
    symbol,
    YEAR(`fillingDate`) as filling_year,
    SUM(revenue) * `rateUSD` as revenue_cur_year
FROM income_statement
GROUP BY symbol, YEAR(`fillingDate`)
ORDER BY 1 ASC, 2 ASC
), revenue_change_by_symbol AS (
    SELECT
        *,
        LAG(revenue_cur_year, 1) OVER(PARTITION BY symbol ORDER BY symbol ASC, filling_year ASC) as revenue_prev_year
    FROM revenue_by_symbol
), revenue_per_change_by_symbol AS ( 
    SELECT 
        *,
        revenue_cur_year - revenue_prev_year as revenue_change,
        ROUND((revenue_cur_year - revenue_prev_year) / revenue_prev_year * 100, 1) as `% change`
    FROM revenue_change_by_symbol
)
SELECT * FROM 
(
    SELECT 
        *,
        ROUND(AVG(`% change`) OVER(PARTITION BY symbol), 1) as `avg annual % change`
    FROM revenue_per_change_by_symbol
) as revenue_per_change_by_symbol_agg
ORDER BY 7 DESC, symbol, filling_year ASC
;


--Which NDX100 companies have the highest grossProfitRatio, and how has this ratio trended over time?
WITH gross_profit_ratio AS(
SELECT 
    symbol,
    YEAR(fillingDate) as filling_year,
    grossProfitRatio,
    LAG(grossProfitRatio) OVER(PARTITION BY symbol ORDER BY YEAR(`fillingDate`)) as gross_profit_ratio_lagging,
    ROUND(AVG(`grossProfitRatio`) OVER(PARTITION BY symbol), 2) as avg_gross_profit_ratio
FROM income_statement
)
SELECT 
    symbol,
    filling_year,
    grossProfitRatio,
    gross_profit_ratio_lagging,
    ROUND((grossProfitRatio - gross_profit_ratio_lagging) / gross_profit_ratio_lagging * 100, 1) as `gross_profit_ratio_annual_%_change`,
    avg_gross_profit_ratio
FROM gross_profit_ratio
ORDER BY 6 DESC, 1, 2 ASC;


--How much do NDX100 companies spend on researchAndDevelopmentExpenses, 
--and how does this compare to their revenue?

WITH RD_and_rev_by_symbol AS (
    SELECT 
        symbol,
        SUM(researchAndDevelopmentExpenses) * `rateUSD` as total_RD_expenses,
        SUM(revenue) * `rateUSD` as total_revenue,
        AVG(researchAndDevelopmentExpenses) OVER() * `rateUSD` as avg_RD_expenses,
        AVG(revenue) OVER() * `rateUSD` as avg_revenue
    FROM income_statement
    GROUP BY symbol
), RD_rev_correlation AS (
    SELECT
        symbol,
        CASE 
            WHEN total_RD_expenses > avg_RD_expenses THEN  'greater'
            ELSE  'less'
        END as `> avg R&D expenses`,
        CASE 
            WHEN total_revenue > avg_revenue THEN  'greater'
            ELSE  'less'
        END as `> avg revenue`
    FROM RD_and_rev_by_symbol
)
SELECT 
    `> avg R&D expenses`,
    `> avg revenue`,
    ROUND(COUNT(symbol) / (SELECT COUNT(symbol) FROM RD_and_rev_by_symbol) * 100, 1) as `% companies`
FROM RD_rev_correlation
GROUP BY 1,2
;

--Which companies have the highest sellingGeneralAndAdministrativeExpenses 
--as a percentage of their total expenses?

SELECT 
    *,
    ROUND(admin_expenses / total_expenses * 100, 1) as `admin % total expenses`
FROM(
    SELECT 
        symbol,
        SUM(`sellingGeneralAndAdministrativeExpenses`) OVER(PARTITION BY symbol)* `rateUSD` as admin_expenses,
        SUM(`costAndExpenses`) OVER(PARTITION BY symbol)* `rateUSD` as total_expenses
    FROM income_statement
    GROUP BY symbol
) as expenses_by_symbol
ORDER BY 4 DESC
;

--What is the eps and epsdiluted trend for each NDX100 company over recent years?
WITH eps_by_symbol as (
    SELECT 
        symbol,
        YEAR(`date`) as year,
        eps * `rateUSD` as epsUSD,
        LAG(eps) OVER(PARTITION BY symbol ORDER BY YEAR(`date`) ASC) * `rateUSD` as epsUSD_lag,
        epsdiluted * `rateUSD` as epsdilutedUSD,
        LAG(epsdiluted) OVER(PARTITION BY symbol ORDER BY YEAR(`date`) ASC) * `rateUSD` as epsdilutedUSD_lag
    FROM income_statement
    GROUP BY symbol, YEAR(`date`)
)
SELECT 
    symbol,
    `year`,
    epsUSD,
    ROUND((epsUSD - epsUSD_lag) / epsUSD_lag * 100, 1) as `% eps change`,
    epsdilutedUSD,
    ROUND((epsdilutedUSD - epsdilutedUSD_lag) / epsdilutedUSD_lag * 100, 1) as `% epsdiluted change`
FROM eps_by_symbol
ORDER BY symbol ASC, `year` ASC
;

--Which companies have shown consistent growth in eps, indicating positive market sentiment?
WITH eps_by_symbol as (
SELECT 
    symbol,
    YEAR(`date`) as year,
    eps * `rateUSD` as epsUSD,
    LAG(eps) OVER(PARTITION BY symbol ORDER BY YEAR(`date`) ASC) * `rateUSD` epsUSD_lag
FROM income_statement
GROUP BY symbol, YEAR(`date`)
), eps_change_by_symbol AS(
SELECT 
    symbol,
    `year`,
    epsUSD,
    ROUND((epsUSD - epsUSD_lag) / epsUSD_lag * 100, 1) as `% epsUSD change`
FROM eps_by_symbol
-- ORDER BY symbol ASC, `year` ASC
)
SELECT 
    symbol,
    SUM(CASE 
        WHEN ISNULL(`% epsUSD change`) THEN 1 
        WHEN `% epsUSD change` > 0 THEN 1 
        ELSE 0 
    END) as pos_eps_change
FROM eps_change_by_symbol
GROUP BY symbol
HAVING pos_eps_change = 5
;

--How does incomeTaxExpense vary across NDX100 companies, 
--and which companies pay the highest taxes relative to incomeBeforeTax?
SELECT 
    *,
    ROUND(income_tax_expense /  income_before_tax * 100, 1) as `tax % income`
FROM(
SELECT 
    symbol,
    YEAR(`date`) as year,
    SUM(`incomeTaxExpense`)  * `rateUSD` as income_tax_expense,
    SUM(`incomeBeforeTax`)  * `rateUSD` as income_before_tax
FROM income_statement
GROUP BY symbol, YEAR(date)
) as income_and_tax
;


--Which companies have the highest interestIncome and interestExpense, 
--and how does this impact their net profitability?
WITH interest_stats_by_symbol AS(
SELECT 
    symbol,
    SUM(`interestIncome`) * `rateUSD` as total_interest_income,
    SUM(`interestExpense`) * `rateUSD` as total_interest_expense,
    SUM(`netIncome`) * `rateUSD` as total_income
FROM income_statement
GROUP BY symbol
)
SELECT 
    symbol,
    total_interest_income,
    total_interest_expense,
    total_interest_income - total_interest_expense as net_interest_income,
    total_income,
    ROUND((total_interest_income - total_interest_expense) / total_income * 100, 1) as `net_interest_income % net_income`
FROM interest_stats_by_symbol
ORDER BY 6 DESC

--What is the trend in weightedAverageShsOutDil over time for each company, 
--and how does share dilution affect eps?
WITH eps_diluted AS(
SELECT 
    symbol,
    YEAR(`date`) as year,
    weightedAverageShsOutDil as wasod,
    LAG(`weightedAverageShsOutDil`) OVER(PARTITION BY symbol ORDER BY YEAR(`date`)) as wasod_lag,
    eps  * `rateUSD` as epsUSD,
    LAG(`eps`) OVER(PARTITION BY symbol ORDER BY YEAR(`date`)) * `rateUSD` as epsUSD_lag
FROM income_statement
GROUP BY symbol, YEAR(date)
)
SELECT 
    symbol,
    year,
    wasod,
    epsUSD,
    (wasod - wasod_lag) / wasod_lag * 100,
    (epsUSD - epsUSD_lag) / epsUSD_lag * 100
FROM eps_diluted;

--What is the distribution of costOfRevenue across companies in the NDX100? 
--Which companies operate with the highest gross margin?

WITH summary AS(
    SELECT 
        symbol,
        SUM(`costOfRevenue`) * `rateUSD` as total_cost_of_rev,
        SUM(`grossProfit`) * `rateUSD` as total_gross_profit,
        SUM(revenue) * `rateUSD` as total_revenue
    FROM income_statement
    GROUP BY symbol
)
SELECT 
    symbol,
    total_gross_profit,
    total_revenue,
    (total_gross_profit / total_revenue) * 100 as `gross_profit % revenue`
FROM summary
ORDER BY 4 DESC
;


--How do operatingExpenses as a percentage of revenue vary across different sectors within the NDX100?
WITH operating_expenses_by_symbol AS(
SELECT 
    symbol,
    YEAR(date) as year,
    SUM(`operatingExpenses`) * `rateUSD` as total_operating_expenses,
    SUM(revenue) * `rateUSD` as total_revenue
FROM income_statement
GROUP BY symbol, YEAR(date)
), operating_expence_per_rev AS (
    SELECT 
        symbol,
        year,
        ROUND((total_operating_expenses / total_revenue) * 100, 1) as operating_expenses_over_rev
    FROM operating_expenses_by_symbol
)
SELECT 
    symbol,
    ROUND(AVG(operating_expenses_over_rev), 1) as `average annual operating expense % revenue`
FROM operating_expence_per_rev
GROUP BY symbol
ORDER BY 2 DESC;