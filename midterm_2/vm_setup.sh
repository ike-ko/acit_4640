useradd -p $(openssl passwd -1 midterm) midterm
yum -y install git nginx
yum -y update
mkdir /home/midterm/webapp
git clone https://github.com/timoguic/ACIT4640-todo-app.git /home/midterm/webapp
systemctl enable nginx && systemctl start nginx

nginx -s reload
