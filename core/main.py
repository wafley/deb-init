import sys
from rich.panel import Panel
from utils.logger import console
from utils.menu import show_main_menu
from utils.runner import run_task

class DebianOrchestrator:
    def __init__(self):
        self.version = "1.0.0"

    def display_banner(self):
        console.print(Panel(
            "[bold white]Debian 13 Python Orchestrator[/bold white]\n"
            "[dim]Select a module to begin the automation process[/dim]",
            title="[success]v" + self.version + "[/success]",
            border_style="blue",
            expand=False
        ))

    def handle_choice(self, choice):
        """Logic to handle each menu option."""
        if choice == "0. Keluar" or choice is None:
            console.print("[warn]Exiting. See you![/warn]")
            sys.exit(0)
            
        console.print(f"\n[info]Executing:[/info] [bold]{choice}[/bold]\n")

        try:
            if "1." in choice:
                pass
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
            
            console.print("\n[success]✔ Task completed![/success]\n")
            sys.exit(0)
        except Exception as e:
            console.print(f"\n[error]Gagal menjalankan {choice}[/error]")

    def start(self):
        while True:
            self.display_banner()
            choice = show_main_menu()
            self.handle_choice(choice)

if __name__ == "__main__":
    orchestrator = DebianOrchestrator()
    orchestrator.start()