#!/bin/bash

sudo systemctl daemon-reload
sudo systemctl enable mosquitto-custom
sudo systemctl start mosquitto-custom
sudo systemctl status mosquitto-custom
