#!/bin/bash
# === User Data Script for Mini Amazon Backend ===
set -euxo pipefail  # Better debugging (print commands, exit on error)

# 1. Update and install dependencies
dnf update -y
dnf install -y python3-pip git mariadb105 

# 2. Change directory to ec2-user home
cd /home/ec2-user

# 3. Clone your GitHub repo 
git clone https://github.com/yahiruvc-27/mini-amazon-backend.git mini-amazon-app
cd mini-amazon-app

# 4. Install Python packages from txt file
pip3 install -r requirements.txt

# 5. Create environment file with variable real values (modify here, secrets*)
cat <<EOF > /etc/mini-amazon.env
RDS_ENDPOINT=mini-amazondb.cctm6is0819y.us-east-1.rds.amazonaws.com
DB_USER=admin
DB_PASS=Vicaya27#6
DB_NAME=store
AWS_REGION=us-east-1
SES_SOURCE=yahiruvc@gmail.com
EOF

# 6. Fix permissions recursively
chown -R ec2-user:ec2-user /home/ec2-user/mini-amazon-app

# 7. Move systemd file service to "/etc/systemd/system/mini-amazon.service"
mv /home/ec2-user/mini-amazon-app/mini-amazon.service /etc/systemd/system/mini-amazon.service

# 8. Add env file reference, so that mini amazon can use this variables
sed -i '/\[Service\]/a EnvironmentFile=/etc/mini-amazon.env' /etc/systemd/system/mini-amazon.service

# 9. Reload and enable service
systemctl daemon-reload # daemon created but must be loaded (mini-amazon.service)
systemctl enable --now mini-amazon # enable and start
systemctl status mini-amazon -l --no-pager
