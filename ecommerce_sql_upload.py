import pandas as pd
from sqlalchemy import create_engine
from time import time
import os
from dotenv import load_dotenv
from pathlib import Path

def create_in_postgres(user, password, host, port, database):

    # Creating Postgre SQL connection, passing user and password as arguments when running script
    engine = create_engine(f'postgresql://{user}:{password}@{host}:{port}/{database}')

    # Tables to create from each csv file
    tables = ['dim_customers','dim_products','fact_sales','state_region_mapping']

    # Go thru each of the csv files to create tables and populate in Postgres
    for table in tables:

        t_start = time()

        # Creating an iterator
        df_iter = pd.read_csv(f'.\Datasets\{table}.csv', iterator=True, chunksize=1000, encoding = 'latin-1')
        df = next(df_iter)

        # Getting only the columns (n=0) to create table and headers
        table_name = table
        # Formatting columns to show as lower case and with _ instead of spaces
        df.columns = [col.lower().replace(' ','_') for col in df.columns]
        df.head(0).to_sql(name=table_name, con=engine, if_exists='replace', index=False)
        df.to_sql(name=table_name, con=engine, if_exists='append', index=False)

        # While there is data, insert next chunk
        while True: 

            try:
                df = next(df_iter)
                df.columns = [col.lower().replace(' ','_') for col in df.columns]
                df.to_sql(name=table_name, con=engine, if_exists='append', index=False)
                
            except StopIteration:
                t_end = time()
                print(f'Table {table} created and all records inserted - %.2f seconds' % (t_end - t_start))
                break

if __name__ == '__main__':

    # Loading env variables
    load_dotenv(dotenv_path=Path('.\.env'))

    user = os.getenv('user')
    password = os.getenv('password')
    host = os.getenv('host')
    port = os.getenv('port')
    database = os.getenv('database')

    # Calling main function
    create_in_postgres(user, password, host, port, database)