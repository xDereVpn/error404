#!/usr/bin/env bash

set -euo pipefail
YELLOW='\033[1;33m'
RED='\033[0;31m'
LIGHT_BLUE='\033[1;36m'
BOLD_WHITE='\033[1;37m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
LIGHT_GREEN='\033[1;32m'
NC='\033[0m' # No Color

# LICENSE IP
LICENSE_URL="https://raw.githubusercontent.com/xDereVpn/permission/main/regist"
LICENSE_INFO_FILE="/etc/zivpn/.license_info"

# Link Download Bin amd64
BIN_URL="https://github.com/arivpnstores/udp-zivpn/releases/download/zahidbd2/udp-zivpn-linux-amd64"

# Link Download config.json
CFG_URL="https://raw.githubusercontent.com/xDereVpn/error404/main/udpzivpn/config.json"

# Path Bin amd64
BIN_PATH="/usr/local/bin/zivpn"

# Directory Config udp zivpn
CFG_DIR="/etc/zivpn"
CFG_PATH="${CFG_DIR}/config.json"
KEY_PATH="${CFG_DIR}/zivpn.key"
CRT_PATH="${CFG_DIR}/zivpn.crt"

# Port udp # Ufw / Dnat
UDP_LISTEN_PORT="5667"
DNAT_FROM_MIN="6000"
DNAT_FROM_MAX="19999"

# ============================
# 1️⃣ Update server
# ============================
echo "[1/9] Update server"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y

# ============================
# 2️⃣ Stop service if exists
# ============================
echo "[2/9] Stop service if exists"
systemctl stop zivpn.service 2>/dev/null || true

# ============================
# 3️⃣ Install/Update binary & config
# ============================
echo "[3/9] Install/Update binary & config"

# Pastikan tidak ada folder/file lama yang conflict
if [ -d "$BIN_PATH" ]; then
    echo "Folder $BIN_PATH ditemukan, menghapus..."
    rm -rf "$BIN_PATH"
elif [ -f "$BIN_PATH" ]; then
    echo "File $BIN_PATH ditemukan, menghapus..."
    rm -f "$BIN_PATH"
fi

mkdir -p "${CFG_DIR}"

# Download binary menggunakan curl
echo "Downloading binary..."
curl -sSL "${BIN_URL}" -o "${BIN_PATH}"
chmod +x "${BIN_PATH}"

# Download config menggunakan curl
echo "Downloading config..."
curl -sSL "${CFG_URL}" -o "${CFG_PATH}"

# ============================
# 4️⃣ Generate cert files (if missing)
# ============================
echo "[4/9] Generate cert files (if missing)"
if [[ ! -f "${KEY_PATH}" || ! -f "${CRT_PATH}" ]]; then
openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
-subj "/C=US/ST=California/L=Los Angeles/O=Example Corp/OU=IT Department/CN=zivpn" \
-keyout "${KEY_PATH}" -out "${CRT_PATH}"
fi

# ============================
# 5️⃣ Persist sysctl
# ============================
echo "[5/9] Persist sysctl (so it survives reboot)"
cat >/etc/sysctl.d/99-zivpn-udp.conf <<EOF
net.core.rmem_max=16777216
net.core.wmem_max=16777216
EOF
sysctl --system >/dev/null

# ============================
# 6️⃣ Force password config to ["zi"]
# ============================
echo "[6/9] Force password config to [\"zi\"]"
sed -i -E 's/"config"[[:space:]]*:[[:space:]]*\[[^]]*\]/"config": ["zi"]/g' "${CFG_PATH}"

# ============================
# 7️⃣ Create systemd service
# ============================
echo "[7/9] Create systemd service (wait network online)"
cat >/etc/systemd/system/zivpn.service <<EOF
[Unit]
Description=zivpn VPN Server
Wants=network-online.target
After=network-online.target
StartLimitIntervalSec=0
[Service]
Type=simple
User=root
WorkingDirectory=${CFG_DIR}
ExecStartPre=/bin/sh -c 'test -s "${CFG_PATH}" && test -s "${KEY_PATH}" && test -s "${CRT_PATH}"'
ExecStart=${BIN_PATH} server -c ${CFG_PATH}
Restart=on-failure
RestartSec=3
Environment=ZIVPN_LOG_LEVEL=info
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=true
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable zivpn.service >/dev/null

# ============================
# 8️⃣ Persist NAT rule
# ============================
echo "[8/9] Persist NAT rule across reboot (iptables-persistent)"
apt-get install -y iptables-persistent >/dev/null
DEF_IF="$(ip -4 route ls | awk '/default/ {print $5; exit}')"
if [[ -z "${DEF_IF}" ]]; then
    echo "❌ Gagal mendeteksi interface default. Cek: ip -4 route"
    exit 1
fi
if ! iptables -t nat -C PREROUTING -i "${DEF_IF}" -p udp --dport "${DNAT_FROM_MIN}:${DNAT_FROM_MAX}" -j DNAT --to-destination ":${UDP_LISTEN_PORT}" 2>/dev/null; then
    iptables -t nat -A PREROUTING -i "${DEF_IF}" -p udp --dport "${DNAT_FROM_MIN}:${DNAT_FROM_MAX}" -j DNAT --to-destination ":${UDP_LISTEN_PORT}"
fi
iptables-save > /etc/iptables/rules.v4

# ============================
# 9️⃣ UFW rules + start service
# ============================
echo "[9/9] UFW rules (optional) + start service"
if command -v ufw >/dev/null 2>&1; then
    ufw allow "${DNAT_FROM_MIN}:${DNAT_FROM_MAX}/udp" >/dev/null || true
    ufw allow "${UDP_LISTEN_PORT}/udp" >/dev/null || true
fi
systemctl restart zivpn.service

echo ""
echo "✅ ZIVPN UDP Installed & reboot-safe"
echo "- Service: systemctl status zivpn --no-pager"
echo "- Interface detected: ${DEF_IF}"
echo "- DNAT UDP ${DNAT_FROM_MIN}-${DNAT_FROM_MAX} -> :${UDP_LISTEN_PORT}"