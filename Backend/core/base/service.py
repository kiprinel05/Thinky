from typing import Generic, TypeVar, Type, List, Optional, Any
from core.base.repository import BaseRepository, ModelType, CreateSchemaType, UpdateSchemaType

RepositoryType = TypeVar("RepositoryType", bound=BaseRepository)

class BaseService(Generic[ModelType, CreateSchemaType, UpdateSchemaType]):
    def __init__(self, repository: BaseRepository[ModelType, CreateSchemaType, UpdateSchemaType]):
        self.repository = repository

    def get(self, id: Any) -> Optional[ModelType]:
        return self.repository.get(id)

    def get_multi(self, skip: int = 0, limit: int = 100) -> List[ModelType]:
        return self.repository.get_multi(skip, limit)

    def create(self, obj_in: CreateSchemaType) -> ModelType:
        return self.repository.create(obj_in)

    def update(self, id: Any, obj_in: UpdateSchemaType) -> Optional[ModelType]:
        db_obj = self.repository.get(id)
        if not db_obj:
            return None
        return self.repository.update(db_obj, obj_in)

    def delete(self, id: Any) -> Optional[ModelType]:
        db_obj = self.repository.get(id)
        if not db_obj:
            return None
        return self.repository.delete(id)
