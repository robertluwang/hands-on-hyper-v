# hyper-v vagrant
Vagrant supports hyper-v as provider.

There is not private network option in hyper-v Vagrantfile, best effort is to setup a static NAT network, run provision script to setup vm network after hyper-v vm up.

## hyper-v Vagrantfile
```
$nic = <<SCRIPT

echo === $(date) Provisioning - nic $1 by $(whoami) start  

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

echo === $(date) Provisioning - nic $1 by $(whoami) end

SCRIPT

Vagrant.configure("2") do |config|
  config.vm.box = "roboxes/ubuntu2204"
  config.ssh.insert_key = false
  config.vm.box_check_update = false

  config.vm.define "master" do |master|
      master.vm.hostname = "master"
      master.vm.provider "hyperv" do |v|
          v.vmname = "master"
          v.memory = 2048
          v.cpus = 1
      end
      master.vm.provision "shell", inline: $nic, args: "192.168.80.30", privileged: false
  end
end
```
pre-condition is static NAT switch with network 192.168.80.0/24 on host pc,
```
Ethernet adapter vEthernet (myNATSW):

   Connection-specific DNS Suffix  . : 
   Description . . . . . . . . . . . : Hyper-V Virtual Ethernet Adapter
   Physical Address. . . . . . . . . : 00-15-5D-17-01-04
   DHCP Enabled. . . . . . . . . . . : No
   Autoconfiguration Enabled . . . . : Yes
   Link-local IPv6 Address . . . . . : fe80::831a:b50c:82bc:cb35%17(Preferred) 
   IPv4 Address. . . . . . . . . . . : 192.168.80.1(Preferred) 
   Subnet Mask . . . . . . . . . . . : 255.255.255.0
```
## vagrant hyper needs admin right
you have to run vagrant for hyper-v as admin, 
```
oldhorse@wsl2:/mnt/c/tools/vagrant/ub2204$ vagrant.exe up --provider hyperv
The provider 'hyperv' that was requested to back the machine
'master' is reporting that it isn't usable on this system. The
reason is shown below:

The Hyper-V provider requires that Vagrant be run with
administrative privileges. This is a limitation of Hyper-V itself.
Hyper-V requires administrative privileges for management
commands. Please restart your console with administrative
privileges and try again.
```
strange PS as admin not work, only works to run cmd as admin, 
```
vagrant up --provider hyperv
```
launched smoothly, 
```
C:\tools\vagrant\ub2204>vagrant up --provider hyperv                                                              Bringing machine 'master' up with 'hyperv' provider...                                                                     ==> master: Verifying Hyper-V is enabled...                                                                                ==> master: Verifying Hyper-V is accessible...                                                                             ==> master: Box 'roboxes/ubuntu2204' could not be found. Attempting to find and install...
    master: Box Provider: hyperv
    master: Box Version: >= 0
==> master: Loading metadata for box 'roboxes/ubuntu2204'
    master: URL: https://vagrantcloud.com/roboxes/ubuntu2204
==> master: Adding box 'roboxes/ubuntu2204' (v4.2.4) for provider: hyperv
    master: Downloading: https://vagrantcloud.com/roboxes/boxes/ubuntu2204/versions/4.2.4/providers/hyperv.box
    master:
    master: Calculating and comparing box checksum...
==> master: Successfully added box 'roboxes/ubuntu2204' (v4.2.4) for 'hyperv'!
==> master: Importing a Hyper-V instance
    master: Creating and registering the VM...
    master: Successfully imported VM
    master: Please choose a switch to attach to your Hyper-V instance.
    master: If none of these are appropriate, please open the Hyper-V manager
    master: to create a new virtual switch.
    master:
    master: 1) myNATSW
    master: 2) Default Switch
    master: 3) WSL
    master:
    master: What switch would you like to use? 1
    master: Configuring the VM...
    master: Setting VM Enhanced session transport type to disabled/default (VMBus)
==> master: Starting the machine...
==> master: Waiting for the machine to report its IP address...
    master: Timeout: 120 seconds
    master: IP: fe80::215:5dff:fe17:106
==> master: Waiting for machine to boot. This may take a few minutes...
    master: SSH address: fe80::215:5dff:fe17:106:22
    master: SSH username: vagrant
    master: SSH auth method: private key
==> master: Machine booted and ready!
==> master: Setting hostname...
==> master: Running provisioner: shell...
    master: Running: inline script
    master: === Sat Nov 26 05:41:38 PM UTC 2022 Provisioning - nic 192.168.80.30 by vagrant start
    master: network:
    master:   version: 2
    master:   renderer: networkd
    master:   ethernets:
    master:     eth0:
    master:       dhcp4: no
    master:       dhcp6: no
    master:       addresses: [192.168.80.30/24]
    master:       routes:
    master:       - to: default
    master:         via: 192.168.80.1
    master:       nameservers:
    master:         addresses: [8.8.8.8,1.1.1.1]
    master: nameserver 8.8.8.8
    master: nameserver 1.1.1.1
    master: network:
    master:   version: 2
    master:   renderer: networkd
    master:   ethernets:
    master:     eth0:
    master:       dhcp4: no
    master:       dhcp6: no
    master:       addresses: [192.168.80.30/24]
    master:       routes:
    master:       - to: default
    master:         via: 192.168.80.1
    master:       nameservers:
    master:         addresses: [8.8.8.8,1.1.1.1]
    master: nameserver 8.8.8.8
    master: nameserver 1.1.1.1
    master: eth0 setting
    master: 1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    master:     link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    master:     inet 127.0.0.1/8 scope host lo
    master:        valid_lft forever preferred_lft forever
    master: 2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    master:     link/ether 00:15:5d:17:01:06 brd ff:ff:ff:ff:ff:ff
    master:     inet 192.168.80.30/24 brd 192.168.80.255 scope global eth0
    master:        valid_lft forever preferred_lft forever
    master:     inet6 fe80::215:5dff:fe17:106/64 scope link
    master:        valid_lft forever preferred_lft forever
    master: default via 192.168.80.1 dev eth0 proto static
    master: 192.168.80.0/24 dev eth0 proto kernel scope link src 192.168.80.30
    master: PING google.ca (172.217.165.131) 56(84) bytes of data.
    master: 64 bytes from lax30s03-in-f3.1e100.net (172.217.165.131): icmp_seq=1 ttl=108 time=43.5 ms
    master: 64 bytes from lax30s03-in-f3.1e100.net (172.217.165.131): icmp_seq=2 ttl=108 time=23.4 ms
    master:
    master: --- google.ca ping statistics ---
    master: 2 packets transmitted, 2 received, 0% packet loss, time 1002ms
    master: rtt min/avg/max/mdev = 23.419/33.461/43.503/10.042 ms
    master: === Sat Nov 26 05:41:40 PM UTC 2022 Provisioning - nic 192.168.80.30 by vagrant end
```
check hyper-v vm working good, 
```
C:\tools\vagrant\ub2204>vagrant status
Current machine states:

master                    running (hyperv)


C:\tools\vagrant\ub2204>vagrant ssh
vagrant@master:~$ ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 00:15:5d:17:01:06 brd ff:ff:ff:ff:ff:ff
    inet 192.168.80.30/24 brd 192.168.80.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::215:5dff:fe17:106/64 scope link
       valid_lft forever preferred_lft forever
vagrant@master:~$ ip route
default via 192.168.80.1 dev eth0 proto static
192.168.80.0/24 dev eth0 proto kernel scope link src 192.168.80.30
vagrant@master:~$ cat /etc/resolv.conf
nameserver 8.8.8.8
nameserver 1.1.1.1
vagrant@master:~$ ping google.ca
PING google.ca (172.217.165.131) 56(84) bytes of data.
64 bytes from lax30s03-in-f3.1e100.net (172.217.165.131): icmp_seq=1 ttl=108 time=22.3 ms
```
## vm communication in myNATSW network 
from hyper-v vm to vagrant hyper-v vm, 
```
oldhorse@dclab:~/tools$ ping 192.168.80.30
PING 192.168.80.30 (192.168.80.30) 56(84) bytes of data.
64 bytes from 192.168.80.30: icmp_seq=1 ttl=64 time=1.33 ms
64 bytes from 192.168.80.30: icmp_seq=2 ttl=64 time=0.491 ms
```
from vagrant hyper-v vm to hyper-v vm,
```
vagrant@master:~$ ping 192.168.80.20
PING 192.168.80.20 (192.168.80.20) 56(84) bytes of data.
64 bytes from 192.168.80.20: icmp_seq=1 ttl=64 time=0.543 ms
```
from vagrant hyper-v vm to host,
```
vagrant@master:~$ ping 192.168.80.1
PING 192.168.80.1 (192.168.80.1) 56(84) bytes of data.
64 bytes from 192.168.80.1: icmp_seq=1 ttl=128 time=0.712 ms
64 bytes from 192.168.80.1: icmp_seq=2 ttl=128 time=0.519 ms
```
from host to vagrant hyper-v vm, 
```
oldhorse@wsl:~$ ping 192.168.80.20
PING 192.168.80.20 (192.168.80.20) 56(84) bytes of data.
64 bytes from 192.168.80.20: icmp_seq=1 ttl=64 time=0.684 ms
```

## vagrant vm timezone

setup correct timezone on vm, 

```
sudo timedatectl set-timezone America/Montreal
```

add line to Vagrantfile for each node, 

```
master.vm.provision "shell", inline: "sudo timedatectl set-timezone America/Montreal", privileged: false, run: "always"
```



