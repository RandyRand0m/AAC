import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from api.api import router as project_router

app = FastAPI()


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class ProjectCreate(BaseModel):
    name: str
    rules: dict

projects = []

app.include_router(project_router, prefix="/api")
# @app.post("/projects/")
# async def create_project(project: ProjectCreate):
#     projects.append(project)
#     return {"message": "Проект сохранен", "project": project}
# 
#
# @app.get("/projects/")
# async def get_projects():
#     return {"projects": projects}

if __name__ == "__main__":
    uvicorn.run(app, host="localhost", port=9096)