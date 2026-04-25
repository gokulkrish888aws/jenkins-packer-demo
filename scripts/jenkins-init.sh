#!/bin/bash
set -e

# volume setup
vgchange -ay

DEVICE_FS=`blkid -o value -s TYPE ${DEVICE}`
if [ "`echo -n $DEVICE_FS`" == "" ] ; then 
  # wait for the device to be attached
  DEVICENAME=`echo "${DEVICE}" | awk -F '/' '{print $3}'`
  DEVICEEXISTS=''
  while [[ -z $DEVICEEXISTS ]]; do
    echo "checking $DEVICENAME"
    DEVICEEXISTS=`lsblk |grep "$DEVICENAME" |wc -l`
    if [[ $DEVICEEXISTS != "1" ]]; then
      sleep 15
    fi
  done
  pvcreate ${DEVICE}
  vgcreate data ${DEVICE}
  lvcreate --name volume1 -l 100%FREE data
  mkfs.ext4 /dev/data/volume1
fi
mkdir -p /var/lib/jenkins
echo '/dev/data/volume1 /var/lib/jenkins ext4 defaults 0 0' >> /etc/fstab
mount /var/lib/jenkins

# Install dependencies
echo "Installing dependencies..."
apt-get install -y python3 openjdk-21-jdk awscli unzip

# Install Jenkins manually (bypass repository issues)
echo "Installing Jenkins..."
wget -q https://get.jenkins.io/war-stable/latest/jenkins.war -O /opt/jenkins.war
useradd -m -s /bin/bash jenkins 2>/dev/null || true
mkdir -p /var/lib/jenkins
chown jenkins:jenkins /var/lib/jenkins /opt/jenkins.war

# Create systemd service for Jenkins
tee /etc/systemd/system/jenkins.service > /dev/null << 'EOF'
[Unit]
Description=Jenkins Continuous Integration Server
After=network.target

[Service]
Type=simple
User=jenkins
Group=jenkins
Environment=JENKINS_HOME=/var/lib/jenkins
ExecStart=/usr/bin/java -jar /opt/jenkins.war --httpPort=8080
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable jenkins
systemctl start jenkins
apt-get install -y jenkins

# Install Terraform
echo "Installing Terraform ${TERRAFORM_VERSION}..."
wget -q https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -O /tmp/terraform.zip
unzip -o /tmp/terraform.zip -d /usr/local/bin/
rm -f /tmp/terraform.zip
terraform --version

# Install Packer
echo "Installing Packer ${PACKER_VERSION}..."
wget -q https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip -O /tmp/packer.zip
unzip -o /tmp/packer.zip -d /usr/local/bin/
rm -f /tmp/packer.zip
packer --version

# Clean up
echo "Cleaning up..."
apt-get clean

echo "Installation complete!"
