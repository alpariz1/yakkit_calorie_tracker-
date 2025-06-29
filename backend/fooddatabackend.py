from fastapi import FastAPI, Depends, HTTPException, status, Security,Path,Query, Body, UploadFile, File,Request
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from pydantic import BaseModel, EmailStr
from datetime import datetime, timedelta, date
from typing import Optional, List
import jwt
from passlib.context import CryptContext
import base64
import uuid, shutil, os
import numpy as np
from tensorflow.keras.preprocessing.image import load_img, img_to_array
from fastapi import Query, File, UploadFile
import tempfile
import os
import httpx
import uuid
import shutil
import numpy as np
from tensorflow.keras.preprocessing.image import load_img, img_to_array
from fastapi import Query, File, UploadFile, Depends
from sqlalchemy.orm import Session
# SQLAlchemy modülleri importları zaten mevcut
from sqlalchemy import create_engine, Column, Integer, String, Float, Date, or_, LargeBinary, Table, ForeignKey, UniqueConstraint, DateTime
from sqlalchemy.orm import declarative_base, sessionmaker, Session, relationship, joinedload

# ------------------ CONFIG & DATABASE ------------------

SECRET_KEY = "your_secret_key_here"  
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60
REFRESH_TOKEN_EXPIRE_DAYS    = 7
# SQL Server bağlantı dizesi - charset=utf8 parametresi eklendi
# Karakter kodlama sorunları devam ederse, SQL Server veritabanınızın ve
# ilgili kolonların (meal_name) collation ayarlarını kontrol et).
DATABASE_URL = "mssql+pyodbc://DESKTOP-BAMBOR6/yakkitfooddb?driver=ODBC+Driver+17+for+SQL+Server&trusted_connection=yes&charset=utf8"

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Kullanıcılar arasındaki arkadaşlıkları tutacak ara tablo
friends_association = Table(
    "friends",
    Base.metadata,
    Column("user_id", Integer, ForeignKey("users.id"), primary_key=True),
    Column("friend_id", Integer, ForeignKey("users.id"), primary_key=True),
    UniqueConstraint("user_id", "friend_id", name="uq_user_friend")
)

