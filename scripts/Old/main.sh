sudo mkdir -p ~root/.ssh
sudo cp ~vagrant/.ssh/auth* ~root/.ssh

# 1
sudo cp /vagrant/scripts/watchlog /etc/sysconfig/

# 2
sudo cp /vagrant/scripts/watchlog.log /var/log/

# 3-4
sudo cp /vagrant/scripts/watchlog.sh /opt/

# 5
sudo cp /vagrant/scripts/watchlog.service /etc/systemd/system/

# 6
sudo cp /vagrant/scripts/watchlog.timer /etc/systemd/system/

# 7
sudo systemctl daemon-reload

# 8
sudo systemctl enable watchlog.service 

# 9
sudo systemctl start watchlog.timer

#----------------------------------------

# 1
sudo yum install epel-release -y
sudo yum install spawn-fcgi php php-cli mod_fcgid httpd -y  

# 2
sudo cp -f /vagrant/scripts/spawn-fcgi /etc/sysconfig/

# 3
sudo cp /vagrant/scripts/spawn-fcgi.service /etc/systemd/system/

# 4
sudo systemctl stop spawn-fcgi
sudo systemctl daemon-reload
sudo systemctl enable spawn-fcgi.service 
sudo systemctl start spawn-fcgi

#----------------------------------------

# 1-2
sudo cp /vagrant/scripts/httpd@.service /etc/systemd/system/

# 3
sudo cp /vagrant/scripts/httpd-first /etc/sysconfig/

# 4
sudo cp /vagrant/scripts/httpd-second /etc/sysconfig/

# 5
sudo cp /vagrant/scripts/first.conf /etc/httpd/conf/

# 6
sudo cp /vagrant/scripts/second.conf /etc/httpd/conf/

# 7
sudo systemctl daemon-reload

# 8
sudo systemctl start httpd@first  
sudo systemctl start httpd@second  





