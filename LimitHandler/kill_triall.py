#!/usr/bin/env python3




##### BASE : LUNATIC TUNNELING x GPT #####

# Lunatic Tunneling | Dian Permana
# Saguling | Jawa Barat | Bandung Barat | Indonesia
# Contact | wa.me/6283197765857



import os
import sys
import subprocess
from datetime import datetime

# === Path Configuration ===
XRAY_CONFIG = "/etc/xray/config.json"

# DB paths
SSH_DB = "/etc/lunatic/ssh/.ssh.db"
VMESS_DB = "/etc/lunatic/vmess/.vmess.db"
VLESS_DB = "/etc/lunatic/vless/.vless.db"
TROJAN_DB = "/etc/lunatic/trojan/.trojan.db"

LOG_FILE = "/var/log/trial_kill.log"

# === Telegram Notif Function ===
def send_telegram(message):
    try:
        with open("/etc/lunatic/bot/notif/key") as f:
            key = f.read().strip()
        with open("/etc/lunatic/bot/notif/id") as f:
            chat_id = f.read().strip()

        if not key or not chat_id:
            return

        text = f"<code>[Expired]</code> {message}"
        cmd = [
            "curl", "-s", "-X", "POST",
            f"https://api.telegram.org/bot{key}/sendMessage",
            "-d", f"chat_id={chat_id}",
            "-d", f"text={text}",
            "-d", "parse_mode=HTML"
        ]
        subprocess.run(cmd, stdout=subprocess.DEVNULL)
    except Exception as e:
        print(f"[ERROR] Telegram notification failed: {e}")

# === Utility Functions ===
def restart_service(service):
    subprocess.run(["systemctl", "restart", service], stdout=subprocess.DEVNULL)

def remove_files(file_list):
    for f in file_list:
        if os.path.exists(f):
            os.remove(f)

def get_expiry_from_db(user, db_path):
    if os.path.exists(db_path):
        with open(db_path, "r") as f:
            for line in f:
                if line.startswith("###") and user in line:
                    parts = line.strip().split()
                    if len(parts) >= 3:
                        return parts[2]
    return None

def log_deletion(user, mode):
    with open(LOG_FILE, "a") as logf:
        logf.write(f"{datetime.now().strftime('%Y-%m-%d %H:%M:%S')} - Deleted {user} from {mode}\n")

# === Deletion Functions ===

def delssh(user):
    print(f"[INFO] Menghapus akun SSH: {user}")
    subprocess.run(["pkill", "-u", user], stdout=subprocess.DEVNULL)
    subprocess.run(["userdel", "-r", user], stdout=subprocess.DEVNULL)
    remove_files([
        f"/etc/lunatic/ssh/ip/{user}",
        f"/etc/lunatic/ssh/{user}",
        f"/etc/lunatic/detail/ssh/{user}.txt",
        f"/var/www/html/ssh-{user}.txt"
    ])
    subprocess.run(["sed", "-i", f"/^#ssh# {user} /d", SSH_DB])
    for svc in ["ssh", "dropbear", "ws"]:
        restart_service(svc)
    send_telegram(f"""
<code>=============================</code>
<code>      TRIALL SSHOPENVPN      </code>
<code>=============================</code>
<code> USERNAME : {user}           </code>
<code> STATUS   : EXPIRED          </code>
<code>=============================</code>""")
    log_deletion(user, "ssh")

def delvmess(user, exp):
    print(f"[INFO] Menghapus akun VMESS: {user}")
    subprocess.run(["sed", "-i", f"/^#vmeACC# {user} {exp}/,/^}},{{/d", XRAY_CONFIG])
    subprocess.run(["sed", "-i", f"/^#vmeACC# {user} {exp}/d", XRAY_CONFIG])
    remove_files([
        f"/etc/lunatic/vmess/usage/{user}",
        f"/etc/lunatic/vmess/ip/{user}",
        f"/etc/lunatic/vmess/{user}",
        f"/etc/lunatic/vmess/detail/{user}.txt",
        f"/var/www/html/vme-{user}.txt"
    ])
    subprocess.run(["sed", "-i", f"/^### {user} {exp}/d", VMESS_DB])
    restart_service("xray")
    send_telegram(f"""
<code>=============================</code>
<code>        TRIALL VMESS         </code>
<code>=============================</code>
<code> USERNAME : {user}           </code>
<code> STATUS   : EXPIRED          </code>
<code>=============================</code>""")
    log_deletion(user, "vmess")

def delvless(user, exp):
    print(f"[INFO] Menghapus akun VLESS: {user}")
    subprocess.run(["sed", "-i", f"/^#vleACC# {user} {exp}/,/^}},{{/d", XRAY_CONFIG])
    remove_files([
        f"/etc/lunatic/vless/usage/{user}",
        f"/etc/lunatic/vless/ip/{user}",
        f"/etc/lunatic/vless/detail/{user}.txt",
        f"/var/www/html/vle-{user}.txt"
    ])
    subprocess.run(["sed", "-i", f"/^### {user} {exp}/d", VLESS_DB])
    restart_service("xray")
    send_telegram(f"""
<code>=============================</code>
<code>        TRIALL VLESS         </code>
<code>=============================</code>
<code> USERNAME : {user}           </code>
<code> STATUS   : EXPIRED          </code>
<code>=============================</code>""")
    log_deletion(user, "vless")

def deltrojan(user, exp):
    print(f"[INFO] Menghapus akun TROJAN: {user}")
    subprocess.run(["sed", "-i", f"/^#troACC# {user} {exp}/,/^}},{{/d", XRAY_CONFIG])
    remove_files([
        f"/etc/lunatic/trojan/usage/{user}",
        f"/etc/lunatic/trojan/ip/{user}",
        f"/etc/lunatic/trojan/detail/{user}.txt",
        f"/var/www/html/tro-{user}.txt"
    ])
    subprocess.run(["sed", "-i", f"/^### {user} {exp}/d", TROJAN_DB])
    restart_service("xray")
    send_telegram(f"""
<code>=============================</code>
<code>       TRIALL TROJAN         </code>
<code>=============================</code>
<code> USERNAME : {user}           </code>
<code> STATUS   : EXPIRED          </code>
<code>=============================</code>""")
    log_deletion(user, "trojan")

# === Main Execution ===
if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: kill_triall.py <mode> <username>")
        sys.exit(1)

    mode = sys.argv[1]
    user = sys.argv[2]

    if mode == "ssh_dell":
        delssh(user)
    elif mode == "vme_dell":
        exp = get_expiry_from_db(user, VMESS_DB)
        if exp:
            delvmess(user, exp)
    elif mode == "vle_dell":
        exp = get_expiry_from_db(user, VLESS_DB)
        if exp:
            delvless(user, exp)
    elif mode == "tro_dell":
        exp = get_expiry_from_db(user, TROJAN_DB)
        if exp:
            deltrojan(user, exp)
    else:
        print("Unknown mode:", mode)
        sys.exit(1)