# ------------------ VERİTABANI MODELLERİ ------------------

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    username = Column(String(255), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    height = Column(Float, nullable=False)  # Boy (cm)
    weight = Column(Float, nullable=False)  # Kilo (kg)
    goal = Column(String(50), nullable=False)   # "kilo vermek" veya "kas yapmak"
    birth_date = Column(Date, nullable=False)
    daily_calories = Column(Float, nullable=False)  # Hesaplanmış günlük kalori ihtiyacı
    profile_image = Column(LargeBinary, nullable=True)

    friends = relationship(
        "User",
        secondary=friends_association,
        primaryjoin=id == friends_association.c.user_id,
        secondaryjoin=id == friends_association.c.friend_id,
        backref="befriended_by"
    )

class FriendRequest(Base):
    __tablename__ = "friend_requests"
    id = Column(Integer, primary_key=True, index=True)
    from_user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    to_user_id   = Column(Integer, ForeignKey("users.id"), nullable=False)
    status       = Column(String(20), default="pending", nullable=False)  # pending/accepted/rejected
    created_at   = Column(DateTime, default=datetime.utcnow, nullable=False)

    from_user = relationship("User", foreign_keys=[from_user_id])
    to_user   = relationship("User", foreign_keys=[to_user_id])

# FoodItem modeli
class FoodItem(Base):
    __tablename__ = "FoodData"
    id = Column(Integer, primary_key=True, index=True)
    product_name = Column(String(255), nullable=False)
    energy_kcal_100g = Column(Float, nullable=False)
    carbohydrates_100g = Column(Float, nullable=False)
    proteins_100g = Column(Float, nullable=False)
    fat_100g = Column(Float, nullable=True)
    fiber_100g = Column(Float, nullable=True)
    sugars_100g = Column(Float, nullable=True)

# MealEntry modeli
class MealEntry(Base):
    __tablename__ = "meal_entries"
    id            = Column(Integer, primary_key=True, index=True)
    user_id       = Column(Integer, ForeignKey("users.id"), nullable=False)
    date          = Column(Date, nullable=False)
    meal_name     = Column(String(50), nullable=False)  # "Kahvaltı", "Öğle Yemeği"...
    food_item_id  = Column(Integer, ForeignKey("FoodData.id"), nullable=False)

    user      = relationship("User", backref="meal_entries")
    food_item = relationship("FoodItem")

# Veritabanı tablolarını oluştur (tablo yapısını değiştirdiyseniz yeniden çalıştırmanız gerekebilir)
# Base.metadata.create_all(bind=engine) # Genellikle ilk kurulumda veya model değişince çalıştırılır

# ------------------ Pydantic Modelleri ------------------

class UserCreate(BaseModel):
    email: EmailStr
    username: str
    password: str
    height: float
    weight: float
    goal: str
    birth_date: date  # YYYY-MM-DD formatında gönderilmeli

class Token(BaseModel):
    access_token: str
    token_type: str
    refresh_token: Optional[str] = None
class RefreshRequest(BaseModel):
    refresh_token: str
class FriendSchema(BaseModel):
    id: int
    username: str
    email: EmailStr

    class Config:
        orm_mode = True

class FriendRequestSchema(BaseModel):
    id: int
    from_user_id: int
    from_username: str # İstek atan kullanıcının adı

    class Config:
        orm_mode = True
# input için (POST /fooditems)
class FoodItemCreate(BaseModel):
    product_name: str
    energy_kcal_100g: float
    carbohydrates_100g: float
    proteins_100g: float
    fat_100g: Optional[float] = None
    fiber_100g: Optional[float] = None
    sugars_100g: Optional[float] = None
# FoodItem için Pydantic şeması
class FoodItemSchema(BaseModel):
    id:int
    product_name: str
    energy_kcal_100g:float
    carbohydrates_100g:float
    proteins_100g: float
    fat_100g: Optional[float] = None   
    fiber_100g: Optional[float] = None  
    sugars_100g: Optional[float] = None

    class Config:
        orm_mode = True

# MealEntry için Pydantic şeması (Frontend'e dönecek yapı)
class MealEntrySchema(BaseModel):
    id: int
    date: date
    meal_name: str
    food_item: FoodItemSchema # İlişkili FoodItem nesnesi

    class Config:
        orm_mode = True

# Yeni öğün kaydı oluşturmak için Pydantic şeması (Frontend'den gelecek yapı)
class CreateMealEntry(BaseModel):
    date: date
    meal_name: str
    food_item_id: int

# Arkadaşlık isteği kabul/ret kararı için Pydantic şeması
class FriendRequestDecision(BaseModel):
    accept: bool

# ------------------ ŞİFRE HASH & JWT ------------------

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta if expires_delta else timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt
def create_refresh_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS))
    to_encode.update({"exp": expire, "type": "refresh"})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
# ------------------ YAŞ HESAPLAMA ------------------

def calculate_age(birth_date: date) -> int:
    today = date.today()
    age = today.year - birth_date.year
    if (today.month, today.day) < (birth_date.month, birth_date.day):
        age -= 1
    return age

# Harris-Benedict formülünün güncel hali (RMR hesaplama) üzerine kurulu basit bir kalori tahmini
def calculate_daily_calories(weight: float, height: float, age: int, gender: str = "male") -> float:
    return (10 * weight) + (6.25 * height) - (5 * age) + 5

# ------------------ DEPENDENCY ------------------

def get_db() -> Session:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Token doğrulama şeması
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="login")

# Mevcut kullanıcıyı getiren dependency (token ile doğrulama)
def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)) -> User:
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub") # type hint eklendi
        if email is None:
             raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Geçersiz token içeriği")

        user = db.query(User).filter(User.email == email).first()
        if user is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Kullanıcı bulunamadı")
        return user
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token süresi dolmuş")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Geçersiz token")
    except Exception as e:
         print(f"Error in get_current_user: {e}") # Hata loglama
         raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Sunucu hatası")


# ------------------ FASTAPI UYGULAMASI ------------------

app = FastAPI()
# Yeni Endpoint: Kullanıcının belirli bir tarihe kadar olan streakini getirir

@app.get("/users/me/streak")

