# coding: utf-8

"""
    RxInferServer OpenAPI specification

    API for RxInferServer.jl - A Julia server for RxInfer probabilistic programming framework

    The version of the OpenAPI document: 1.0.0
    Generated by OpenAPI Generator (https://openapi-generator.tech)

    Do not edit the class manually.
"""  # noqa: E501


from __future__ import annotations
import pprint
import re  # noqa: F401
import json

from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field, StrictStr
from typing import Any, ClassVar, Dict, List
from typing import Optional, Set
from typing_extensions import Self

class CreatedModelInfo(BaseModel):
    """
    CreatedModelInfo
    """ # noqa: E501
    model_id: StrictStr = Field(description="Unique identifier for the created model instance")
    model_name: StrictStr = Field(description="Name of the model (including version identifier if applicable, e.g. \"BetaBernoulli-v1\")")
    created_at: datetime = Field(description="Timestamp of when the model was created")
    description: StrictStr = Field(description="Description of the created model instance")
    arguments: Dict[str, Any] = Field(description="Model-specific configuration arguments")
    current_episode: StrictStr = Field(description="Name of the current episode for this model")
    __properties: ClassVar[List[str]] = ["model_id", "model_name", "created_at", "description", "arguments", "current_episode"]

    model_config = ConfigDict(
        populate_by_name=True,
        validate_assignment=True,
        protected_namespaces=(),
    )


    def to_str(self) -> str:
        """Returns the string representation of the model using alias"""
        return pprint.pformat(self.model_dump(by_alias=True))

    def to_json(self) -> str:
        """Returns the JSON representation of the model using alias"""
        # TODO: pydantic v2: use .model_dump_json(by_alias=True, exclude_unset=True) instead
        return json.dumps(self.to_dict())

    @classmethod
    def from_json(cls, json_str: str) -> Optional[Self]:
        """Create an instance of CreatedModelInfo from a JSON string"""
        return cls.from_dict(json.loads(json_str))

    def to_dict(self) -> Dict[str, Any]:
        """Return the dictionary representation of the model using alias.

        This has the following differences from calling pydantic's
        `self.model_dump(by_alias=True)`:

        * `None` is only added to the output dict for nullable fields that
          were set at model initialization. Other fields with value `None`
          are ignored.
        """
        excluded_fields: Set[str] = set([
        ])

        _dict = self.model_dump(
            by_alias=True,
            exclude=excluded_fields,
            exclude_none=True,
        )
        return _dict

    @classmethod
    def from_dict(cls, obj: Optional[Dict[str, Any]]) -> Optional[Self]:
        """Create an instance of CreatedModelInfo from a dict"""
        if obj is None:
            return None

        if not isinstance(obj, dict):
            return cls.model_validate(obj)

        _obj = cls.model_validate({
            "model_id": obj.get("model_id"),
            "model_name": obj.get("model_name"),
            "created_at": obj.get("created_at"),
            "description": obj.get("description"),
            "arguments": obj.get("arguments"),
            "current_episode": obj.get("current_episode")
        })
        return _obj


