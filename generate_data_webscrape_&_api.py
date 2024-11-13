import pandas as pd                         #for data wrangling
import requests                             #for making http requests to target server
import yfinance as yf                       #for pulling financial information - income statement
from bs4 import BeautifulSoup as bs         #for parsing http response 
from sqlalchemy import create_engine,text   #for writing pandas dataframe to mysql database


url = 'https://www.slickcharts.com/nasdaq100'
headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36", 
    "Accept-Language": "en-US,en;q=0.9"
           }


page = requests.get(url, headers=headers)
print(f'{url} request status code: {page.status_code}')


soup = bs(page.content, 'html.parser')
print(soup.prettify())


table = soup.find('table', class_='table')
print(table.prettify())


symbols = table.find_all('tr')
print(symbols)


tickers =[symbol.get('id').split('-')[-1] for symbol in symbols if symbol.get('id') != None]
print('tickers', tickers, sep='\n')


df = pd.DataFrame(columns=[
    'date', 
    'symbol', 
    'reportedCurrency', 
    'cik', 
    'fillingDate', 
    'acceptedDate', 
    'calendarYear', 
    'period', 
    'revenue', 
    'costOfRevenue', 
    'grossProfit', 
    'grossProfitRatio', 
    'researchAndDevelopmentExpenses', 
    'generalAndAdministrativeExpenses', 
    'sellingAndMarketingExpenses', 
    'sellingGeneralAndAdministrativeExpenses', 
    'otherExpenses', 
    'operatingExpenses', 
    'costAndExpenses', 
    'interestIncome', 
    'interestExpense', 
    'depreciationAndAmortization', 
    'ebitda', 
    'ebitdaratio', 
    'operatingIncome', 
    'operatingIncomeRatio', 
    'totalOtherIncomeExpensesNet', 
    'incomeBeforeTax', 
    'incomeBeforeTaxRatio', 
    'incomeTaxExpense', 
    'netIncome', 
    'netIncomeRatio', 
    'eps', 
    'epsdiluted', 
    'weightedAverageShsOut', 
    'weightedAverageShsOutDil', 
    'link', 
    'finalLink'
    ])


for ticker in tickers:
    ticker_data = requests.get(f'https://financialmodelingprep.com/api/v3/income-statement/{ticker}?period=annual&apikey=Be113ypd6JJOcshmQDYfVpS1yJWqclkT')
    for ticker_data_year in ticker_data.json():
        print(ticker_data_year)
        df.loc[len(df)] = ticker_data_year


fx_usd_rate = {('USD', 1), ('EUR', 1.06365), ('CNY', 0.1381)}
fx_usd = pd.DataFrame(fx_usd_rate, columns=['reportedCurrency', 'rateUSD'])


df_2 = df.merge(fx_usd, on='reportedCurrency', how='left')

engine = create_engine('mysql+pymysql://root:1234@localhost:3307/ndx_comp')

create_table_query = """
    CREATE TABLE income_statement_ndx (
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
)
"""
try:
    with engine.connect() as connection:
        connection.execute(text(create_table_query))
        print('query successful')
except Exception as e:
    print(e)

df_2.to_sql('income_statement_ndx', con=engine, if_exists='append', index=False)

#Data provided by Financial Modeling Prep - https://financialmodelingprep.com/developer/docs/

