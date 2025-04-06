import os
import shutil
from typing import List, Dict, Optional
from fastapi import APIRouter, HTTPException, Depends, UploadFile, File
from pydantic import BaseModel, field_validator, ValidationError
from sqlalchemy import delete
from sqlalchemy.future import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from core.models import db_helper, Project, Widget
# from core.models.coremodels import PointType, PointImage

router = APIRouter()
router.tags = ["Name"]

class ProjectCreateScheme(BaseModel):
    name: str
    rules: Dict  # JSON-правила

class ProjectUpdateScheme(BaseModel):
    name: str
    rules: Dict

class ProjectViewScheme(BaseModel):
    id: int
    name: str
    rules: Dict

    class Config:
        from_attributes = True

class WidgetCreateScheme(BaseModel):
    name: str
    type: str  # Тип виджета
    config: Dict  # JSON-конфиг виджета
    file_url: Optional[str] = None  # Опциональная ссылка на файл

class WidgetUpdateScheme(BaseModel):
    name: str
    type: str
    config: Dict
    file_url: Optional[str] = None

class WidgetViewScheme(BaseModel):
    id: int
    name: str
    type: str
    config: Dict
    file_url: Optional[str] = None

    class Config:
        from_attributes = True

async def create_project_crud(session: AsyncSession, project_in: ProjectCreateScheme) -> ProjectViewScheme:
    project = Project(name=project_in.name, rules=project_in.rules)
    session.add(project)
    await session.commit()
    await session.refresh(project)
    return ProjectViewScheme(id=project.id, name=project.name, rules=project.rules)


async def update_project_crud(session: AsyncSession, project_id: int, project_data: ProjectUpdateScheme):
    result = await session.execute(select(Project).where(Project.id == project_id))
    project = result.scalars().first()

    if not project:
        raise HTTPException(status_code=404, detail="Проект не найден")

    project.name = project_data.name
    project.rules = project_data.rules
    await session.commit()
    await session.refresh(project)

    return ProjectViewScheme(id=project.id, name=project.name, rules=project.rules)


async def get_projects_crud(session: AsyncSession) -> List[ProjectViewScheme]:
    result = await session.execute(select(Project))
    projects = result.scalars().all()
    return [ProjectViewScheme(id=p.id, name=p.name, rules=p.rules) for p in projects]


async def get_project_by_id_crud(session: AsyncSession, project_id: int) -> ProjectViewScheme:
    result = await session.execute(select(Project).where(Project.id == project_id))
    project = result.scalars().first()

    if not project:
        raise HTTPException(status_code=404, detail="Проект не найден")

    return ProjectViewScheme(id=project.id, name=project.name, rules=project.rules)


async def delete_project_crud(session: AsyncSession, project_id: int):
    result = await session.execute(select(Project).where(Project.id == project_id))
    project = result.scalars().first()

    if not project:
        raise HTTPException(status_code=404, detail="Проект не найден")

    await session.execute(delete(Project).where(Project.id == project_id))
    await session.commit()
    return {"message": "Проект удален"}

async def create_widget_crud(session: AsyncSession, widget_in: WidgetCreateScheme) -> WidgetViewScheme:
    widget = Widget(name=widget_in.name, type=widget_in.type, config=widget_in.config, file_url=widget_in.file_url)
    session.add(widget)
    await session.commit()
    await session.refresh(widget)
    return WidgetViewScheme(id=widget.id, name=widget.name, type=widget.type, config=widget.config, file_url=widget.file_url)

async def update_widget_crud(session: AsyncSession, widget_id: int, widget_data: WidgetUpdateScheme):
    result = await session.execute(select(Widget).where(Widget.id == widget_id))
    widget = result.scalars().first()

    if not widget:
        raise HTTPException(status_code=404, detail="Виджет не найден")

    widget.name = widget_data.name
    widget.type = widget_data.type
    widget.config = widget_data.config
    widget.file_url = widget_data.file_url
    await session.commit()
    await session.refresh(widget)

    return WidgetViewScheme(id=widget.id, name=widget.name, type=widget.type, config=widget.config, file_url=widget.file_url)

