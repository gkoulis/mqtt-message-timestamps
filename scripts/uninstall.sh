#!/bin/bash

set -e

SERVICE_NAME="mosquitto-custom"
INSTALL_DIR="/opt/mosquitto-custom"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
CUSTOM_USER="mosquitto-custom"
CUSTOM_GROUP="mosquitto-custom"

echo "🚧 Starting cleanup of ${SERVICE_NAME}..."

# Stop and disable the service
if systemctl is-active --quiet "${SERVICE_NAME}"; then
    echo "⛔ Stopping ${SERVICE_NAME} service..."
    sudo systemctl stop "${SERVICE_NAME}"
fi

if systemctl is-enabled --quiet "${SERVICE_NAME}"; then
    echo "🔌 Disabling ${SERVICE_NAME} service..."
    sudo systemctl disable "${SERVICE_NAME}"
fi

# Remove the service file
if [ -f "${SERVICE_FILE}" ]; then
    echo "🧹 Removing service file..."
    sudo rm -f "${SERVICE_FILE}"
fi

# Reload systemd to apply changes
echo "🔄 Reloading systemd..."
sudo systemctl daemon-reload

# Remove the installation directory
if [ -d "${INSTALL_DIR}" ]; then
    echo "🗑️ Removing installation directory at ${INSTALL_DIR}..."
    sudo rm -rf "${INSTALL_DIR}"
fi

# Remove user and group if they exist
if id "${CUSTOM_USER}" &>/dev/null; then
    echo "👤 Removing user ${CUSTOM_USER}..."
    sudo userdel "${CUSTOM_USER}"
fi

if getent group "${CUSTOM_GROUP}" &>/dev/null; then
    echo "👥 Removing group ${CUSTOM_GROUP}..."
    sudo groupdel "${CUSTOM_GROUP}"
fi

echo "✅ Cleanup completed!"

# Optionally remove logs (uncomment if needed)
# echo "🧹 Removing logs..."
# sudo journalctl --vacuum-time=1s --unit="${SERVICE_NAME}"

echo "📦 ${SERVICE_NAME} has been fully removed from the system."
