import pyodbc

try:
    conn_str = (
        r'Driver={ODBC Driver 17 for SQL Server};'
        r'Server=DESKTOP-BAMBOR6;'
        r'Database=yakkitfooddb;'
        r'Trusted_Connection=yes;'
    )
    cnxn = pyodbc.connect(conn_str)
    cursor = cnxn.cursor()
    cursor.execute("SELECT 1")
    row = cursor.fetchone()
    if row:
        print("Veritabanı bağlantısı başarılı ve temel sorgu çalıştı.")
    else:
        print("Veritabanı bağlantısı başarılı ancak temel sorgu çalışmadı.")
    cnxn.close()
except Exception as e:
    print(f"Veritabanı bağlantı hatası: {e}")