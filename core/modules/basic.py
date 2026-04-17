import os
import configparser
from utils.config_loader import get_config
from utils.runner import run_task
from utils.logger import console

class BasicSetup:
    def __init__(self):
        self.config = get_config("packages")
        self.home = os.path.expanduser("~")
        self.font_dir = os.path.join(self.home, ".local/share/fonts")
        self.kde_config_path = os.path.join(self.home, ".config/kdeglobals")

    def install_packages(self):
        """Install APT packages (Core & Additional)."""
        basic = self.config.get("basic", {})
        packages = basic.get("core_packages", []) + basic.get("additional_packages", [])
        
        if packages:
            run_task("Updating APT index", "sudo apt-get update -y")
            run_task(
                f"Installing {len(packages)} system packages", 
                f"sudo apt-get install -y {' '.join(packages)}"
            )

    def setup_ssh(self):
        """Setup SSH Server."""
        run_task("Installing OpenSSH Server", "sudo apt-get install -y openssh-server")
        run_task("Enabling SSH service", "sudo systemctl enable --now ssh")
    
    def setup_regional(self):
        """Setup Timezone & Locale."""
        basic = self.config.get("basic", {})
        tz = basic.get("timezone", "UTC")
        loc = basic.get("locale", "en_US.UTF-8")

        run_task(
            f"Setting timezone to {tz}",
            f"sudo timedatectl set-timezone {tz}"
        )

        run_task(
            f"Generating locale {loc}",
            f"sudo locale-gen {loc}"
        )

        run_task(
            f"Setting default locale",
            f"sudo update-locale LANG={loc}"
        )

    def install_fonts(self):
        """Instalasi Fonts."""
        fonts = self.config.get("basic", {}).get("fonts", [])
        if not fonts:
            return

        os.makedirs(self.font_dir, exist_ok=True)
        console.print("[info]➔ Downloading and installing fonts...[/info]")

        for font in fonts:
            name = font.get("name")
            url = font.get("url")
            
            if not url:
                console.print(f"[warn]Skip {name}: URL is empty[/warn]")
                continue

            target_path = os.path.join(self.font_dir, name)
            
            if not os.path.exists(target_path):
                tmp_zip = f"/tmp/{name}.zip"
                # Using curl -L to handle redirects from GitHub
                run_task(
                    f"Downloading {name}",
                    f"curl -L '{url}' -o {tmp_zip}"
                )
                
                if os.path.exists(tmp_zip):
                    os.makedirs(target_path, exist_ok=True)
                    run_task(
                        f"Extracting {name}",
                        f"unzip -o {tmp_zip} -d {target_path}"
                    )
                    os.remove(tmp_zip)

        run_task("Updating font cache", "fc-cache -fv")

    def run(self):
        console.print("[info]Executing Basic System Setup...[/info]")
        self.install_packages()
        self.setup_ssh()
        self.setup_regional()
        self.install_fonts()
        console.print("[success]✔ Basic Setup completed successfully![/success]")