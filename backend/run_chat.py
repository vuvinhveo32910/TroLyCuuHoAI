"""Run one local chat service. Runtime data and model weights stay outside Git."""
import runpy
import sys
from local_config import load_config

HERE = load_config()
sys.path.insert(0, str(HERE / 'medgemma'))
runpy.run_path(str(HERE / 'medgemma' / 'server.py'), run_name='__main__')
