import subprocess
from rich.progress import Progress, SpinnerColumn, TextColumn
from .logger import console

def run_task(description, command):
    """Run a command with a loading spinner."""

    # Start a progress spinner
    with Progress(
        SpinnerColumn(),
        TextColumn("{task.description}"),
        transient=True,
    ) as progress:
        # Create a task (no progress bar, just spinner)
        task_id = progress.add_task(
            description = f"{description}...",
            total = None
        )

        try:
            # Run the command
            process = subprocess.run(
                command,
                shell = True,
                check = True,
                stdout = subprocess.PIPE,
                stderr = subprocess.PIPE,
                text = True
            )

            # Stop and remove spinner after success
            progress.stop_task(task_id)
            progress.remove_task(task_id)

            # Show success message
            console.print(f"✔ {description}")

            # Return command output
            return process.stdout

        except subprocess.CalledProcessError as e:
            # Stop and remove spinner if error happens
            progress.stop_task(task_id)
            progress.remove_task(task_id)

            # Show error message
            console.print(f"✘ Failed: {description}")

            # Show error details if available
            if e.stderr:
                console.print(e.stderr.strip())

            raise