async def get_widgets_crud(session: AsyncSession) -> List[WidgetViewScheme]:
    result = await session.execute(select(Widget))
    widgets = result.scalars().all()
    return [WidgetViewScheme(id=w.id, name=w.name, type=w.type, config=w.config, file_url=w.file_url) for w in widgets]

async def get_widget_by_id_crud(session: AsyncSession, widget_id: int) -> WidgetViewScheme:
    result = await session.execute(select(Widget).where(Widget.id == widget_id))
    widget = result.scalars().first()

    if not widget:
        raise HTTPException(status_code=404, detail="Виджет не найден")

    return WidgetViewScheme(id=widget.id, name=widget.name, type=widget.type, config=widget.config, file_url=widget.file_url)

async def delete_widget_crud(session: AsyncSession, widget_id: int):
    result = await session.execute(select(Widget).where(Widget.id == widget_id))
    widget = result.scalars().first()

    if not widget:
        raise HTTPException(status_code=404, detail="Виджет не найден")

    await session.execute(delete(Widget).where(Widget.id == widget_id))
    await session.commit()
    return {"message": "Виджет удален"}

@router.post("/projects/", response_model=ProjectViewScheme)
async def create_project(project_in: ProjectCreateScheme, db: AsyncSession = Depends(db_helper.scoped_session_dependency)):
    return await create_project_crud(session=db, project_in=project_in)

@router.put("/projects/{project_id}/", response_model=ProjectViewScheme)
async def update_project(project_id: int, project_data: ProjectUpdateScheme, db: AsyncSession = Depends(db_helper.scoped_session_dependency)):
    return await update_project_crud(session=db, project_id=project_id, project_data=project_data)

@router.get("/projects/", response_model=List[ProjectViewScheme])
async def get_projects(db: AsyncSession = Depends(db_helper.scoped_session_dependency)):
    return await get_projects_crud(session=db)

@router.get("/projects/{project_id}/", response_model=ProjectViewScheme)
async def get_project_by_id(project_id: int, db: AsyncSession = Depends(db_helper.scoped_session_dependency)):
    return await get_project_by_id_crud(session=db, project_id=project_id)

@router.delete("/projects/{project_id}/")
async def delete_project(project_id: int, db: AsyncSession = Depends(db_helper.scoped_session_dependency)):
    return await delete_project_crud(session=db, project_id=project_id)

@router.post("/widgets/", response_model=WidgetViewScheme)
async def create_widget(widget_in: WidgetCreateScheme, db: AsyncSession = Depends(db_helper.scoped_session_dependency)):

    return await create_widget_crud(session=db, widget_in=widget_in)

@router.put("/widgets/{widget_id}/", response_model=WidgetViewScheme)
async def update_widget(widget_id: int, widget_data: WidgetUpdateScheme, db: AsyncSession = Depends(db_helper.scoped_session_dependency)):

    return await update_widget_crud(session=db, widget_id=widget_id, widget_data=widget_data)

@router.get("/widgets/", response_model=List[WidgetViewScheme])
async def get_widgets(db: AsyncSession = Depends(db_helper.scoped_session_dependency)):

    return await get_widgets_crud(session=db)

@router.get("/widgets/{widget_id}/", response_model=WidgetViewScheme)
async def get_widget_by_id(widget_id: int, db: AsyncSession = Depends(db_helper.scoped_session_dependency)):

    return await get_widget_by_id_crud(session=db, widget_id=widget_id)

@router.delete("/widgets/{widget_id}/")
async def delete_widget(widget_id: int, db: AsyncSession = Depends(db_helper.scoped_session_dependency)):

    return await delete_widget_crud(session=db, widget_id=widget_id)