def get_user_streak(

    target_date: date = Query(..., description="Streak hesaplanacak tarih (YYYY-MM-DD)"),

    current_user: User = Depends(get_current_user),

    db: Session = Depends(get_db)

):

    # 1. Target tarihte giriş var mı kontrol et

    has_entry_today = db.query(MealEntry).filter(

        MealEntry.user_id == current_user.id,

        MealEntry.date == target_date

    ).first() is not None



    # 2. Streak hesapla

    streak_count = 0

    current_check_date = target_date



    # Eğer bugün giriş varsa, streak bugünden başlar

    if has_entry_today:

        streak_count = 1

        # Dünden başlayarak geriye doğru git

        current_check_date = target_date - timedelta(days=1)



        while True:

            # Bu tarihte giriş var mı?

            entry_on_date = db.query(MealEntry).filter(

                MealEntry.user_id == current_user.id,

                MealEntry.date == current_check_date

            ).first()



            if entry_on_date:

                # Giriş varsa streaki artır ve bir önceki güne git

                streak_count += 1

                current_check_date -= timedelta(days=1)

            else:

                # Giriş yoksa streak bozulmuş demektir, döngüyü kır

                break



            # Kullanıcının ilk giriş tarihinden öncesine gitmemek için bir kontrol ekleyebilirsiniz (isteğe bağlı)

            # if current_check_date < user_first_entry_date: break



    # 3. Sonuçları döndür

    return {

        "streak_count": streak_count,

        "has_entry_today": has_entry_today # Bu bilgi ön yüzde alevin rengi için kullanılacak

    }




