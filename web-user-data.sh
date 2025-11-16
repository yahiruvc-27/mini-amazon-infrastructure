#!/bin/bash
set -euxo pipefail

# === 1.- Update and Install packages ===
dnf update -y
dnf install -y nginx git awscli

# === 2.- Cretate variables ===
export S3_BUCKET="mini-amazon-bucket-yahir"
export IP_BACKEND="10.0.1.162"
export WEBROOT="/var/www/mini-amazon"
export NGINX_CONFIG_PATH="/etc/nginx/conf.d"

# === 3.- Prepare root directory for GitHub code ===
mkdir -p /var/www

# === 4.- Clone GitHub to root dir ====
git clone https://github.com/yahiruvc-27/mini-amazon-frontend.git ${WEBROOT}
cd ${WEBROOT}

sed -i "s|BACKEND_PLACEHOLDER|${IP_BACKEND}|g" ${WEBROOT}/nginx/mini-amazon.conf


# === 5.- Move nginx config adn clean the default
mv ${WEBROOT}/nginx/mini-amazon.conf ${NGINX_CONFIG_PATH}/mini-amazon.conf
rm -f /etc/nginx/conf.d/default.conf

# === 6.- Create az.txt with instance metadata ===

# Request a session token 
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

# Use the token to get the Availability Zone
AZ=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" \
  -s http://169.254.169.254/latest/meta-data/placement/availability-zone)

# Save it to root frontend directory and fix permissions
echo "$AZ" > ${WEBROOT}/az.txt
chmod 644 ${WEBROOT/}/az.txt

# === 7.- Get S3 product images to image directory ====
cd ${WEBROOT}/images
aws s3 sync s3://$S3_BUCKET ${WEBROOT}/images --delete

# === 8.- Permissions and nginx service start ===
chown -R nginx:nginx ${WEBROOT}
chmod -R 755 ${WEBROOT}

systemctl daemon-reload
systemctl enable --now nginx
systemctl status nginx -l --no-pager