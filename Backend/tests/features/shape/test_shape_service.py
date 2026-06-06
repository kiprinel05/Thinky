"""Tests for ShapeService with the ML model mocked."""
from unittest.mock import MagicMock

import pytest

from features.shape.service import ShapeService


@pytest.fixture
def service():
    # Skip __init__ (which loads the real ShapeModel from disk) and inject a mock.
    svc = ShapeService.__new__(ShapeService)
    svc.model = MagicMock()
    return svc


def test_predict_delegates_to_model(service):
    service.model.predict.return_value = "triangle"
    assert service.predict(b"fake bytes") == "triangle"
    service.model.predict.assert_called_once_with(b"fake bytes")
