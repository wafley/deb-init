import questionary
from .logger import console

def show_main_menu():
    """Displays the selection menu using the arrow keys."""
    choices = [
        "1. Basic System Setup",
        "2. Development Environment",
        "3. Desktop & UI",
        "4. General Settings",
        "5. Additional Tools",
        "6. Run All (Full Setup)",
        questionary.Separator(), # Boundary lines to keep things neat
        "0. Keluar"
    ]
    
    answer = questionary.select(
        "Pilih modul yang ingin dijalankan:",
        choices=choices,
        use_arrow_keys=True,
        style=questionary.Style([
            ('qmark', 'fg:#673ab7 bold'),       # Question mark color
            ('question', 'bold'),               # Question color
            ('answer', 'fg:#f44336 bold'),      # Selected answer color
            ('pointer', 'fg:#673ab7 bold'),     # Color of the pointer arrow
            ('highlighted', 'fg:#673ab7 bold'), # Text color when highlighted
            ('selected', 'fg:#cc5454'),         # Color when selected
        ])
    ).ask()
    
    return answer