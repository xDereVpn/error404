#!/usr/bin/env python3

import os
import json
import subprocess
from datetime import datetime
import pytz
import requests

# ====== KONFIGURASI ======
XRAY_CONFIG = "/etc/xray/config.json"
WIB = pytz.timezone('Asia/Jakarta')
TODAY = datetime.now(WIB).date()
JAM_SEKARANG = datetime.now(WIB).strftime("%d-%m-%Y %H:%M WIB")

SERVICES = ["xray", "nginx"]

TELEGRAM_TOKEN = "GANTI_TOKEN_BOT_KAMU"  # Ganti dari @BotFather
TELEGRAM_CHAT_ID = "GANTI_CHAT_ID_KAMU"  # Ganti dari @userinfobot
# =========================

ACCOUNTS = {
    "vmess": {
        "db": "/etc/lunatic/vmess/.vmess.db",
        "tag": "#vmeACC#",
        "ip": "/etc/lunatic/vmess/ip",
        "usage": "/etc/lunatic/vmess/usage",
        "detail": "/etc/lunatic/vmess/detail"
    },
    "vless": {
        "db": "/etc/lunatic/vless/.vless.db",
        "tag": "#vleACC#",
        "ip": "/etc/lunatic/vless/ip",
        "usage": "/etc/lunatic/vless/usage",
        "detail": "/etc/lunatic/vless/detail"
    },
    "trojan": {
        "db": "/etc/lunatic/trojan/.trojan.db",
        "tag": "#troACC#",
        "ip": "/etc/lunatic/trojan/ip",
        "usage": "/etc/lunatic/trojan/usage",
        "detail": "/etc/lunatic/trojan/detail"
    }
}

SSH_DB = "/etc/lunatic/ssh/.ssh.db"
DELETED_USERS = {"vmess": [], "vless": [], "trojan": [], "ssh": []}

def kirim_telegram(pesan):
    if TELEGRAM_TOKEN == "GANTI_TOKEN_BOT_KAMU":
        return
    url = f"https://api.telegram.org/bot{TELEGRAM_TOKEN}/sendMessage"
    data = {
        "chat_id": TELEGRAM_CHAT_ID,
        "text": pesan,
        "parse_mode": "HTML"
    }
    try:
        requests.post(url, data=data, timeout=10)
    except:
        pass

def restart_services():
    for svc in SERVICES:
        subprocess.run(["systemctl", "restart", svc],
                       stdout=subprocess.DEVNULL,
                       stderr=subprocess.DEVNULL)

def remove_file(path):
    if os.path.exists(path):
        os.remove(path)

def delete_xray_user(username, tag):
    with open(XRAY_CONFIG) as f:
        lines = f.readlines()

    new = []
    skip = False

    for line in lines:
        if tag in line and username in line:
            skip = True
            continue
