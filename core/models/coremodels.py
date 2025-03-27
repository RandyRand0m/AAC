from enum import Enum

from core.models import Base
from sqlalchemy import Column, Integer, Float, Boolean, String, ForeignKey, DateTime, func, JSON
from sqlalchemy.orm import relationship, Mapped, mapped_column, backref

class Project(Base):
    __tablename__ = 'Project'
    name: Mapped[str] = mapped_column(String,nullable=False)
    id: Mapped[int] = mapped_column(primary_key=True)
    rules: Mapped[dict] = mapped_column(JSON, nullable=False, default=dict)
    def __str__(self):
        return f'{self.__class__.__name__} with {self.name}'
