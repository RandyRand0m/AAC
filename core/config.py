import os

from dotenv import load_dotenv
from pydantic.v1 import BaseSettings

dev_status = True

load_dotenv()

if dev_status:
    print("Текущая база данных:", os.getenv("GADBNAME"))
    db_url = f"postgresql+asyncpg://{os.getenv('GAUSERNAME')}:{os.getenv('GAPASSWORD')}@{os.getenv('GAHOST')}:{os.getenv('GAPORT')}/{os.getenv('GADBNAME')}"
    alemb_url = f"postgresql://{os.getenv('GAUSERNAME')}:{os.getenv('GAPASSWORD')}@{os.getenv('GAHOST')}:{os.getenv('GAPORT')}/{os.getenv('GADBNAME')}"
    rab_url = "localhost"


class Settings(BaseSettings):
    db_url: str = db_url
    db_url_alembic: str = alemb_url
    rabbit_url: str = rab_url
    db_echo: bool = False  # True only for DEBUG


settings = Settings()
