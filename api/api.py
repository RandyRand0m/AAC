import os
import shutil
from typing import List, Dict, Optional

import httpx
from fastapi import APIRouter, HTTPException, Depends, UploadFile, File, Header
from fastapi.security import OAuth2PasswordBearer
from pydantic import BaseModel, field_validator, ValidationError
from rest_framework import status
from sqlalchemy import delete
from sqlalchemy.future import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from starlette.responses import JSONResponse

from core.models import db_helper, Project, Widget, Page, User
# from core.models.coremodels import PointType, PointImage

from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from jose import jwt, JWTError
from starlette.status import HTTP_401_UNAUTHORIZED

from core.config import settings  # SECRET_KEY и прочее

from core.models import  User
from .settings import settings

router = APIRouter()
router.tags = ["Name"]

class WidgetLinkScheme(BaseModel):
    id: int

class WidgetViewScheme(BaseModel):
    id: int
    name: str
    type: str
    code: Optional[str] = None
    file_url: Optional[str] = None
    config: Dict = {}

    class Config:
        from_attributes = True

class WidgetCreateScheme(BaseModel):
    name: str
    type: str
    config: Dict = {}
    code: Optional[str] = None
    file_url: Optional[str] = None

class PageCreateScheme(BaseModel):
    name: str
    order: int
    widgets: List[WidgetCreateScheme] = []

class PageViewScheme(BaseModel):
    id: int
    name: str
    order: int
    widgets: List[WidgetViewScheme] = []

    class Config:
        from_attributes = True

class WidgetUpdateScheme(BaseModel):
    name: Optional[str] = None
    type: Optional[str] = None
    code: Optional[str] = None
    file_url: Optional[str] = None

class ProjectCreateScheme(BaseModel):
    name: str
    rules: Dict
    pages: List[PageCreateScheme] = []
    user_id: int

class ProjectViewScheme(BaseModel):
    id: int
    name: str
    rules: Dict
    pages: List[PageViewScheme] = []

    class Config:
        from_attributes = True


class ProjectUpdateScheme(BaseModel):
    name: Optional[str] = None
    rules: Optional[Dict] = None
    widgets: Optional[List[WidgetCreateScheme]] = None  # перезапись виджетов (если нужно)


async def create_project_crud(session: AsyncSession, project_in: ProjectCreateScheme) -> ProjectViewScheme:
    try:
        project = Project(name=project_in.name, rules=project_in.rules, user_id=project_in.user_id)
        session.add(project)
        await session.flush()  # нужно до создания связанных объектов

        for page_data in project_in.pages:
            page = Page(name=page_data.name, order=page_data.order, project=project)
            session.add(page)
            await session.flush()

            for widget_data in page_data.widgets:
                widget = Widget(
                    name=widget_data.name,
                    type=widget_data.type,
                    config=widget_data.config,
                    code=widget_data.code,
                    file_url=widget_data.file_url,
                    page=page
                )
                session.add(widget)

        await session.commit()
        await session.refresh(project)

        return await get_project_by_id_crud(session, project.id)

    except Exception as e:
        print(f"Ошибка при создании проекта: {e}")
        await session.rollback()
        raise HTTPException(status_code=500, detail="Ошибка при создании проекта")

async def update_project_crud(session: AsyncSession, project_id: int, project_data: ProjectUpdateScheme):
    result = await session.execute(
        select(Project)
        .options(selectinload(Project.pages).selectinload(Page.widgets))
        .where(Project.id == project_id)
    )
    project = result.scalars().first()

    if not project:
        raise HTTPException(status_code=404, detail="Проект не найден")

    if project_data.name:
        project.name = project_data.name

    if project_data.rules is not None:
        project.rules = project_data.rules

    if project_data.widgets is not None:
        project.pages.clear()

        page = Page(name="Main", order=0, project=project)

        for w_data in project_data.widgets:
            widget = Widget(
                name=w_data.name,
                type=w_data.type,
                config=w_data.config,
                code=w_data.code,
                file_url=w_data.file_url,
                page=page
            )
            session.add(widget)

        project.pages.append(page)

    await session.commit()
    await session.refresh(project)

    return ProjectViewScheme(
        id=project.id,
        name=project.name,
        rules=project.rules,
        pages=[
            PageViewScheme(
                id=page.id,
                name=page.name,
                order=page.order,
                widgets=[
                    WidgetViewScheme(
                        id=widget.id,
                        name=widget.name,
                        type=widget.type,
                        config=widget.config,
                        code=widget.code,
                        file_url=widget.file_url,
                    )
                    for widget in page.widgets
                ]
            )
            for page in project.pages
        ]
    )


