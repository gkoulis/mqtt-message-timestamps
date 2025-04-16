#!/bin/bash

set -e  # Exit on error
set -u  # Treat unset variables as errors
set -o pipefail

# === Variables ===
PROJECT_DIR="${HOME}/projects/EclipseMosquitto"

echo "🚀 Setting up Mosquitto with mqtt-message-timestamps plugin..."

# Prepare directories
echo "📁 Creating project directory at ${PROJECT_DIR}..."
mkdir -p "${PROJECT_DIR}"
cd "${PROJECT_DIR}"

# Install dependencies
echo "🧩 Installing dependencies..."
sudo apt update
sudo apt install -y build-essential libc-ares-dev libcjson-dev libwebsockets-dev libssl-dev xsltproc docbook-xsl git libcunit1-dev libargon2-dev cmake pkg-config rsync libsqlite3-dev

# Clone Mosquitto
echo "🐳 Cloning Mosquitto..."
git clone --recursive https://github.com/eclipse/mosquitto.git
cd mosquitto
git checkout develop

# Ensure submodules are up to date
git submodule update --init --recursive

# Clone the plugin
cd ..
echo "🔌 Cloning mqtt-message-timestamps plugin..."
git clone https://github.com/gkoulis/mqtt-message-timestamps.git --depth 1

# Copy plugin source into mosquitto source
echo "🔄 Copying plugin source into Mosquitto tree..."
rsync -av --exclude='.git' mqtt-message-timestamps/ ./mosquitto/mqtt-message-timestamps/

# Add plugin to CMakeLists.txt
echo "🔧 Modifying Mosquitto's CMakeLists.txt to include plugin..."
echo -e "\n# ========================================\n# Custom Plugins\n# ========================================\n\nadd_subdirectory(mqtt-message-timestamps)" >> ./mosquitto/CMakeLists.txt

# Build Mosquitto with the plugin
echo "🏗️ Building Mosquitto with plugin..."
cd ./mosquitto
mkdir -p build
cd build
cmake .. -DWITH_TLS=ON -DWITH_WEBSOCKETS=ON -DWITH_SRV=ON -DWITH_DOCS=OFF -DWITH_BUNDLED_DEPS=ON
make -j$(nproc)

# Install Mosquitto
echo "📦 Installing Mosquitto..."
sudo make install

echo "✅ Build and installation completed successfully!"
echo "👉 Next step: run './install.sh' to install the custom build to /opt and set up the systemd service."
