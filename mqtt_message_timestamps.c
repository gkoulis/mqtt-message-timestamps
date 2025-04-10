#include "config.h"
#include <stdio.h>
#include <time.h>
#include "mosquitto.h"

#define PLUGIN_NAME "mqtt_message_timestamps"
#define PLUGIN_VERSION "1.0"

MOSQUITTO_PLUGIN_DECLARE_VERSION(5);

static mosquitto_plugin_id_t *mosq_pid = NULL;

/* Utility function to add a timestamp user-property */
static int add_timestamp_property(mosquitto_property **properties, const char *property_name)
{
	struct timespec ts;
	uint64_t timestamp_ns;
	char timestamp_str[32]; // Enough to hold nanosecond timestamp

	if (clock_gettime(CLOCK_REALTIME, &ts) != 0) {
		fprintf(stderr, "[%s] Failed to get time for %s\n", PLUGIN_NAME, property_name);
		return MOSQ_ERR_UNKNOWN;
	}

	timestamp_ns = (uint64_t)ts.tv_sec * 1000000000ULL + (uint64_t)ts.tv_nsec;
	snprintf(timestamp_str, sizeof(timestamp_str), "%llu", (unsigned long long)timestamp_ns);

    return mosquitto_property_add_string_pair(properties, MQTT_PROP_USER_PROPERTY, property_name, timestamp_str);

    /*
	int rc = mosquitto_property_add_string_pair(properties, MQTT_PROP_USER_PROPERTY, property_name, timestamp_str);
	if (rc != MOSQ_ERR_SUCCESS) {
		fprintf(stderr, "[%s] Failed to add property %s: %d\n", PLUGIN_NAME, property_name, rc);
	} else {
		fprintf(stderr, "[%s] Added property %s = %s\n", PLUGIN_NAME, property_name, timestamp_str);
	}
	return rc;
    */
}

/* Callback for incoming messages (client -> broker) */
static int callback_message_in(int event, void *event_data, void *userdata)
{
	struct mosquitto_evt_message *ed = event_data;

	UNUSED(event);
	UNUSED(userdata);

	// fprintf(stderr, "[%s] Ingress hook fired for topic '%s'\n", PLUGIN_NAME, ed->topic);

	return add_timestamp_property(&ed->properties, "broker.ingress-timestamp");
}

/* Callback for outgoing messages (broker -> client) */
static int callback_message_out(int event, void *event_data, void *userdata)
{
	struct mosquitto_evt_message *ed = event_data;

	UNUSED(event);
	UNUSED(userdata);

	// fprintf(stderr, "[%s] Egress hook fired for topic '%s'\n", PLUGIN_NAME, ed->topic);

	return add_timestamp_property(&ed->properties, "broker.egress-timestamp");
}

/* Plugin initialization */
int mosquitto_plugin_init(mosquitto_plugin_id_t *identifier, void **user_data, struct mosquitto_opt *opts, int opt_count)
{
	UNUSED(user_data);
	UNUSED(opts);
	UNUSED(opt_count);

	mosq_pid = identifier;
	mosquitto_plugin_set_info(identifier, PLUGIN_NAME, PLUGIN_VERSION);

	fprintf(stderr, "[%s] Plugin initialized.\n", PLUGIN_NAME);

	mosquitto_callback_register(mosq_pid, MOSQ_EVT_MESSAGE_IN, callback_message_in, NULL, NULL);
	mosquitto_callback_register(mosq_pid, MOSQ_EVT_MESSAGE_OUT, callback_message_out, NULL, NULL);

	return MOSQ_ERR_SUCCESS;
}

/* Plugin cleanup */
int mosquitto_plugin_cleanup(void *user_data, struct mosquitto_opt *opts, int opt_count)
{
	UNUSED(user_data);
	UNUSED(opts);
	UNUSED(opt_count);

	fprintf(stderr, "[%s] Plugin cleanup.\n", PLUGIN_NAME);

	return MOSQ_ERR_SUCCESS;
}
