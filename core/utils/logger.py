from rich.console import Console
from rich.theme import Theme

custom_theme = Theme({
    "info": "bold blue",
    "success": "bold green",
    "warn": "bold yellow",
    "error": "bold red",
    "highlight": "bold magenta"
})

console = Console(theme = custom_theme)