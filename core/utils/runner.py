import subprocess
from rich.progress import Progress, SpinnerColumn, TextColumn
from .logger import console


def run_task(description, command, show_output=False):
    """Run a command with a clean CLI-style spinner."""

    with Progress(
        SpinnerColumn(),
        TextColumn("{task.description}"),
        transient=True,  # 👈 penting: hilangkan jejak spinner
        console=console,
    ) as progress:

        task_id = progress.add_task(f"{description}...", total=None)

        try:
            result = subprocess.run(
                command,
                shell=True,
                check=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
            )

        except subprocess.CalledProcessError as e:
            # Spinner otomatis hilang karena transient=True
            console.print(f"[red]✘ Failed:[/red] {description}")

            if e.stderr:
                console.print(e.stderr.strip())

            raise

    # 👇 keluar dari `with` = spinner sudah bersih
    console.print(f"[green]✔[/green] {description}")

    if show_output and result.stdout:
        console.print(result.stdout.rstrip())

    return result.stdout