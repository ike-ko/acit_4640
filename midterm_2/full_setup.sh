vbmg () { /mnt/c/Program\ Files/Oracle/VirtualBox/VBoxManage.exe "$@"; }
NET_NAME="A01033689_net"
VM_NAME="midterm_4640"
STUDENT_ID="A01033689"
KEY_PATH="midterm_id_rsa"

vbmg natnetwork remove --netname "$NET_NAME"
vbmg natnetwork add --netname "$NET_NAME" \
                --network 192.168.250.0/24 \
                --dhcp off \
                --ipv6 off \
                --enable \
                --port-forward-4 "tcp:tcp:[]:42080:[192.168.250.10]:82" \
                --port-forward-4 "ssh:tcp:[]:50222:[192.168.250.10]:22"
vbmg modifyvm "$VM_NAME" --name "$STUDENT_ID" --nic1 natnetwork \
                --nat-network1 "$NET_NAME" --mouse usbtablet --audio none --boot1 disk
vbmg startvm "$STUDENT_ID"

while /bin/true; do
    	ssh -i "$KEY_PATH" -p 50222 \
    	    -o ConnectTimeout=2 -o StrictHostKeyChecking=no \
    	    -q midterm@localhost exit
    	if [ $? -ne 0 ]; then
    	        echo "PXE server is not up, sleeping..."
    	        sleep 2
    	else
    	        break
    	fi
done


