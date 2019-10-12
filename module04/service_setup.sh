#!/bin/bash -x

vbmg () { VBoxManage.exe "$@"; }
# vbmg () { /mnt/c/Program\ Files/Oracle/VirtualBox/VBoxManage.exe "$@"; }

VM_NAME="VM_ACIT4640"
NET_NAME="net_4640"

clean_all () {
	vbmg natnetwork remove --netname "$NET_NAME"
	vbmg unregistervm "$VM_NAME" --delete
}

create_network () {
	vbmg natnetwork add --netname "$NET_NAME" \
		--network 192.168.250.0/24 \
		--dhcp off \
		--ipv6 off \
		--enable \
		--port-forward-4 "ssh:tcp:[]:50022:[192.168.250.10]:22" \
		--port-forward-4 "http:tcp:[]:50080:[192.168.250.10]:80" \
		--port-forward-4 "https:tcp:[]:50443:[192.168.250.10]:443" \
		--port-forward-4 "ssh2:tcp:[]:50222:[192.168.250.200]:22"
}

create_vm () {
	vbmg createvm --name "$VM_NAME" --ostype RedHat_64 --register
	vbmg modifyvm "$VM_NAME" --memory 2048 --vram 16 --cpus 1 --nic1 natnetwork \
		--nat-network1 net_4640 --mouse usbtablet --audio none --boot1 disk\
		--boot2 net
	SED_PROGRAM="/^Config file:/ { s/^.*:\s\+\(\S\+\)/\1/; s|\\\\|/|gp }"
	VBOX_FILE=$(vbmg showvminfo "$VM_NAME" | sed -ne "$SED_PROGRAM")
	VM_DIR=$(dirname "$VBOX_FILE")
	vbmg createmedium disk --filename "$VM_DIR"/"$VM_NAME".vdi \
		--format VDI \
		--size 10000
	vbmg storagectl "$VM_NAME" --name "Controller1" --add sata \
		--bootable on
	vbmg storageattach "$VM_NAME" --storagectl "Controller1" \
		--port 0 --device 0 \
		--type hdd \
		--medium "$VM_DIR"/"$VM_NAME".vdi
	vbmg storageattach "$VM_NAME" --storagectl "Controller1" \
		--type dvddrive --medium emptydrive \
		--port 1 --device 0
}

PXE_NAME="PXE_4640"
KEY_PATH="pxe_files/acit_admin_id_rsa"

pxe_setup () {
	vbmg modifyvm "$PXE_NAME" --nic1 natnetwork --nat-network1 net_4640
	vbmg startvm "$PXE_NAME" --type headless
	chmod 700 "$KEY_PATH"
	while /bin/true; do
        	ssh -i "$KEY_PATH" -p 50222 \
        	    -o ConnectTimeout=2 -o StrictHostKeyChecking=no \
        	    -q admin@localhost exit
        	if [ $? -ne 0 ]; then
        	        echo "PXE server is not up, sleeping..."
        	        sleep 2
        	else
        	        break
        	fi
	done
	ssh -i "$KEY_PATH" -p 50222 admin@localhost "sudo rm -rf /var/www/lighttpd/ks.cfg; sudo rm -rf /var/www/lighttpd/pxe_files"
	scp -P 50222 -i "$KEY_PATH" -r pxe_files/ admin@localhost:/home/admin/
	ssh -p 50222 -i "$KEY_PATH" admin@localhost "sudo mv /home/admin/pxe_files /var/www/lighttpd/"
	ssh -p 50222 -i "$KEY_PATH" admin@localhost "sudo cp -rf /var/www/lighttpd/pxe_files/ks.cfg /var/www/lighttpd/ks.cfg"
	ssh -p 50222 -i "$KEY_PATH" admin@localhost "sudo cp -rf /var/www/lighttpd/pxe_files/default /var/lib/tftpboot/pxelinux/pxelinux.cfg/default"
	ssh -p 50222 -i "$KEY_PATH" admin@localhost "sudo chmod 755 /var/www/lighttpd/ks.cfg"
}

start_vm () {
	vbmg startvm "$VM_NAME"
}

clean_all
create_network
create_vm
pxe_setup
start_vm
