#!/bin/bash -x

# Create user, disable SELinux, firewall setup
initial_setup() {
	useradd -m -r todo-app && passwd -l todo-app
	setenforce 0
	sed -r -i 's/SELINUX=(enforcing|disabled)/SELINUX=permissive/' /etc/selinux/config
	firewall-cmd --zone=public --add-service=http
	firewall-cmd --zone=public --add-service=https
	firewall-cmd --zone=public --add-service=ssh
	firewall-cmd --zone=public --remove-service=dhcpv6-client
	firewall-cmd --zone=public --add-port=80/tcp
	firewall-cmd --zone=public --add-port=443/tcp
	firewall-cmd --zone=public --add-port=22/tcp
	firewall-cmd --runtime-to-permanent
}

# Setup todoapp and run services
app_setup() {
	su - todo-app bash -c "
	    mkdir app;
	    git clone https://github.com/timoguic/ACIT4640-todo-app.git app;
	    cd app;
	    npm i;
    "
    /bin/cp -rf /home/admin/database.js /home/todo-app/app/config
    /bin/cp -rf /home/admin/nginx.conf /etc/nginx/
    /bin/cp -rf /home/admin/todoapp.service /lib/systemd/system
    chown todo-app:todo-app -R /home/todo-app/app/config/database.js
    chmod -R 755 /home/todo-app/
    systemctl daemon-reload
    systemctl enable nginx && systemctl start nginx
    systemctl enable mongod && systemctl start mongod
    systemctl enable todoapp && systemctl start todoapp
}

initial_setup
app_setup
