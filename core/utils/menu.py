import questionary

def show_main_menu():
    """Displays the selection menu using the arrow keys."""
    choices = [
        "Basic System Setup",
        "Development Environment",
        "Desktop & UI",
        "General Settings",
        "Additional Tools",
        "Run All (Full Setup)",
        questionary.Separator(), # Boundary lines to keep things neat
        "Quit"
    ]
    
    answer = questionary.select(
        "Select the module you want to run:",
        choices = choices,
        use_arrow_keys = True,
        style = questionary.Style([
            ('qmark', 'fg:#673ab7 bold'),       # Question mark color
            ('question', 'bold'),               # Question color
            ('answer', 'fg:#00ff00 bold'),      # Selected answer color
            ('pointer', 'fg:#673ab7 bold'),     # Color of the pointer arrow
            ('highlighted', 'fg:#673ab7 bold'), # Text color when highlighted
            ('selected', 'fg:#00ff00'),         # Color when selected
        ])
    ).ask()
    
    return answer