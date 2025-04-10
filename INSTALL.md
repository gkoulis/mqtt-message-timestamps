# Manual Installation Guide for Mosquitto with mqtt-message-timestamps Plugin

This guide will help you manually build and install Mosquitto with the `mqtt-message-timestamps` plugin, configure it, and set it up as a systemd service.

## Prerequisites

Ensure you have a Linux environment with administrative (sudo) privileges.

### Install Required Dependencies

Open your terminal and run:

```bash
sudo apt update
sudo apt install -y build-essential libc-ares-dev libcjson-dev libwebsockets-dev libssl-dev xsltproc docbook-xsl git libcunit1-dev libargon2-dev cmake pkg-config rsync
```

## Clone the Mosquitto Source Code

Create a working directory and clone the Mosquitto repository:

```bash
mkdir -p ~/projects/EclipseMosquitto
cd ~/projects/EclipseMosquitto

git clone --recursive https://github.com/eclipse/mosquitto.git
cd mosquitto
git checkout develop
git submodule update --init --recursive
```

## Clone the mqtt-message-timestamps Plugin

Clone the plugin repository and copy its contents into the Mosquitto source tree:

```bash
cd ~/projects/EclipseMosquitto
git clone https://github.com/gkoulis/mqtt-message-timestamps.git --depth 1
rsync -av --exclude='.git' mqtt-message-timestamps/ ./mosquitto/mqtt-message-timestamps/
```

## Modify Mosquitto to Include the Plugin

Edit the `CMakeLists.txt` file in the Mosquitto directory to include the plugin:

```bash
cd ~/projects/EclipseMosquitto/mosquitto
nano CMakeLists.txt
```

Add the following lines at the end of the file:

```cmake
# ========================================
# Custom Plugins
# ========================================

add_subdirectory(mqtt-message-timestamps)
```

Save and close the file.

## Build Mosquitto with the Plugin

Create a build directory and compile the source:

```bash
mkdir -p build
cd build
cmake .. -DWITH_TLS=ON -DWITH_WEBSOCKETS=ON -DWITH_SRV=ON -DWITH_DOCS=OFF -DWITH_BUNDLED_DEPS=ON
make -j$(nproc)
sudo make install
```

## Prepare the Installation Directory

Create the target installation directories:

```bash
sudo mkdir -p /opt/mosquitto-custom/bin
sudo mkdir -p /opt/mosquitto-custom/lib
sudo mkdir -p /opt/mosquitto-custom/conf
```

Copy the necessary binaries and libraries:

```bash
sudo cp /usr/local/sbin/mosquitto /opt/mosquitto-custom/bin/
sudo cp /usr/local/bin/mosquitto_* /opt/mosquitto-custom/bin/
sudo cp /usr/local/lib/libmosquitto.so* /opt/mosquitto-custom/lib/
sudo cp ~/projects/EclipseMosquitto/mosquitto/build/mqtt-message-timestamps/mqtt_message_timestamps.so /opt/mosquitto-custom/lib/
```

## Create the Configuration File

Create the Mosquitto configuration file:

```bash
sudo nano /opt/mosquitto-custom/conf/mosquitto.conf
```

Add the following content:

```conf
plugin /opt/mosquitto-custom/lib/mqtt_message_timestamps.so
```

Save and close the file.

## Create the Startup Script

Create a script to launch Mosquitto with the correct environment:

```bash
sudo nano /opt/mosquitto-custom/bin/start-mosquitto.sh
```

Add the following content:

```bash
#!/bin/bash
export LD_LIBRARY_PATH=/opt/mosquitto-custom/lib:$LD_LIBRARY_PATH
/opt/mosquitto-custom/bin/mosquitto -c /opt/mosquitto-custom/conf/mosquitto.conf
```

Make the script executable:

```bash
sudo chmod +x /opt/mosquitto-custom/bin/start-mosquitto.sh
```

## Create the System User and Group

Create a dedicated user and group for the service:

```bash
sudo groupadd --system mosquitto-custom || true
sudo useradd --system --no-create-home --shell /usr/sbin/nologin --gid mosquitto-custom mosquitto-custom
sudo chown -R mosquitto-custom:mosquitto-custom /opt/mosquitto-custom
```

## Create the systemd Service

Create the service file:

```bash
sudo nano /etc/systemd/system/mosquitto-custom.service
```

Add the following content:

```ini
[Unit]
Description=Custom Mosquitto MQTT Broker with Plugin
After=network.target

[Service]
ExecStart=/opt/mosquitto-custom/bin/start-mosquitto.sh
Restart=always
User=mosquitto-custom
Group=mosquitto-custom
Environment=LD_LIBRARY_PATH=/opt/mosquitto-custom/lib

[Install]
WantedBy=multi-user.target
```

Reload systemd to apply changes:

```bash
sudo systemctl daemon-reload
```

Enable and start the service:

```bash
sudo systemctl enable mosquitto-custom
sudo systemctl start mosquitto-custom
sudo systemctl status mosquitto-custom
```

## Verify the Installation

Check that Mosquitto is running:

```bash
sudo systemctl status mosquitto-custom
```

Check the version to ensure it's installed correctly:

```bash
/opt/mosquitto-custom/bin/mosquitto -v
```

Test publishing and subscribing to a topic:

```bash
/opt/mosquitto-custom/bin/mosquitto_sub -V mqttv5 -t test/topic -F '%U %U : %p'
/opt/mosquitto-custom/bin/mosquitto_pub -V mqttv5 -t test/topic -m "hello world"
```

## Uninstalling

To completely remove the custom installation:

Stop and disable the service:

```bash
sudo systemctl stop mosquitto-custom
sudo systemctl disable mosquitto-custom
```

Remove the service file:

```bash
sudo rm -f /etc/systemd/system/mosquitto-custom.service
sudo systemctl daemon-reload
```

Remove the installation directory:

```bash
sudo rm -rf /opt/mosquitto-custom
```

Remove the system user and group:

```bash
sudo userdel mosquitto-custom
sudo groupdel mosquitto-custom
```
