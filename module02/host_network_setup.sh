#! /bin/bash -x
vbmg () { VBoxManage.exe "$@"; }
vbmg natnetwork add --netname net_4640 --network "192.168.250.0/24" --enable --dhcp off
vbmg natnetwork modify --netname net_4640 --port-forward-4 "ssh:tcp:[]:50022:[192.168.250.10]:22"
vbmg natnetwork modify --netname net_4640 --port-forward-4 "http:tcp:[]:50080:[192.168.250.10]:80"
vbmg natnetwork modify --netname net_4640 --port-forward-4 "https:tcp:[]:50443:[192.168.250.10]:443"

VM_NAME="VM_ACIT4640"

vbmg createvm --name $VM_NAME --ostype RedHat_64 --register
vbmg modifyvm $VM_NAME --memory 1024 --vram 16 --cpus 1 --nic1 natnetwork --nat-network1 net_4640 --mouse usbtablet --audio none

SED_PROGRAM="/^Config file:/ { s/^.*:\s\+\(\S\+\)/\1/; s|\\\\|/|gp }"
VBOX_FILE=$(vbmg showvminfo "$VM_NAME" | sed -ne "$SED_PROGRAM")
VM_DIR=$(dirname "$VBOX_FILE")
SCTL_NAME="VM_ACIT4640_SCTL"
MEDIUM_NAME="/VM_ACIT4640_DISK"
MEDIUM_FILEPATH=$VM_DIR$MEDIUM_NAME

vbmg createmedium disk --filename "$MEDIUM_FILEPATH" --size 10000
vbmg storagectl $VM_NAME --name $SCTL_NAME --add sata
vbmg storageattach $VM_NAME --storagectl $SCTL_NAME --port 0 --device 0 --type hdd --medium "$MEDIUM_FILEPATH.vdi"

vbmg storagectl $VM_NAME --name "IDE Controller" --add ide --controller PIIX4
vbmg storageattach $VM_NAME --storagectl "IDE Controller" --port 1 --device 0 --type dvddrive --medium "C:/Users/Ko/Downloads/CentOS-7-x86_64-Minimal-1810.iso"
