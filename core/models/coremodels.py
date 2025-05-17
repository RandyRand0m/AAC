from enum import Enum
from typing import Optional

from core.models import Base
from sqlalchemy import Column, Integer, Float, Boolean, String, ForeignKey, DateTime, func, JSON, Table, Text
from sqlalchemy.orm import relationship, Mapped, mapped_column, backref

class User(Base):
    __tablename__ = "User"

    id: Mapped[int] = mapped_column(primary_key=True)
    phone = Column(String, unique=True, index=True)

    projects = relationship("Project", back_populates="user")

class Project(Base):
    __tablename__ = 'Project'

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String, nullable=False)
    user_id: Mapped[Optional[int]] = mapped_column(ForeignKey("User.id"), nullable=True)
    user = relationship("User", back_populates="projects")
    rules: Mapped[dict] = mapped_column(JSON, nullable=False, default=dict)

    #widgets = relationship("Widget", back_populates="project", cascade="all, delete-orphan")
    pages = relationship("Page", back_populates="project", cascade="all, delete-orphan")
    def __str__(self):
        return f'{self.__class__.__name__} with {self.name}'

class Widget(Base):
    __tablename__ = "Widget"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String, nullable=False)
    type: Mapped[str] = mapped_column(String, nullable=False)
    config: Mapped[dict] = mapped_column(JSON, nullable=False, default=dict)
    code: Mapped[str] = mapped_column(Text, nullable=True)
    file_url: Mapped[str] = mapped_column(String, nullable=True)

    page_id: Mapped[int] = mapped_column(ForeignKey("Page.id"), nullable=False)
    page = relationship("Page", back_populates="widgets")

    def __str__(self):
        return f'{self.__class__.__name__} with {self.name}'
class Page(Base):
    __tablename__ = "Page"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String, nullable=False)
    order: Mapped[int] = mapped_column(Integer, default=0)

    project_id: Mapped[int] = mapped_column(ForeignKey("Project.id"), nullable=False)
    project = relationship("Project", back_populates="pages")

    widgets = relationship("Widget", back_populates="page", cascade="all, delete-orphan")

class Verification(Base):
    __tablename__ = "verification"
    phone_number = Column(String, primary_key=True)