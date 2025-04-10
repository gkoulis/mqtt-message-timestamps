set (PLUGIN_NAME mqtt_message_timestamps)

add_mosquitto_plugin_no_install("${PLUGIN_NAME}" "${PLUGIN_NAME}.c" "" "")