import pandas as pd
import pyodbc

# CSV dosyasını oku
df = pd.read_csv(r"E:\yakkit_calorie_tracker\assets\filtered_food_data_clean2.csv")
# Maksimum 255 karakter olacak şekilde kesme işlemi
df['product_name'] = df['product_name'].apply(lambda x: x[:255])

# SQL Server bağlantısı
conn = pyodbc.connect(
    "DRIVER={SQL Server};"
    "SERVER=DESKTOP-BAMBOR6;"  # SQL Server adresin
    "DATABASE=yakkitfooddb;"
    "Trusted_Connection=yes;"
)

cursor = conn.cursor()

# Verileri tabloya ekle
for index, row in df.iterrows():
    cursor.execute("""
        INSERT INTO FoodData (product_name, energy_kcal_100g, carbohydrates_100g, proteins_100g, fat_100g, fiber_100g, sugars_100g)
        VALUES (?, ?, ?, ?, ?, ?, ?)""",
        row["product_name"], row["energy-kcal_100g"], row["carbohydrates_100g"],
        row["proteins_100g"], row["fat_100g"], row["fiber_100g"], row["sugars_100g"]
    )

conn.commit()
cursor.close()
conn.close()
