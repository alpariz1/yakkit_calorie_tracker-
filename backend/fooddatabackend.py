from fastapi import FastAPI, Depends, HTTPException, status, Security
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from pydantic import BaseModel, EmailStr
from datetime import datetime, timedelta, date
from typing import Optional, List
import jwt
from passlib.context import CryptContext

# SQLAlchemy modülleri
from sqlalchemy import create_engine, Column, Integer, String, Float, Date, or_
from sqlalchemy.orm import declarative_base, sessionmaker, Session

# ------------------ CONFIG & DATABASE ------------------

SECRET_KEY = "your_secret_key_here"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

# SQL Server bağlantı dizesi
DATABASE_URL = "mssql+pyodbc://DESKTOP-BAMBOR6/yakkitfooddb?driver=ODBC+Driver+17+for+SQL+Server&trusted_connection=yes"

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

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

# FoodItem modeli
class FoodItem(Base):
    __tablename__ = "FoodData"
    id = Column(Integer, primary_key=True, index=True)
    product_name = Column(String(255), nullable=False)
    energy_kcal_100g = Column(Float, nullable=True)
    carbohydrates_100g = Column(Float, nullable=True)
    proteins_100g = Column(Float, nullable=True)
    fat_100g = Column(Float, nullable=True)
    fiber_100g = Column(Float, nullable=True)
    sugars_100g = Column(Float, nullable=True)

Base.metadata.create_all(bind=engine)

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

# FoodItem için Pydantic şeması
class FoodItemSchema(BaseModel):
    id: Optional[int]
    product_name: str
    energy_kcal_100g: Optional[float]
    carbohydrates_100g: Optional[float]
    proteins_100g: Optional[float]
    fat_100g: Optional[float]
    fiber_100g: Optional[float]
    sugars_100g: Optional[float]

    class Config:
        orm_mode = True

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

# ------------------ YAŞ HESAPLAMA ------------------

def calculate_age(birth_date: date) -> int:
    today = date.today()
    age = today.year - birth_date.year
    if (today.month, today.day) < (birth_date.month, birth_date.day):
        age -= 1
    return age

def calculate_daily_calories(weight: float, height: float, age: int) -> float:
    return (10 * weight) + (6.25 * height) - (5 * age) + 5

# ------------------ DEPENDENCY ------------------

def get_db() -> Session:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# ------------------ FASTAPI UYGULAMASI ------------------

app = FastAPI()
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="login")

# Kayıt endpoint'i
@app.post("/register", response_model=Token)
def register(user: UserCreate, db: Session = Depends(get_db)):
    existing_user = db.query(User).filter(
        or_(User.email == user.email, User.username == user.username)
    ).first()
    if existing_user:
        raise HTTPException(
            status_code=400,
            detail="Email veya kullanıcı adı zaten kayıtlı."
        )

    hashed_pw = get_password_hash(user.password)
    age = calculate_age(user.birth_date)
    daily_calories = calculate_daily_calories(user.weight, user.height, age)

    db_user = User(
        email=user.email,
        username=user.username,
        hashed_password=hashed_pw,
        height=user.height,
        weight=user.weight,
        goal=user.goal,
        birth_date=user.birth_date,
        daily_calories=daily_calories
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)

    access_token = create_access_token(data={"sub": db_user.email})
    return {"access_token": access_token, "token_type": "bearer"}

# Giriş endpoint'i
@app.post("/login", response_model=Token)
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == form_data.username).first()
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Hatalı email veya şifre",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token = create_access_token(data={"sub": user.email})
    return {"access_token": access_token, "token_type": "bearer"}

# /userinfo endpoint'i
""""@app.get("/userinfo")
def get_user_info(token: str = Security(oauth2_scheme), db: Session = Depends(get_db)):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email = payload.get("sub")
        user = db.query(User).filter(User.email == email).first()
        if not user:
            raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı")
        return {"username": user.username, "daily_calories": user.daily_calories}
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token süresi dolmuş")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Geçersiz token")*/"""
@app.get("/userinfo")
def get_user_info(token: str = Security(oauth2_scheme), db: Session = Depends(get_db)):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email = payload.get("sub")
        user = db.query(User).filter(User.email == email).first()
        if not user:
            raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı")
        # Kullanıcının doğum tarihine göre yaş hesaplanıyor
        age = calculate_age(user.birth_date)
        # Boy, kilo ve yaş bilgilerine göre günlük kalori ihtiyacı yeniden hesaplanıyor
        daily_calories = calculate_daily_calories(user.weight, user.height, age)
        #print(f"DEBUG: weight={user.weight}, height={user.height}, age={age}, daily_calories={daily_calories}")
        print(f"DEBUG: weight={user.weight}, height={user.height}, age={age}, daily_calories={daily_calories}", flush=True)

        return {
            "username": user.username,
            "daily_calories": daily_calories,
            "height": user.height,
            "weight": user.weight,
            "birth_date": user.birth_date.isoformat(),
            "goal": user.goal,         # ← ekledik
            "age": age
        }
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token süresi dolmuş")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Geçersiz token")

# /fooditems endpoint'i: Tüm yiyecek verilerini döndürür.
@app.get("/fooditems", response_model=List[FoodItemSchema])
def get_fooditems(db: Session = Depends(get_db)):
    items = db.query(FoodItem).all()
    return items
# /fooditems/search endpoint'i: Arama sorgusuna göre eşleşen yiyecek verilerini döndürür.
@app.get("/fooditems/search", response_model=List[FoodItemSchema])
def search_fooditems(query: str, db: Session = Depends(get_db)):
    # SQL Server'da case-insensitive arama yapmak için ilike kullanabiliriz.
    items = db.query(FoodItem).filter(FoodItem.product_name.ilike(f"%{query}%")).all()
    return items

# (Opsiyonel) Yeni yiyecek ekleme endpoint'i.
@app.post("/fooditems", response_model=FoodItemSchema)
def create_fooditem(item: FoodItemSchema, db: Session = Depends(get_db)):
    db_item = FoodItem(**item.dict())
    db.add(db_item)
    db.commit()
    db.refresh(db_item)
    return db_item

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("fooddatabackend:app", host="127.0.0.1", port=8000, reload=True)
