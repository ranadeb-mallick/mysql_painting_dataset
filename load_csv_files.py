# import mysql.connector

# conn = mysql.connector.connect(host='localhost', user='root', password='****', database='paintings')
#
# if conn.is_connected():
#     print('Connection established ...', conn)

import pandas as pd
from sqlalchemy import create_engine

conn_string = 'mysql+pymysql://root:7318Root@localhost:3306/paintings'
engine = create_engine(conn_string)
connect = engine.connect()

csv_files = ['artist', 'canvas_size', 'image_link', 'museum', 'museum_hours', 'product_size', 'subject', 'work']

for file in csv_files:
    df = pd.read_csv(f"D:/SQL_project/painting_data/{file}.csv")
    df.to_sql(file, con=connect, if_exists='replace', index=False)


