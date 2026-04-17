import sys
from rich.panel import Panel
from utils.logger import console
from utils.menu import show_main_menu
from utils.config_loader import get_config

# Modules
from modules.basic import BasicSetup

class DebianOrchestrator:
    def __init__(self):
        # Get app data from settings.yaml
        # Use .get() to be safe if the key is not in the YAML
        self.config = get_config("app").get('app', {})
        self.version = self.config.get('version', '0.0.0')
        self.name = self.config.get('name', 'Debian Automator')
        self.description = self.config.get('description', 'Automation tool')

    def display_banner(self):
        # Render entry banner with version
        console.print(Panel(
            f"[bold white]{self.name}[/bold white]\n"
            f"[dim]{self.description}[/dim]",
            title = f"[success]v{self.version}[/success]",
            border_style = "blue",
            expand = False
        ))

    def handle_choice(self, choice):
        """Dispatch menu selection."""

        # Exit condition
        if choice == "Quit" or choice is None:
            console.print("[warn]Exiting. See you![/warn]")
            sys.exit(0)

        # Log selected action
        console.print(f"\n[info]Executing:[/info] [bold]{choice}[/bold]\n")

        try:
            # Naive routing based on label prefix
            if "Basic System Setup" in choice:
                setup = BasicSetup()
                setup.run()
            elif "2." in choice:
                pass
            elif "3." in choice:
                pass
            elif "4." in choice:
                pass
            elif "5." in choice:
                pass
            elif "6." in choice:
                pass

            # Success path
            console.print("\n✔ Task completed!\n")
            sys.exit(0)

        except Exception:
            # Generic failure handler
            console.print(f"\n[error]Failed to run {choice}[/error]")

    def start(self):
        # Main event loop
        while True:
            self.display_banner()
            choice = show_main_menu()
            self.handle_choice(choice)

if __name__ == "__main__":
    # Bootstrap entrypoint
    orchestrator = DebianOrchestrator()
    orchestrator.start()