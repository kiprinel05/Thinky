"""Tests for ColorService with the ML model mocked."""
from unittest.mock import MagicMock

import pytest

from features.color.service import ColorService


@pytest.fixture
def service():
    svc = ColorService.__new__(ColorService)
    svc.model = MagicMock()
    return svc


def test_predict_normalises_rgb_to_unit_range(service):
    service.model.predict.return_value = "red"

    result = service.predict(r=255, g=0, b=128)

    assert result == "red"
    # Service contract: RGB is normalised to [0, 1] before reaching the model.
    expected_input = [255 / 255.0, 0 / 255.0, 128 / 255.0]
    service.model.predict.assert_called_once_with(expected_input)


def test_zero_rgb_passes_zero_vector(service):
    service.model.predict.return_value = "black"
    service.predict(0, 0, 0)
    service.model.predict.assert_called_once_with([0.0, 0.0, 0.0])
