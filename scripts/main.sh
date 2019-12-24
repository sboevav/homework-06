sudo mkdir -p ~root/.ssh
sudo cp ~vagrant/.ssh/auth* ~root/.ssh

sudo yum install mailx -y

sudo cp /vagrant/scripts/watchlog /etc/sysconfig/
sudo cp /vagrant/scripts/watchlog.log /var/log/
sudo cp /vagrant/scripts/watchlog.sh /opt/
sudo cp /vagrant/scripts/watchlog.service /etc/systemd/system/
sudo cp /vagrant/scripts/watchlog.timer /etc/systemd/system/

sudo systemctl daemon-reload
sudo systemctl enable watchlog.service 
sudo systemctl start watchlog.timer

