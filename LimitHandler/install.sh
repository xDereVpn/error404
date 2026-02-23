#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
set -e

echo "✅ Downloading monitor_quota.py..."
wget -O /usr/bin/monitor_quota.py https://raw.githubusercontent.com/xDereVpn/error404/main/LimitHandler/monitor_quota.py

echo "✅ Downloading monitor_autokill.py..."
wget -O /usr/bin/monitor_autokill.py https://raw.githubusercontent.com/xDereVpn/error404/main/LimitHandler/monitor_autokill.py

echo "✅ Downloading autodelete.py..."
wget -O /usr/bin/autodelete.py https://raw.githubusercontent.com/xDereVpn/error404/main/LimitHandler/autodelete.py

echo "✅ Downloading kill_triall.py..."
wget -O /usr/bin/kill_triall.py https://raw.githubusercontent.com/xDereVpn/error404/main/LimitHandler/kill_triall.py
wget -O /usr/bin/check_triall_expired.py https://raw.githubusercontent.com/xDereVpn/error404/main/LimitHandler/check_triall_expired.py

chmod +x /usr/bin/monitor_quota.py
chmod +x /usr/bin/monitor_autokill.py
chmod +x /usr/bin/autodelete.py
chmod +x /usr/bin/kill_triall.py
chmod +x /usr/bin/check_triall_expired.py

touch /var/log/lunatic_quota_monitor.log
chmod 644 /var/log/lunatic_quota_monitor.log

############################################
# SERVICE MONITOR
############################################

cat > /etc/systemd/system/monitor-quota.service <<-EOF
[Unit]
Description=Auto Monitor Xray Quota & Device
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/env python3 /usr/bin/monitor_quota.py
Restart=always
RestartSec=10
StandardOutput=append:/var/log/lunatic_quota_monitor.log
StandardError=append:/var/log/lunatic_quota_monitor.log

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/monitor-autokill.service <<-EOF
[Unit]
Description=AutoKill IP Limit for XRAY/SSH Users
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /usr/bin/monitor_autokill.py
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

############################################
# ====== BAGIAN DIPERBAIKI: AUTODELETE ======
############################################

# SERVICE AUTODELETE (ONESHOOT)
cat > /etc/systemd/system/autodelete.service <<-EOF
[Unit]
Description=Auto Delete Expired Xray & SSH Accounts
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/bin/python3 /etc/lunatic/autodelete.py
EOF

# TIMER AUTODELETE (INI YANG BENAR)
cat > /etc/systemd/system/autodelete.timer <<-EOF
[Unit]
Description=Daily Auto Delete Expired Accounts

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
EOF

############################################
# AKTIFKAN SEMUA SERVICE
############################################

echo "🚀 Mengaktifkan service..."
systemctl daemon-reload

# QUOTA MONITOR
systemctl enable monitor-quota
systemctl restart monitor-quota

# AUTOKILL
systemctl enable monitor-autokill
systemctl restart monitor-autokill

# AUTODELETE (FIXED)
systemctl enable autodelete.timer
systemctl start autodelete.timer

echo "✅ Instalasi selesai!"
echo "🔍 Cek timer dengan: systemctl list-timers | grep autodelete"