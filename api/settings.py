import os
from pydantic_settings import BaseSettings
from pathlib import Path

class Settings(BaseSettings):
    SECRET_KEY: str
    REFRESH_SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60

    GADBNAME: str
    GAPORT: int
    GAHOST: str
    GAUSERNAME: str
    GAPASSWORD: str
    GAALGORITHM: str = "HS256"
    GASEKKEY: str
    GASECREFKEY: str
    GASALT: str
    GAACTOKENEXP: int

    class Config:
        env_file = str(Path(__file__).parent.parent / ".env")
        env_file_encoding = 'utf-8'


settings = Settings()
print(f"SECRET_KEY: {settings.SECRET_KEY}")
print(f"REFRESH_SECRET_KEY: {settings.REFRESH_SECRET_KEY}")