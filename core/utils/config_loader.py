import yaml
import os
from .logger import console

def get_config(filename):
    # Get the absolute path of this file (config_loader.py)
    current_file_path = os.path.abspath(__file__)
    
    # Go up 2 levels: utils -> core -> root
    # Use chained os.path.dirname to be more explicit
    utils_dir = os.path.dirname(current_file_path)
    core_dir = os.path.dirname(utils_dir)
    project_root = os.path.dirname(core_dir)
    
    config_path = os.path.join(project_root, "config", f"{filename}.yaml")

    # DEBUG: Enable this just once to see where Python is looking
    # console.print(f"[dim]DEBUG: Looking for {filename} at {config_path}[/dim]")

    if not os.path.exists(config_path):
        # If the file is missing, don't just keep quiet, tell us where it is.
        console.print(f"[warn]Config missing: {config_path}[/warn]")
        return {}

    try:
        with open(config_path, 'r', encoding='utf-8') as file:
            data = yaml.safe_load(file)
            return data if data else {}
    except Exception as e:
        console.print(f"[error]Failed to load config '{filename}': {e}[/error]")
        return {}