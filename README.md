# Nasdaq-100 Financial Analysis (2020-2024)

This project performs a comprehensive financial analysis on the Nasdaq-100 (NDX) companies, focusing on their annual income statements from 2020 to 2024. Through data collection, database integration, and SQL-based analysis, it explores the revenue, expenses, and profitability trends within the index. This project may be useful for data analysts, financial engineers, and investors looking to gain insights into the financial performance of major tech and non-tech companies in the Nasdaq-100.

## Table of Contents
- [Project Overview](#project-overview)
- [Data Collection](#data-collection)
- [Data Processing](#data-processing)
- [Database](#database)
- [Analysis](#analysis)
- [Technologies Used](#technologies-used)
- [Acknowledgments](#acknowledgments)

## Project Overview
This analysis project utilizes annual income statement data from 2020 to 2024 for Nasdaq-100 companies. It:
1. Scrapes a website to retrieve the current list of companies in the Nasdaq-100.
2. Collects income statement data via API calls to Financial Modeling Prep (FMP).
3. Stores the data in a MySQL database for structured querying.
4. Analyzes financial performance using SQL to uncover revenue, net income, expense ratios, and year-over-year trends.

## Data Collection
The initial data source is a web scraping process to get the Nasdaq-100 company tickers. This is followed by making API requests to Financial Modeling Prep’s Income Statement API to retrieve income statement data for each company from 2020 to 2024.

Data source API: [Financial Modeling Prep (FMP)](https://financialmodelingprep.com/)

## Data Processing
- The data obtained from the API is cleaned and transformed using **Pandas** to ensure compatibility with database storage.
- Each company’s income statement is processed and appended to a MySQL database.

## Database
The project uses MySQL to store the Nasdaq-100 financial data, enabling efficient querying for financial analysis.

Data pipeline:
1. **Pandas** and **SQLAlchemy** were used to structure and insert data into MySQL.
2. **MySQL** queries allow flexible analysis of key financial metrics over time.

## Analysis
Several key financial analyses are performed on the income statement data, including:
- **Revenue Growth**: Calculate year-over-year revenue changes to assess company growth rates.
- **Profit Margins**: Determine net income as a percentage of revenue.
- **Expense Ratios**: Evaluate the ratio of different expense categories to revenue.
- **Comparative Analysis**: Cross-company comparisons to identify leaders in terms of revenue growth and profitability within the Nasdaq-100.

## Technologies Used
- **Python** (Pandas, SQLAlchemy)
- **MySQL**
- **Web Scraping** (requests, BeautifulSoup)
- **Financial Modeling Prep API** for income statement data


## Acknowledgments
Data sourced via the [Financial Modeling Prep API](https://financialmodelingprep.com/), which provides a wide range of financial data for companies.



