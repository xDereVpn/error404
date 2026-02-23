#!/usr/bin/env python3



##### BASE : LUNATIC TUNNELING x GPT #####

# Lunatic Tunneling | Dian Permana
# Saguling | Jawa Barat | Bandung Barat | Indonesia
# Contact | wa.me/6283197765857



from datetime import datetime
import subprocess

# Semua mode dan DB path
db_list = {
    "vmess": "/etc/lunatic/vmess/.vmess.db",
    "vless": "/etc/lunatic/vless/.vless.db",
    "trojan": "/etc/lunatic/trojan/.trojan.db",
    "ssh": "/etc/lunatic/ssh/.ssh.db"
}

kill_script = "/usr/bin/kill_triall.py"
today = datetime.now().strftime("%Y-%m-%d")

for mode, db_path in db_list.items():
    if not os.path.exists(db_path):
        continue
    with open(db_path) as f:
        for line in f:
            if line.startswith("###") or line.startswith("#ssh#"):
                parts = line.strip().split()
                if mode == "ssh":
                    username = parts[1]
                    exp = parts[4]
                else:
                    username = parts[1]
                    exp = parts[2]
                try:
                    if datetime.strptime(exp, "%Y-%m-%d") <= datetime.now():
                        subprocess.run(["python3", kill_script, f"{mode}_dell", username])
                except Exception:
                    continue