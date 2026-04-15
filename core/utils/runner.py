import subprocess
from rich.progress import Progress, SpinnerColumn, TextColumn
from .logger import console

def run_task(description, command):
    """Execute shell commands with a stylish spinner."""
    with Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}"),
        transient=True,
    ) as progress:
        task_id = progress.add_task(
            description=f"[info]{description}...[/info]",
            total=None
        )

        try:
            process = subprocess.run(
                command,
                shell=True,
                check=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )

            progress.stop_task(task_id)
            progress.remove_task(task_id)

            console.print(f"[success]\n✔[/success] {description}")
            return process.stdout

        except subprocess.CalledProcessError as e:
            progress.stop_task(task_id)
            progress.remove_task(task_id)

            console.print(f"[error]\n✘[/error] Failed: {description}")
            if e.stderr:
                console.print(f"[dim red]{e.stderr.strip()}[/dim red]")
            raise