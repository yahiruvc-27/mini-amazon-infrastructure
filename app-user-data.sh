#!/bin/bash
# === User Data Script for Mini Amazon Backend ===
set -euxo pipefail  # Better debugging (print commands, exit on error)

# 1. Update and install dependencies
dnf update -y
dnf install -y python3-pip git mariadb105 

APP_DIR="/home/ec2-user/mini-amazon-app"
ENV_FILE="/etc/mini-amazon.env"
SERVICE_SRC="${APP_DIR}/mini-amazon.service"
SERVICE_CONFIG="/etc/systemd/system/mini-amazon.service"


# 3. Clone your GitHub repo 
cd /home/ec2-user

if [ ! -d "${APP_DIR}/.git" ]; then
  echo "Cloning backend repository..."
  git clone https://github.com/yahiruvc-27/mini-amazon-backend.git "${APP_DIR}"
else
  echo "Backend repository already exists. Pulling latest changes..."
  cd "${APP_DIR}"
  git pull
fi

# 4. Install Python packages from txt file
pip3 install -r "${APP_DIR}/requirements.txt"

# 5. Create environment file with variable real values (modify here, secrets*)
cat <<EOF > "${ENV_FILE}"
RDS_ENDPOINT=****
DB_USER=****
DB_PASS=****
DB_NAME=store
AWS_REGION=us-east-1
SES_SOURCE=****
EOF

chmod 600 "${ENV_FILE}"

# 6. Fix permissions recursively
chown -R ec2-user:ec2-user "${APP_DIR}"

# 7. Move systemd file .service to "/etc/systemd/system/mini-amazon.service"
mv /home/ec2-user/mini-amazon-app/mini-amazon.service /etc/systemd/system/mini-amazon.service

# ------------------------------------------------------------
# 7. Install systemd service file (COPY, NOT MOVE)
# ------------------------------------------------------------
if [ ! -f "${SERVICE_CONFIG}" ]; then
  echo "Installing systemd service file..."
  cp "${SERVICE_SRC}" "${SERVICE_CONFIG}"
fi

# ------------------------------------------------------------
# 8. Ensure EnvironmentFile is referenced exactly once
# ------------------------------------------------------------
if ! grep -q "^EnvironmentFile=${ENV_FILE}" "${SERVICE_CONFIG}"; then
  sed -i "/^\[Service\]/a EnvironmentFile=${ENV_FILE}" "${SERVSERVICE_CONFIGICE_DST}"
fi

# ------------------------------------------------------------
# 9. Reload systemd and start service
# ------------------------------------------------------------
systemctl daemon-reload
systemctl enable --now mini-amazon

# Non-fatal sanity check
systemctl is-active mini-amazon || systemctl status mini-amazon -l --no-pager