async def get_projects_crud(session: AsyncSession) -> List[ProjectViewScheme]:
    result = await session.execute(select(Project))
    projects = result.scalars().all()
    return [ProjectViewScheme(id=p.id, name=p.name, rules=p.rules) for p in projects]


async def get_project_by_id_crud(session: AsyncSession, project_id: int) -> ProjectViewScheme:
    result = await session.execute(
        select(Project)
        .options(selectinload(Project.pages).selectinload(Page.widgets))
        .where(Project.id == project_id)
    )
    project = result.scalars().first()

    if not project:
        raise HTTPException(status_code=404, detail="Проект не найден")

    return ProjectViewScheme(
        id=project.id,
        name=project.name,
        rules=project.rules,
        pages=[
            PageViewScheme(
                id=page.id,
                name=page.name,
                order=page.order,
                widgets=[
                    WidgetViewScheme(
                        id=w.id,
                        name=w.name,
                        type=w.type,
                        config=w.config,
                        code=w.code,
                        file_url=w.file_url
                    )
                    for w in page.widgets
                ]
            )
            for page in project.pages
        ]
    )


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

    if widget_data.name is not None:
        widget.name = widget_data.name
    if widget_data.type is not None:
        widget.type = widget_data.type
    if widget_data.config is not None:
        widget.config = widget_data.config
    if widget_data.file_url is not None:
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


@router.get("/api/projects/user/{user_id}")
async def get_user_projects(user_id: int, db: AsyncSession = Depends(db_helper.scoped_session_dependency)):
    result = await db.execute(select(Project).where(Project.user_id == user_id))
    projects = result.scalars().all()

    return [
        {
            "id": project.id,
            "name": project.name,
            "rules": project.rules,
            #"created_at": project.created_at.isoformat(),
        }
        for project in projects
    ]

@router.post("/projects/", response_model=ProjectViewScheme)
async def create_project(project_in: ProjectCreateScheme, db: AsyncSession = Depends(db_helper.scoped_session_dependency)):
    return await create_project_crud(session=db, project_in=project_in)

@router.put("/projects/{project_id}/", response_model=ProjectViewScheme)
async def update_project(project_id: int, project_data: ProjectUpdateScheme, db: AsyncSession = Depends(db_helper.scoped_session_dependency)):
    return await update_project_crud(session=db, project_id=project_id, project_data=project_data)


@router.get("/projects/", response_model=List[ProjectViewScheme])
async def get_project(db: AsyncSession = Depends(db_helper.scoped_session_dependency)):
    return await get_projects_crud(session=db,)

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


def get_authorization_header(request: Request) -> str:
    auth = request.headers.get("Authorization")
    if not auth:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing Authorization header")
    return auth

# Функция для проверки наличия токена в запросе
async def get_user_from_token(
        authorization: str = Depends(get_authorization_header),
):
    # Проверяем, начинается ли токен с "Bearer "
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token format")

    # Извлекаем сам токен из заголовка
    token = authorization.split(" ")[1]

    # Логируем для отладки
    print(f"Received token: {token}")

    # Просто возвращаем токен без декодирования
    return token

# Функция, проверяющая наличие токена в запросе
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="login-by-token")

# Функция для проверки наличия токена через OAuth2
def get_token(token: str = Depends(oauth2_scheme)):
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token is missing",
        )
    return token
# Роут для логина/создания пользователя
class TokenRequest(BaseModel):
    phone: str

@router.post("/login-by-token")
async def login_by_token(
        request: TokenRequest,  # Получаем данные через модель Pydantic
        token: str = Depends(get_token),
        session: AsyncSession = Depends(db_helper.scoped_session_dependency)
):
    phone = request.phone  # Получаем номер телефона из тела запроса

    # Получаем токен, но сам токен не проверяется на сервере
    received_token = await get_user_from_token(authorization=f"Bearer {token}")

    # Логируем токен для отладки
    print(f"Received token: {received_token}")

    try:
        # Ищем пользователя по номеру телефона
        result = await session.execute(select(User).where(User.phone == phone))
        user = result.scalar_one_or_none()

        if user:
            # Логируем информацию о найденном пользователе
            print(f"Found user: {user}")
            print(f"User ID: {user.id}")
        else:
            # Если пользователя не найдено, создаём нового
            print("User not found, creating new user")
            user = User(phone=phone)
            session.add(user)
            await session.commit()
            print(f"Created new user: {user}")

        # Возвращаем user_id
        return JSONResponse(content={"user_id": user.id}, status_code=status.HTTP_200_OK)

    except jwt.JWTError as e:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")