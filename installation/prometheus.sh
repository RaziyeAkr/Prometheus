#!/bin/bash
#set variables
RED="\033[0;31m"
YELLOW="\033[0;33m"
GREEN="\033[0;32m"
NC="\033[0m"
BLUE="\033[0;34m"
IP=$(hostname -I | awk '{print $1}')
CONFIG_PATH="/etc/prometheus"
#pre install works
echo -e "${BLUE}Installing JQ package for java script view.${NC}"
dnf install jq -y  > /dev/null
echo -e "${BLUE}Finish installing.${NC}"
sleep 5
echo "We need to set some works before start to manage."
echo -e "${RED}Channging hostname and timezone${NC}."
hostnamectl set-hostname "monitoring server"
timedatectl set-timezone Asia/Tehran
sleep 5
##########################################
echo -e "${RED}Create prometheus User and Dependency for prometheus.${NC}"
useradd -r -s /sbin/nologin prometheus
mkdir /var/lib/prometheus
mkdir /etc/prometheus
chown -R prometheus: /etc/prometheus
chown -R prometheus: /var/lib/prometheus
sleep 5
###########################################
echo -e "${BLUE}Getting prometheus binary file frome github.${NC}"
LATEST=$(curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest | jq -r '.tag_name')
echo -e "${GREEN}Latest prometheus version detected: ${LATEST}${NC}"
URL=$(curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest \
  | jq -r '.assets[] | select(.name | test("linux-amd64\\.tar\\.gz$")) | .browser_download_url')
cd /home
mkdir prometheus/
cd prometheus/
wget -q --show-progress ${URL} -O prometheus.tar.gz
tar -xzf prometheus.tar.gz
cd prometheus-*
cp prometheus promtool /usr/local/bin
cp -a console* $CONFIG_PATH
sleep 5
#########################################
echo -e "${YELLOW}Writing configs in prometheus yaml.${NC}"
tee ${CONFIG_PATH}/prometheus.yml > /dev/null << EOF
global:
  scrape_interval: 10s

scrape_configs:
  - job_name: 'Prometheus Server'
    static_configs:
      - targets: ['${IP}:9090']
EOF
sleep 5
#########################################
echo -e "${RED}Writing service file.${NC}"
sudo tee /usr/lib/systemd/system/prometheus.service > /dev/null << EOF
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
--config.file /etc/prometheus/prometheus.yml \
--storage.tsdb.path /var/lib/prometheus/ \
--web.console.templates=/etc/prometheus/consoles \
--web.console.libraries=/etc/prometheus/console_libraries
ExecReload=/usr/bin/kill -HUP $MAINPID

[Install]
WantedBy=multi-user.target
EOF
#############################
echo -e "${RED}Reload daemon.${NC}"
systemctl daemon-reload
echo -e "${YELLOW}Start prometheus service.${NC}"
systemctl start prometheus.service
systemctl enable prometheus.service
##############################
echo -e "${GREEN}Congrtulation! you have prometheus monitoring.${NC}"
systemctl status prometheus.service --no-pager
