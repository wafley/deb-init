import yaml
import os
from .logger import console

def get_config(filename):
    """
    Generic loader for reading any YAML file inside the /config folder.
    Usage: get_config("settings") -> read config/settings.yaml
    """
    base_path = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
    config_path = os.path.join(base_path, "config", f"{filename}.yaml")

    if not os.path.exists(config_path):
        # We use log warn so that it doesn't crash immediately if the optional file is missing.
        return {}

    try:
        with open(config_path, 'r') as file:
            data = yaml.safe_load(file)
            return data if data else {}
    except Exception as e:
        console.print(f"[error]Failed to load config '{filename}': {e}[/error]")
        return {}

# Pre-load the main configuration for immediate use.
settings = get_config("settings")