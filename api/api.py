from typing import List, Dict, Optional
from fastapi.security import OAuth2PasswordBearer
from pydantic import BaseModel, field_validator, ValidationError, Field
from rest_framework import status
from sqlalchemy import delete
from sqlalchemy.orm import selectinload
from starlette.responses import JSONResponse

from api.crude import create_project_crud, update_project_crud, get_projects_crud, get_project_by_id_crud, \
    delete_project_crud, create_widget_crud, update_widget_crud, get_widgets_crud, get_widget_by_id_crud, \
    delete_widget_crud
from api.scheme import ProjectCreateScheme, ProjectViewScheme, ProjectUpdateScheme, PageViewScheme, WidgetViewScheme, \
    WidgetCreateScheme, WidgetUpdateScheme
from core.models import db_helper, Project, Widget, Page, User

from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from jose import jwt, JWTError
from core.models import  User
from core.models.coremodels import Verification

router = APIRouter()
router.tags = ["Name"]

SECRET_KEY = "366c5edb4f534d2c702004aaf6f9aa294d1b21fa068bed1cbe1e371a06aa8633"
ALGORITHM = "HS256"

@router.get("/api/projects/user/{user_id}")
async def get_user_projects(user_id: int, db: AsyncSession = Depends(db_helper.scoped_session_dependency)):
    result = await db.execute(
        select(Project)
        .where(Project.user_id == user_id)
        .options(
            selectinload(Project.pages).selectinload(Page.widgets)
    ))
    projects = result.scalars().all()

    # Преобразуем проекты в список словарей
    projects_data = []
    for project in projects:
        project_data = {
            "id": project.id,
            "name": project.name,
            "colorScheme": project.theme,
            "fontFamily": project.fontFamily,
            "navBarType": project.navBarType,
            "pages": []
        }
        for page in project.pages:
            page_data = {
                "id": page.id,

                "title": page.title,
                "widgetsList": [
                    {"id": widget.id, "metadata": widget.config}  # Используем widget.config вместо widget.metadata
                    for widget in page.widgets
                ]
            }
            project_data["pages"].append(page_data)
        projects_data.append(project_data)

    return projects_data

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

def decode_jwt_token(token: str) -> dict:
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except JWTError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")

async def get_current_user(
    token: str = Depends(OAuth2PasswordBearer(tokenUrl="/api/login-by-token")),
    session: AsyncSession = Depends(db_helper.scoped_session_dependency),
) -> User:
    payload = decode_jwt_token(token)
    phone = payload.get("phone")

    if not phone:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token payload")

    result = await session.execute(select(User).where(User.phone == phone))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    return user

def get_authorization_header(request: Request) -> str:
    auth = request.headers.get("Authorization")
    if not auth:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing Authorization header")
    return auth

async def get_user_from_token(
        authorization: str = Depends(get_authorization_header),
):
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token format")

    token = authorization.split(" ")[1]

    print(f"Received token: {token}")

    return token

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="login-by-token")

def get_token(token: str = Depends(oauth2_scheme)):
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token is missing",
        )
    return token

class TokenRequest(BaseModel):
    phone: str

class VerificationSchema(BaseModel):
    phone_number: str = Field(alias="phone")

    class Config:
        allow_population_by_field_name = True

@router.post("/login-by-token")
async def login_by_token(
    request: VerificationSchema,
    session: AsyncSession = Depends(db_helper.scoped_session_dependency),
):
    phone = request.phone_number

    result = await session.execute(select(User).where(User.phone == phone))
    user = result.scalar_one_or_none()
    if not user:
        user = User(phone=phone)
        session.add(user)
        await session.commit()
        await session.refresh(user)

    # Создаём токен
    token_data = {"phone": user.phone}
    access_token = jwt.encode(token_data, SECRET_KEY, algorithm=ALGORITHM)

    return {"access_token": access_token, "token_type": "bearer", "user_id": user.id,}