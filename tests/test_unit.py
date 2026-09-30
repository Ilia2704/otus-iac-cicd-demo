import importlib.util
from pathlib import Path

from fastapi.testclient import TestClient

APP_FILE = Path(__file__).parents[1] / "app" / "main.py"
spec = importlib.util.spec_from_file_location("sentiment_app", APP_FILE)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
client = TestClient(module.app)


def test_health():
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_normalize_positive():
    assert module.normalize_label("POSITIVE") == "POSITIVE"


def test_normalize_negative_from_extra_text():
    assert module.normalize_label("The answer is negative.") == "NEGATIVE"


def test_normalize_rejects_unknown_output():
    try:
        module.normalize_label("MIXED")
    except ValueError:
        return
    raise AssertionError("ValueError expected")
