from enum import Enum

from core.models import Base
from sqlalchemy import Column, Integer, Float, Boolean, String, ForeignKey, DateTime, func, JSON, Table
from sqlalchemy.orm import relationship, Mapped, mapped_column, backref

project_widget_association = Table(
    "ProjectWidget",
    Base.metadata,
    Column("project_id", ForeignKey("Project.id"), primary_key=True),
    Column("widget_id", ForeignKey("Widget.id"), primary_key=True)
)

class Project(Base):
    __tablename__ = 'Project'
    name: Mapped[str] = mapped_column(String,nullable=False)
    id: Mapped[int] = mapped_column(primary_key=True)
    rules: Mapped[dict] = mapped_column(JSON, nullable=False, default=dict)

    widgets = relationship("Widget", secondary=project_widget_association, back_populates="projects")

    def __str__(self):
        return f'{self.__class__.__name__} with {self.name}'

class Widget(Base):
    __tablename__ = "Widget"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String, nullable=False)
    type: Mapped[str] = mapped_column(String, nullable=False)
    config: Mapped[dict] = mapped_column(JSON, nullable=False, default=dict)
    file_url: Mapped[str] = mapped_column(String, nullable=True)

    projects = relationship("Project", secondary=project_widget_association, back_populates="widgets")

    def __str__(self):
            return f'{self.__class__.__name__} with {self.name}'
