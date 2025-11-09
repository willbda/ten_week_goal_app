"""
Simple configuration - loads paths from config.toml
"""

from pathlib import Path
import sys
import tomllib

# Project root
PROJECT_ROOT = Path(__file__).parent.parent

# Load config.toml
config_path = PROJECT_ROOT / "config" / "config.toml"
with open(config_path, "rb") as f:
    config = tomllib.load(f)

# Storage paths
STORAGE_DIR = PROJECT_ROOT / config["storage"]["data_dir"]
DB_PATH = STORAGE_DIR / config["storage"]["db_name"]
SCHEMA_PATH = PROJECT_ROOT / config["storage"]["schema_dir"]

# Logging
LOG_DIR = PROJECT_ROOT / config["logging"]["log_dir"]
LOG_LEVEL = config["logging"]["level"]

# Ensure directories exist
STORAGE_DIR.mkdir(parents=True, exist_ok=True)
LOG_DIR.mkdir(parents=True, exist_ok=True)
