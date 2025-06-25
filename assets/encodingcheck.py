
import pyodbc

try:
    conn = pyodbc.connect("DRIVER={SQL Server};SERVER=DESKTOP-BAMBOR6;DATABASE=yakkitfooddb;Trusted_Connection=yes;")
    print("Bağlantı başarılı!")
    conn.close()
except Exception as e:
    print("Bağlantı başarısız:", e)
