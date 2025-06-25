import pandas as pd
import pyodbc

# Modelinizin tanıdığı 102 sınıf etiketleri listesi
recognized_classes = [
    "apple_pie", "baby_back_ribs", "baklava", "beef_carpaccio", "beef_tartare",
    "beet_salad", "beignets", "bibimbap", "bread_augmented", "bread_pudding",
    "breakfast_burrito", "bruschetta", "caesar_salad", "cannoli", "caprese_salad",
    "carrot_cake", "ceviche", "cheese_plate", "cheesecake", "chicken_curry",
    "chicken_quesadilla", "chicken_wings", "chocolate_cake", "chocolate_mousse",
    "churros", "clam_chowder", "club_sandwich", "crab_cakes", "creme_brulee",
    "croque_madame", "cup_cakes", "deviled_eggs", "donuts", "dumplings", "edamame",
    "eggs_benedict", "escargots", "falafel", "filet_mignon", "fish_and_chips",
    "foie_gras", "french_fries", "french_onion_soup", "french_toast",
    "fried_calamari", "fried_rice", "frozen_yogurt", "garlic_bread", "gnocchi",
    "greek_salad", "grilled_cheese_sandwich", "grilled_salmon", "guacamole",
    "gyoza", "hamburger", "hot_and_sour_soup", "hot_dog", "huevos_rancheros",
    "hummus", "ice_cream", "lasagna", "lobster_bisque", "lobster_roll_sandwich",
    "macaroni_and_cheese", "macarons", "miso_soup", "mussels", "nachos", "omelette",
    "onion_rings", "oysters", "pad_thai", "paella", "pancakes", "panna_cotta",
    "peking_duck", "pho", "pizza", "pork_chop", "poutine", "prime_rib",
    "pulled_pork_sandwich", "ramen", "ravioli", "red_velvet_cake", "risotto",
    "samosa", "sashimi", "scallops", "seaweed_salad", "shrimp_and_grits",
    "spaghetti_bolognese", "spaghetti_carbonara", "spring_rolls", "steak",
    "strawberry_shortcake", "sushi", "tacos", "takoyaki", "tiramisu",
    "tuna_tartare", "waffles"
]

# Basit anahtar kelime eşlemesi: ürün isminde aranan sınıf etiketinin geçip geçmediğine bakıyoruz.
def get_class_label(product_name):
    product_name_lower = product_name.lower()
    # Ürün isminde bulunan tüm eşleşmeleri listele
    matches = [label for label in recognized_classes if label in product_name_lower]
    # Eğer yalnızca 1 eşleşme varsa, o sınıfı döndür
    if len(matches) == 1:
        return matches[0]
    # Birden fazla veya hiç eşleşme varsa None döndür
    return None

# CSV'den veri okuma (önceden eklediğiniz FoodData'nın orijinal verilerini içerdiğini varsayıyoruz)
df = pd.read_csv(r"E:\yakkit_calorie_tracker\assets\filtered_food_data_clean2.csv")

# Her kayıt için get_class_label ile sınıf etiketini belirle
df["class_label"] = df["product_name"].apply(get_class_label)

# SQL Server bağlantısı
conn = pyodbc.connect(
    "DRIVER={SQL Server};"
    "SERVER=DESKTOP-BAMBOR6;"  # SQL Server adresiniz
    "DATABASE=yakkitfooddb;"
    "Trusted_Connection=yes;"
)
cursor = conn.cursor()

# 1'e 1 eşleşme sağlamak için; her tanınan sınıf etiketini yalnızca bir kez güncelliyoruz.
# updated_labels sözlüğü, hangi sınıf etiketine karşılık hangi ürünün güncellendiğini saklar.
updated_labels = {}

for index, row in df.iterrows():
    label = row["class_label"]
    # Eğer sınıf etiketimiz belirlendiyse ve henüz bu sınıfa ait bir kayıt güncellenmediyse
    if label is not None and label not in updated_labels:
        # Not: Eğer tabloda benzersiz kayıtları belirleyecek bir primary key varsa, onu kullanmak daha doğru olur.
        cursor.execute("""
            UPDATE FoodData
            SET class_label = ?
            WHERE product_name = ?""",
            label, row["product_name"]
        )
        updated_labels[label] = row["product_name"]

conn.commit()
cursor.close()
conn.close()

print("Her tanınan sınıftan yalnızca bir kayıt güncellendi. Güncellenen etiketler:", updated_labels)
