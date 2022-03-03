SCRIPR_DIR=$(cd $(dirname $0);pwd)
####apt update upgrade####
echo '====apt update upgrade===='
sudo apt update -y
sudo apt upgrade -y
sudo apt autoremove

sudo apt install -y pigpio python3-pigpio
sudo apt install -y python-tk
sudo apt install -y git
sudo apt install -y hostapd dnsmasq iptables-persistent

