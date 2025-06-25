import csv

input_file = r"E:\yakkit_calorie_tracker\assets\filtered_food_data.csv"
output_file = r"E:\yakkit_calorie_tracker\assets\filtered_food_data_clean2.csv"

with open(input_file, mode="r", encoding="utf-8", errors="replace") as fin, \
     open(output_file, mode="w", encoding="utf-8", newline="") as fout:

    # Varsayılan ayırıcı: virgül, tırnak işareti: çift tırnak
    reader = csv.reader(fin, delimiter=',', quotechar='"', skipinitialspace=True)
    # Çıktı dosyasını tüm alanları tırnak içine alarak yazıyoruz.
    writer = csv.writer(fout, delimiter=',', quotechar='"', quoting=csv.QUOTE_ALL)

    for row in reader:
        # Eğer satır boşsa atla
        if not row:
            continue

        # Beklenen kolon sayısı: 7 (ilk kolon ürün adı, son 6 kolon sayısal veri)
        if len(row) == 7:
            fixed_row = row
        elif len(row) > 7:
            # İlk kolondaki ürün adı, fazla bölünmüş; son 6 eleman sayısal alanlar
            numeric_fields = row[-6:]
            product_name = ",".join(row[:-6]).strip()
            fixed_row = [product_name] + numeric_fields
        else:
            # Beklenenden az kolon varsa, bu satırı atlayabilir veya loglayabilirsiniz.
            print("Beklenenden az kolon içeren satır atlanıyor:", row)
            continue

        writer.writerow(fixed_row)

print(f"Temizlenmiş dosya '{output_file}' olarak oluşturuldu.")
