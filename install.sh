#!/bin/sh

if [ "$(whoami)" != "root" ]; then
  echo Script must be run as root
  exit 1
fi

systemctl disable --now apt-automatic-full-upgrade.timer 2>/dev/null

cat << EOF > /etc/systemd/system/apt-automatic-full-upgrade.service
[Unit]
Description=Auto upgrade all apt packages
After=network-online.target
Wants=network-online.target
[Service]
Type=oneshot
User=root
ExecStart=apt-get update --yes --quiet=2
ExecStart=apt-get full-upgrade --yes --quiet
ExecStart=apt-get dist-upgrade --yes --quiet
ExecStart=apt-get autoremove --yes --quiet
ExecStart=apt-get clean --yes --quiet=2
ExecStart=apt-get autoclean --yes --quiet=2
EOF

cat << EOF > /etc/systemd/system/apt-automatic-full-upgrade.timer
[Unit]
Description=Auto upgrade all apt packages
[Timer]
OnCalendar=*-*-* 01:00:00
RandomizedDelaySec=4h
Persistent=true
[Install]
WantedBy=timers.target
EOF

cat << EOF > /usr/local/bin/uninstall-apt-automatic-full-upgrade.sh
#!/bin/sh
if [ "\$(whoami)" != "root" ]; then
  echo Script must be run as root
  exit 1
fi
systemctl disable --now apt-automatic-full-upgrade.timer 2>/dev/null
rm /etc/systemd/system/apt-automatic-full-upgrade.service
rm /etc/systemd/system/apt-automatic-full-upgrade.timer
systemctl daemon-reload 2>/dev/null
rm /usr/local/bin/uninstall-apt-automatic-full-upgrade.sh
EOF
chmod +x /usr/local/bin/uninstall-apt-automatic-full-upgrade.sh

systemctl daemon-reload
systemctl enable --now apt-automatic-full-upgrade.timer 2>/dev/null
