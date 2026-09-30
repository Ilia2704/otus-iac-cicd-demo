import os
import sys
import time

import httpx

BASE_URL = os.environ["APP_URL"].rstrip("/")

CASES = [
    ("This is good.", "POSITIVE"),
    ("This is bad.", "NEGATIVE"),
]


def wait_for_health():
    for _ in range(30):
        try:
            r = httpx.get(f"{BASE_URL}/health", timeout=5)
            if r.status_code == 200:
                return
        except httpx.HTTPError:
            pass
        time.sleep(2)
    raise RuntimeError("Application did not become healthy")


def main():
    wait_for_health()
    for text, expected in CASES:
        r = httpx.post(f"{BASE_URL}/sentiment", json={"text": text}, timeout=90)
        r.raise_for_status()
        got = r.json()["label"]
        print(f"{text!r} -> {got} (expected {expected})")
        if got != expected:
            print(f"Expected {expected}, got {got}", file=sys.stderr)
            raise SystemExit(1)


if __name__ == "__main__":
    main()
