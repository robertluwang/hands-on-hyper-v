# nat-eth0.sh
# handy script to setup static ip on hyper-v ubuntu vm
# By Robert Wang @github.com/robertluwang
# Dec 10, 2022
# $1 - static ip on NAT hyper-v switch

echo === $(date) Provisioning - nat-eth0 $1 by $(whoami) start  

SUBNET=$(echo $1 | cut -d"." -f1-3)

cat <<EOF | sudo tee /etc/netplan/01-netcfg.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no
      dhcp6: no
      addresses: [$1/24]
      routes:
      - to: default
        via: ${SUBNET}.1
      nameservers:
        addresses: [8.8.8.8,1.1.1.1]
EOF

sudo unlink /etc/resolv.conf
sudo rm /etc/resolv.conf
cat << EOF | sudo tee /etc/resolv.conf 
nameserver 8.8.8.8
nameserver 1.1.1.1
EOF

sudo chattr +i /etc/resolv.conf

cat /etc/netplan/01-netcfg.yaml
cat /etc/resolv.conf

sudo netplan apply

echo eth0 setting

ip addr
ip route
ping -c 2 google.ca

echo === $(date) Provisioning - nat-eth0 $1 by $(whoami) end