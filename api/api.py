import os
import shutil
from typing import List, Dict
from fastapi import APIRouter, HTTPException, Depends, UploadFile, File
from pydantic import BaseModel, field_validator, ValidationError
from sqlalchemy import delete
from sqlalchemy.future import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from core.models import db_helper, Project
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
