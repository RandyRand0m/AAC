from typing import List, Dict, Optional
from pydantic import BaseModel, field_validator, ValidationError, Field

class WidgetViewScheme(BaseModel):
    id: int
    category_id: Optional[int] = None
    metadata: Dict = Field(default_factory=dict)

    @field_validator('metadata', mode='before')
    def validate_metadata(cls, v):
        if v is None:
            return {}
        if hasattr(v, 'dict'):
            return v.dict()
        if hasattr(v, '__dict__'):
            return vars(v)
        if isinstance(v, dict):
            return v
        return {}

    class Config:
        from_attributes = True

class WidgetCreateScheme(BaseModel):
    category_id: int
    metadata: Dict = Field(default_factory=dict)

class PageCreateScheme(BaseModel):
    title: str
    page_id: int
    required_categories: Optional[List[int]] = None
    widgetsList: List[WidgetCreateScheme] = []

class PageViewScheme(BaseModel):
    id: int
    title: str
    # icon: Optional[str] = None
    widgetsList: List[WidgetViewScheme] = []

    class Config:
        from_attributes = True

class ProjectCreateScheme(BaseModel):
    name: str
    theme: str = "light"
    template: str = "Фитнес-Клуб"
    navBarType: int = 0
    fontFamily: str = "Montserrat"
    pages: List[PageCreateScheme] = []
    user_id: int

class ProjectViewScheme(BaseModel):
    id: int
    name: str
    colorScheme: str
    fontFamily: str
    navBarType: int
    pages: List[PageViewScheme] = []

    class Config:
        from_attributes = True

class WidgetUpdateScheme(BaseModel):
    id: int
    category_id: int
    metadata: Dict = Field(default_factory=dict)

class PageUpdateScheme(BaseModel):
    id: int
    title: str
    widgetsList: List[WidgetUpdateScheme]

class ProjectUpdateScheme(BaseModel):
    name: Optional[str] = None
    theme: Optional[str] = None
    fontFamily: Optional[str] = None
    navBarType: Optional[int] = None
    pages: Optional[List[PageUpdateScheme]] = None  


