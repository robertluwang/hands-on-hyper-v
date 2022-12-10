# update & upgrade

sudo apt update -y
sudo apt upgrade -y 

# check nested vt enabled for kvm 

VMX=$(egrep -c '(vmx|svm)' /proc/cpuinfo)

if $VMX = 0 
then
    echo "Please enable nested VT on host, exit!"
fi 

# kvm install 

sudo apt install -y qemu-kvm libvirt-daemon-system virtinst libvirt-clients bridge-utils
sudo systemctl enable libvirtd
sudo systemctl start libvirtd
sudo systemctl status libvirtd

# add login user to group of kvm, libvirt

sudo usermod -aG kvm $USER
sudo usermod -aG libvirt $USER

