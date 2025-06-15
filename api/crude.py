from typing import List, Dict, Optional
from sqlalchemy import delete
from sqlalchemy.orm import selectinload
from api.scheme import ProjectCreateScheme, ProjectViewScheme, ProjectUpdateScheme, PageViewScheme, WidgetViewScheme, \
    WidgetCreateScheme, WidgetUpdateScheme
from core.models import db_helper, Project, Widget, Page, User
from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

async def create_project_crud(session: AsyncSession, project_in: ProjectCreateScheme) -> ProjectViewScheme:
    try:
        project = Project(
            name=project_in.name,
            theme=project_in.theme,
            template=project_in.template,
            navBarType=project_in.navBarType,
            fontFamily=project_in.fontFamily,
            user_id=project_in.user_id
        )
        session.add(project)
        await session.flush()

        for page_data in project_in.pages:
            page = Page(
                page_id=page_data.page_id,
                title=page_data.title,
                required_categories=page_data.required_categories,
                project=project
            )
            session.add(page)
            await session.flush()

            for widget_data in page_data.widgetsList:
                # Ensure metadata is always a dictionary
                metadata = widget_data.metadata if hasattr(widget_data, 'metadata') and isinstance(widget_data.metadata, dict) else {}
                widget = Widget(
                    category_id=widget_data.category_id if hasattr(widget_data, 'category_id') else 0,
                    config=metadata,  # Use the ensured dictionary
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

    # Update basic project info
    if project_data.name:
        project.name = project_data.name
    if project_data.theme:
        project.theme = project_data.theme
    if project_data.fontFamily:
        project.fontFamily = project_data.fontFamily
    if project_data.navBarType is not None:
        project.navBarType = project_data.navBarType

    if project_data.pages is not None:
        # Clear existing pages and widgets
        for page in project.pages:
            await session.delete(page)
        await session.flush()

        # Add new pages and widgets
        for page_data in project_data.pages:
            page = Page(
                id=page_data.id,
                title=page_data.title,
                project=project
            )
            session.add(page)
            await session.flush()

            for widget_data in page_data.widgetsList:
                widget = Widget(
                    id=widget_data.id,
                    category_id=widget_data.category_id,
                    config=widget_data.metadata,
                    page=page
                )
                session.add(widget)

    await session.commit()
    await session.refresh(project)

    return await get_project_by_id_crud(session, project.id)

async def get_projects_crud(session: AsyncSession) -> List[ProjectViewScheme]:
    result = await session.execute(select(Project))
    projects = result.scalars().all()
    return [
        ProjectViewScheme(
            id=p.id,
            name=p.name,
            colorScheme=p.theme,
            fontFamily=p.fontFamily,
            navBarType=p.navBarType,
            pages=[]
        )
        for p in projects
    ]

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
        colorScheme=project.theme,
        fontFamily=project.fontFamily,
        navBarType=project.navBarType,
        pages=[
            PageViewScheme(
                id=page.id,
                title=page.title,
                widgetsList=[
                    WidgetViewScheme(
                        id=widget.id,
                        metadata=widget.config if hasattr(widget, 'config') else {},
                        category_id=widget.category_id if hasattr(widget, 'category_id') else None
                    )
                    for widget in page.widgets
                ]
            )
            for page in project.pages
        ]
    )

async def delete_project_crud(session: AsyncSession, project_id: int):
    result = await session.execute(
        select(Project)
        .options(
            selectinload(Project.pages)
            .selectinload(Page.widgets)
        )
        .where(Project.id == project_id)
    )
    project = result.scalars().first()

    if not project:
        raise HTTPException(status_code=404, detail="Проект не найден")

    try:
        for page in project.pages:
            for widget in page.widgets:
                await session.delete(widget)
            await session.flush()

        for page in project.pages:
            await session.delete(page)
        await session.flush()

        await session.delete(project)
        await session.commit()

        return {"message": "Проект удален"}
    except Exception as e:
        await session.rollback()
        print(f"Ошибка при удалении проекта: {e}")
        raise HTTPException(status_code=500, detail="Ошибка при удалении проекта")

async def create_widget_crud(session: AsyncSession, widget_in: WidgetCreateScheme) -> WidgetViewScheme:
    widget = Widget(
        name=widget_in.name,
        type=widget_in.type,
        config=widget_in.config if isinstance(widget_in.config, dict) else {},
        file_url=widget_in.file_url
    )
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
        widget.config = widget_data.config if isinstance(widget_data.config, dict) else {}
    if widget_data.file_url is not None:
        widget.file_url = widget_data.file_url
    await session.commit()
    await session.refresh(widget)

    return WidgetViewScheme(id=widget.id, name=widget.name, type=widget.type, config=widget.config, file_url=widget.file_url)

async def get_widgets_crud(session: AsyncSession) -> List[WidgetViewScheme]:
    result = await session.execute(select(Widget))
    widgets = result.scalars().all()
    return [WidgetViewScheme(id=w.id, name=w.name, type=w.type, metadata=w.config, file_url=w.file_url) for w in widgets]

async def get_widget_by_id_crud(session: AsyncSession, widget_id: int) -> WidgetViewScheme:
    result = await session.execute(select(Widget).where(Widget.id == widget_id))
    widget = result.scalars().first()

    if not widget:
        raise HTTPException(status_code=404, detail="Виджет не найден")

    return WidgetViewScheme(id=widget.id, name=widget.name, type=widget.type, config=widget.config, file_url=widget.file_url)

async def delete_widget_crud(session: AsyncSession, widget_id: int):
    result = await session.execute(
        select(Widget)
        .where(Widget.id == widget_id)
    )
    widget = result.scalars().first()

    if not widget:
        raise HTTPException(status_code=404, detail="Виджет не найден")

    try:
        await session.delete(widget)
        await session.commit()
        return {"message": "Виджет удален"}
    except Exception as e:
        await session.rollback()
        print(f"Ошибка при удалении виджета: {e}")
        raise HTTPException(status_code=500, detail="Ошибка при удалении виджета")