# 1) GET /users/me/meals?date=YYYY-MM-DD — Belirtilen günün kayıtlı öğünlerini döner
@app.get("/users/me/meals", response_model=List[MealEntrySchema])
def get_meals_for_date(
    date: date = Query(..., description="Öğünlerin getirileceği tarih (YYYY-MM-DD)"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Kullanıcının belirtilen tarihteki tüm öğün kayıtlarını sorgula
    entries = db.query(MealEntry)\
        .filter(
            MealEntry.user_id == current_user.id,
            MealEntry.date == date
        )\
        .options(joinedload(MealEntry.food_item))\
        .all() # <-- Girinti düzeltildi

    return entries
@app.post("/users/me/meals/photo", response_model=MealEntrySchema)
async def classify_and_log_meal(
    meal_name: str = Query(...),
    date: date = Query(...),
    image: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # 1) Fotoğrafı classifier servisine gönder
    files = {'image': (image.filename, await image.read(), image.content_type)}
    #resp = httpx.post("http://127.0.0.1:8001/classify", files=files)
    #resp = httpx.post("http://localhost/classify", files=files)
    #resp = httpx.post("http://app1:8001/classify", files=files)
    #resp = httpx.post("http://192.168.43.171:8001/classify", files=files)
    #resp = httpx.post("https://77f1-176-227-2-12.ngrok-free.app/classify", files=files)
    resp = httpx.post("https://classifier.yakkit.shop/classify", files=files)
    resp.raise_for_status()
    data = resp.json()
    label = data['class']
    calories = data['calories']

    # 2) Veritabanına kaydet (FoodItem & MealEntry)
    food = db.query(FoodItem).filter_by(product_name=label).first()
    if not food:
        food = FoodItem(
          product_name=label,
          energy_kcal_100g=calories,
          carbohydrates_100g=0,
          proteins_100g=0
        )
        db.add(food); db.commit(); db.refresh(food)

    entry = MealEntry(
      user_id=current_user.id,
      date=date,
      meal_name=meal_name,
      food_item_id=food.id
    )
    db.add(entry); db.commit(); db.refresh(entry)
    print("← raw returned:", entry.__dict__, entry.food_item.__dict__)
    return entry
# 2) POST /users/me/meals — Yeni bir öğün kaydı ekler
@app.post("/users/me/meals", response_model=MealEntrySchema, status_code=201)
def create_meal_entry(
    data: CreateMealEntry, # İstek gövdesinden CreateMealEntry modelini al
    current_user: User = Depends(get_current_user), # Token ile kullanıcıyı doğrula
    db: Session = Depends(get_db) # Veritabanı oturumu
):
    # Frontend'den gelen verilerle yeni MealEntry nesnesi oluştur
    entry = MealEntry(
        user_id=current_user.id, # Mevcut kullanıcının ID'si
        date=data.date,
        meal_name=data.meal_name, # Frontend'den gelen meal_name stringi
        food_item_id=data.food_item_id # Frontend'den gelen food_item_id
    )

    db.add(entry) # Veritabanına ekle
    db.commit() # Değişiklikleri kaydet
    db.refresh(entry) # Eklenen nesneyi veritabanından yenile (ID gibi alanlar dolar)

    # Eklenen kaydı FoodItem ilişkisi ile birlikte döndür
    # İlişkiyi yüklemek için tekrar sorgulama ve options kullanma (veya refresh sonrası eager load)
    return db.query(MealEntry).filter(MealEntry.id == entry.id).options(joinedload(MealEntry.food_item)).first()


# Arkadaş listeleme endpoint'i
@app.get("/users/me/friends", response_model=List[FriendSchema])
def list_friends(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Doğrulanmış kullanıcının arkadaş listesini döndürür (SQLAlchemy ilişkisi kullanılıyor)
    # return current_user.friends # friend ilişkisi eager load edilmemiş olabilir
    # İlişkiyi yükleyerek döndürmek daha güvenli olabilir:
     return db.query(User).filter(User.id == current_user.id).options(joinedload(User.friends)).first().friends


# Arkadaşlık isteği gönderme endpoint'i
@app.post("/users/me/friend-requests", response_model=FriendRequestSchema, status_code=201)
def send_friend_request(
    body: dict = Body(..., example={"to_user_id": 4}, description="İstek gönderilecek kullanıcının user_id'si"), # Örnek ve açıklama eklendi
    current_user: User = Depends(get_current_user), # Token ile kullanıcıyı doğrula
    db: Session = Depends(get_db) # Veritabanı oturumu
):
    to_id = body.get("to_user_id")
    if to_id is None:
         raise HTTPException(422, "to_user_id alanı gerekli.") # Eksik alan kontrolü

    if to_id == current_user.id:
        raise HTTPException(400, "Kendinize arkadaşlık isteği gönderemezsiniz.")

    # Zaten bekleyen veya kabul edilmiş bir istek var mı kontrol et
    existing_request = db.query(FriendRequest).filter(
        ((FriendRequest.from_user_id == current_user.id) & (FriendRequest.to_user_id == to_id)) |
        ((FriendRequest.from_user_id == to_id) & (FriendRequest.to_user_id == current_user.id))
    ).filter(FriendRequest.status.in_(["pending", "accepted"])).first()

    if existing_request:
        if existing_request.status == "pending":
             raise HTTPException(400, "Bu kullanıcıya zaten bekleyen bir arkadaşlık isteğiniz var.")
        elif existing_request.status == "accepted":
             raise HTTPException(400, "Bu kullanıcı zaten arkadaşınız.")

    target_user = db.query(User).get(to_id)
    if not target_user:
        raise HTTPException(404, "İstek gönderilmek istenen kullanıcı bulunamadı.")

    # Yeni arkadaşlık isteği oluştur
    new_request = FriendRequest(
      from_user_id = current_user.id,
      to_user_id   = to_id,
      status       = "pending"
    )
    db.add(new_request) # Veritabanına ekle
    db.commit() # Değişiklikleri kaydet
    db.refresh(new_request) # Eklenen nesneyi veritabanından yenile

    # Pydantic şemasına uygun olarak döndür
    # İlişkisel veriyi (from_user.username) yüklemek için from_user ilişkisini eager load et
    db.refresh(new_request) # from_user ilişkisini yüklemek için refresh gerekebilir
    return FriendRequestSchema(
      id            = new_request.id,
      from_user_id  = new_request.from_user_id,
      from_username = new_request.from_user.username # İlişkiden kullanıcı adını al
    )


# Arkadaş silme endpoint'i
@app.delete("/users/me/friends/{friend_id}", status_code=204)
def remove_friend(
    friend_id: int = Path(..., description="Silinecek arkadaşın user_id'si"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Silinecek arkadaşı veritabanında bul
    friend_to_remove = db.query(User).get(friend_id)
    # Arkadaşın varlığını ve mevcut kullanıcının arkadaşı olup olmadığını kontrol et
    if not friend_to_remove or friend_to_remove not in current_user.friends:
        raise HTTPException(404, "Arkadaş bulunamadı veya zaten ekli değil.")

    # SQLAlchemy ilişkisini kullanarak arkadaşı listeden kaldır
    # İlişkiyi hem kullanıcının hem de arkadaşın listesinden kaldır (iki yönlü silme)
    current_user.friends.remove(friend_to_remove)
    friend_to_remove.friends.remove(current_user) # İlişkinin diğer yönünü de sil

    db.commit() # Değişiklikleri kaydet

    # 204 No Content statüsünde başarılı yanıt döndür (body içermez)
    return


# Kullanıcı arama endpoint'i (kullanıcı adına göre)
@app.get("/users/search", response_model=List[FriendSchema])
def search_users(
    username: str = Query(..., description="Aranacak kullanıcı adı (kısmi ve büyük/küçük harf duyarsız)"),
    db: Session = Depends(get_db)
):
    # product_name alanında arama sorgusunu içeren (case-insensitive) yiyecekleri filtrele
    users = db.query(User)\
        .filter(User.username.ilike(f"%{username}%"))\
        .all() # Eşleşen tüm kullanıcıları getir

    # Pydantic şemasına dönüştürülmüş listeyi döndür
    return users

# Gelen arkadaşlık isteklerini listeleme endpoint'i
@app.get("/users/me/friend-requests", response_model=List[FriendRequestSchema])
def list_friend_requests(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Mevcut kullanıcıya gelen ve durumu 'pending' olan istekleri sorgula
    pending_requests = db.query(FriendRequest)\
        .filter(
            FriendRequest.to_user_id == current_user.id,
            FriendRequest.status == "pending"
        )\
        .options(joinedload(FriendRequest.from_user))\
        .all() # <-- Girinti düzeltildi


    # Sorgu sonuçlarını Pydantic şemasına dönüştürerek döndür
    return [
        FriendRequestSchema(
            id=req.id,
            from_user_id=req.from_user_id,
            from_username=req.from_user.username # İlişkiden kullanıcı adını al
        )
        for req in pending_requests
    ]

# Arkadaşlık isteğine yanıt verme endpoint'i (kabul veya reddetme)
@app.post("/users/me/friend-requests/{request_id}/respond")
def respond_friend_request(
    request_id: int = Path(..., description="Yanıtlanacak istek ID'si"),
    decision: FriendRequestDecision = Body(...), # Kabul veya reddetme bilgisi (boolean)
    current_user: User = Depends(get_current_user), # Token ile kullanıcıyı doğrula
    db: Session = Depends(get_db) # Veritabanı oturumu
):
    # Belirtilen ID'ye sahip, mevcut kullanıcıya gelen ve bekleyen isteği sorgula
    req = db.query(FriendRequest)\
        .filter(
            FriendRequest.id == request_id,
            FriendRequest.to_user_id == current_user.id,
            FriendRequest.status == "pending"
        )\
        .options(joinedload(FriendRequest.from_user))\
        .first() # <-- Girinti düzeltildi


    if not req:
        raise HTTPException(status_code=404, detail="İstek bulunamadı, zaten yanıtlanmış veya size ait değil.")

    if decision.accept:
        # İstek kabul edildiyse:
        # İki kullanıcı arasında arkadaşlık ilişkisini iki yönlü olarak kur
        current_user.friends.append(req.from_user) # Mevcut kullanıcının arkadaş listesine ekle
        req.from_user.friends.append(current_user) # İstek atan kullanıcının arkadaş listesine ekle
        req.status = "accepted" # İsteğin durumunu güncelle
        # İsteği veritabanından silebilirsiniz veya durumu "accepted" olarak bırakabilirsiniz.
        # Eğer durumu güncellediyseniz silmeye gerek yok. Eğer sadece kabul edilenleri tutacaksanız silebilirsiniz.
        # Burada durumu güncelleyip silmiyorum.
        # db.delete(req) # İsteği silmek isterseniz bu satırı kullanın
    else:
        # İstek reddedildiyse:
        req.status = "rejected" # İsteğin durumunu "rejected" olarak güncelle

    db.commit() # Değişiklikleri kaydet

    # Başarılı yanıt döndür
    return {"detail": "İşlem tamamlandı", "status": req.status}


# Kayıt endpoint'i
@app.post("/register", response_model=Token, status_code=201) # 201 Created status kodu
def register(user: UserCreate, db: Session = Depends(get_db)):
    # Email veya kullanıcı adının zaten kayıtlı olup olmadığını kontrol et
    existing_user = db.query(User).filter(
        or_(User.email == user.email, User.username == user.username)
    ).first()
    if existing_user:
        detail_msg = "Email zaten kayıtlı." if existing_user.email == user.email else "Kullanıcı adı zaten kayıtlı."
        raise HTTPException(
            status_code=400,
            detail=detail_msg # Daha spesifik hata mesajı
        )

    # Şifreyi hashle, yaş ve günlük kalori ihtiyacını hesapla
    hashed_pw = get_password_hash(user.password)
    age = calculate_age(user.birth_date)
    # Cinsiyet bilgisi UserCreate modeline ve calculate_daily_calories fonksiyonuna eklenirse daha doğru kalori hesaplanır.
    daily_calories = calculate_daily_calories(user.weight, user.height, age)

    # Yeni kullanıcı nesnesi oluştur
    db_user = User(
        email=user.email,
        username=user.username,
        hashed_password=hashed_pw,
        height=user.height,
        weight=user.weight,
        goal=user.goal,
        birth_date=user.birth_date,
        daily_calories=daily_calories # Hesaplanan kalori kaydediliyor
    )
    db.add(db_user) # Veritabanına ekle
    db.commit() # Değişiklikleri kaydet
    db.refresh(db_user) # Eklenen kullanıcıyı yenile

    # Kullanıcı için JWT token oluştur ve döndür
    access_token = create_access_token(data={"sub": db_user.email})
    return {"access_token": access_token, "token_type": "bearer"}

# Giriş endpoint'i
@app.post("/login", response_model=Token)
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    # Email (form_data.username olarak geliyor) ile kullanıcıyı bul
    user = db.query(User).filter(User.email == form_data.username).first()
    # Kullanıcı yoksa veya şifre yanlışsa yetkilendirme hatası döndür
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Hatalı email veya şifre",
            headers={"WWW-Authenticate": "Bearer"},
        )
    # Başarılı girişte JWT token oluştur ve döndür
    #access_token = create_access_token(data={"sub": user.email})
    #return {"access_token": access_token, "token_type": "bearer"}
    access_token  = create_access_token(data={"sub": user.email})
    refresh_token = create_refresh_token(data={"sub": user.email})
    return {
        "access_token": access_token,
        "token_type":   "bearer",
        "refresh_token": refresh_token
    }
@app.post("/token/refresh", response_model=Token)
def refresh_token(req: RefreshRequest):
    try:
        payload = jwt.decode(req.refresh_token, SECRET_KEY, algorithms=[ALGORITHM])
        if payload.get("type") != "refresh":
            raise HTTPException(status_code=401, detail="Invalid token type")
        email = payload.get("sub")
        if email is None:
            raise HTTPException(status_code=401, detail="Invalid token payload")
        # (Optional) Check DB or a blacklist to see if this refresh token is revoked.

        # Issue a brand-new access token:
        access_token = create_access_token(data={"sub": email})
        # Optionally rotate refresh tokens:
        refresh_token = create_refresh_token(data={"sub": email})
        return {
            "access_token":  access_token,
            "token_type":    "bearer",
            "refresh_token": refresh_token
        }
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Refresh token expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid refresh token")

# Kullanıcı bilgi endpoint'i (token gerektirir)
@app.get("/userinfo")
def get_user_info(current_user: User = Depends(get_current_user)): # get_current_user dependency kullanıldı
    # get_current_user dependency zaten token'ı doğruluyor ve kullanıcıyı getiriyor
    user = current_user # current_user artık doğrulanmış kullanıcı nesnesi

    # Kullanıcının doğum tarihine göre yaş hesaplanıyor
    age = calculate_age(user.birth_date)
    # Boy, kilo ve yaş bilgilerine göre günlük kalori ihtiyacı yeniden hesaplanıyor (gerekirse, kayıt olurken hesaplanıyor)
    # Eğer bu değerin her zaman güncel olması gerekiyorsa burada hesaplayıp döndürebilirsiniz.
    # Aksi halde veritabanından gelen değeri kullanmak yeterli olabilir.
    # Veritabanından gelen daily_calories float olduğu için int'e çevirip döndürelim frontend için.
    calculated_daily_calories = int(calculate_daily_calories(user.weight, user.height, age))

    # Base64 profil resmi (varsa)
    image_b64 = base64.b64encode(user.profile_image).decode() if user.profile_image else None

    # Kullanıcı bilgilerini sözlük olarak döndür
    return {
        "id": user.id,
        "email": user.email,
        "username": user.username,
        "daily_calories": calculated_daily_calories, # Hesaplanan değeri döndür
        "height": user.height,
        "weight": user.weight,
        "birth_date": user.birth_date.isoformat(), # Tarihi ISO formatında stringe çevir
        "goal": user.goal,
        "age": age,
        "profile_image": image_b64
    }


# /fooditems endpoint'i: Tüm yiyecek verilerini döndürür.
@app.get("/fooditems", response_model=List[FoodItemSchema])
def get_fooditems(db: Session = Depends(get_db)):
    # FoodData tablosundaki tüm yiyecekleri sorgula
    items = db.query(FoodItem).all()
    # FoodItem listesini FoodItemSchema listesine dönüştürerek döndür
    return items

# /fooditems/search endpoint'i: Arama sorgusuna göre eşleşen yiyecek verilerini döndürür.
@app.get("/fooditems/search", response_model=List[FoodItemSchema])
def search_fooditems(
    query: str = Query(..., description="Aranacak yiyecek adı (kısmi ve büyük/küçük harf duyarsız)"),
    db: Session = Depends(get_db)
):
    # product_name alanında arama sorgusunu içeren (case-insensitive) yiyecekleri filtrele
    items = db.query(FoodItem).filter(FoodItem.product_name.ilike(f"{query}%")).order_by(FoodItem.product_name).limit(20).all()
    # Eşleşen yiyecek listesini FoodItemSchema listesine dönüştürerek döndür
    return items

#  Yeni yiyecek ekleme endpoint'i.
@app.post("/fooditems", response_model=FoodItemSchema, status_code=201)
async def create_fooditem(
    item: FoodItemCreate = Body(...),     # RequestBody doğrudan Pydantic modeli
    db: Session = Depends(get_db),
):
    # Ham JSON payload'ı görmek isterseniz:
    print("🛠️ RAW PAYLOAD:", item)

    db_item = FoodItem(**item.dict())
    db.add(db_item)
    db.commit()
    db.refresh(db_item)
    return db_item



# Profil fotoğrafı yükleme endpoint'i
@app.post("/users/{user_id}/upload-photo")
async def upload_photo(user_id: int = Path(..., description="Fotoğraf yüklenecek kullanıcının ID'si"), file: UploadFile = File(..., description="Yüklenecek fotoğraf dosyası"), db: Session = Depends(get_db)):
    # Belirtilen ID'ye sahip kullanıcıyı veritabanında bul
    user = db.query(User).get(user_id)
    if not user:
        raise HTTPException(404, "Kullanıcı bulunamadı.")

    # Yüklenen dosya boyutunu kontrol et (isteğe bağlı)
    file.file.seek(0, 2)
    file_size = file.file.tell()
    file.file.seek(0) # Dosya imlecini başa al

    if file_size > 5 * 1024 * 1024: # Örnek: 5MB limit
        raise HTTPException(status_code=400, detail="Dosya boyutu çok büyük (Max 5MB)")
        raise HTTPException(status_code=400, detail="Dosya boyutu çok büyük (Max 5MB)")


    # Yüklenen dosyayı bayt olarak oku
    data = await file.read()
    # Okunan bayt verisini kullanıcının profil_image alanına ata
    user.profile_image = data
    db.commit() # Değişiklikleri kaydet

    # Başarılı yanıt döndür
    return {"message": "Profil fotoğrafı başarıyla yüklendi."}

# FastAPI uygulamasını başlatmak için (bu dosya ana dosya ise)
if __name__ == "__main__":
    import uvicorn
    # reload=True geliştirme sırasında kod değişikliklerini otomatik algılar
    uvicorn.run("fooddatabackend:app", host="0.0.0.0", port=8000, reload=True)
    #  