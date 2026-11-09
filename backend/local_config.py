"""Read local paths without loading any model or starting a listener."""
import os
from pathlib import Path


def load_config():
    backend = Path(__file__).resolve().parent
    config = backend / '.env.local'
    if config.is_file():
        for line in config.read_text(encoding='utf-8-sig').splitlines():
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            key, separator, value = line.partition('=')
            if separator and key.strip().startswith('MEDGEMMA_'):
                os.environ.setdefault(key.strip(), value.strip().strip('"').strip("'"))
    # A fresh clone can share the sibling model directory without bundling weights.
    os.environ.setdefault('MEDGEMMA_MODEL_PATH', str(backend.parent.parent / 'medgemma-1.5-4b-it'))
    os.environ.setdefault('HF_HUB_OFFLINE', '1')
    os.environ.setdefault('HF_DEACTIVATE_ASYNC_LOAD', '1')
    return backend
