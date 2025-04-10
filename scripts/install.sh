#!/bin/bash

set -e

# === Variables ===
PROJECT_DIR="${HOME}/projects/EclipseMosquitto"
INSTALL_DIR="/opt/mosquitto-custom"
SERVICE_NAME="mosquitto-custom"
CUSTOM_USER="mosquitto-custom"
CUSTOM_GROUP="mosquitto-custom"

echo "🚀 Installing Mosquitto Custom..."

# Create system user and group if not exists
if ! id "${CUSTOM_USER}" &>/dev/null; then
    echo "🔧 Creating user and group: ${CUSTOM_USER}"
    sudo groupadd --system "${CUSTOM_GROUP}" || true
    sudo useradd --system --no-create-home --shell /usr/sbin/nologin --gid "${CUSTOM_GROUP}" "${CUSTOM_USER}"
fi

# Prepare directories
sudo mkdir -p "${INSTALL_DIR}/bin"
sudo mkdir -p "${INSTALL_DIR}/lib"
sudo mkdir -p "${INSTALL_DIR}/conf"

# Copy Mosquitto binary
sudo cp /usr/local/sbin/mosquitto "${INSTALL_DIR}/bin/"

# Copy mosquitto_sub and mosquitto_pub
sudo cp /usr/local/bin/mosquitto_* "${INSTALL_DIR}/bin/"

# Copy libraries
sudo cp /usr/local/lib/libmosquitto.so* "${INSTALL_DIR}/lib/"

# Copy plugin
sudo cp /usr/local/lib/mosquitto_dynamic_security.so "${INSTALL_DIR}/lib/" || true
sudo cp "${PROJECT_DIR}/mosquitto/build/mqtt-message-timestamps/mqtt_message_timestamps.so" "${INSTALL_DIR}/lib/"

# Copy config
sudo cp ./mosquitto-custom.conf "${INSTALL_DIR}/conf/mosquitto.conf"

# Create startup script
sudo tee "${INSTALL_DIR}/bin/start-mosquitto.sh" > /dev/null <<'EOF'
#!/bin/bash
export LD_LIBRARY_PATH=/opt/mosquitto-custom/lib:$LD_LIBRARY_PATH
/opt/mosquitto-custom/bin/mosquitto -c /opt/mosquitto-custom/conf/mosquitto.conf
EOF

sudo chmod +x "${INSTALL_DIR}/bin/start-mosquitto.sh"

# Set ownership
sudo chown -R "${CUSTOM_USER}:${CUSTOM_GROUP}" "${INSTALL_DIR}"

# Install systemd service
sudo cp ./mosquitto-custom.service /etc/systemd/system/mosquitto-custom.service

echo "✅ Install script completed. Now run ./enable_start.sh to enable and start the service."
