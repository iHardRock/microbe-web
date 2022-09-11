#!/bin/sh

plugin="mqtt"
source /usr/sbin/plugins-common

show_help() {
  echo "Usage: $0 [-t topic] [-m message] [-v] [-h]
  -t topic    MQTT topic
  -m message  Message playload
  -v          Verbose output.
  -h          Show this help.
"
  exit 0
}

# override config values with command line arguments
while getopts m:t:vh flag; do
  case ${flag} in
  m) mqtt_message=${OPTARG} ;;
  t) mqtt_topic=${OPTARG} ;;
  v) verbose=1 ;;
  h) show_help ;;
  esac
done

[ "false" = "$mqtt_enabled" ] &&
  log "Sending to MQTT broker is disabled." && exit 10

# validate mandatory values
[ -z "$mqtt_host" ] &&
  log "MQTT broker host not found in config" && exit 11
[ -z "$mqtt_port" ] &&
  log "MQTT broker port not found in config" && exit 12
[ -z "$mqtt_topic" ] &&
  log "MQTT topic not found" && exit 13
[ -z "$mqtt_message" ] &&
  log "MQTT message template not found" && exit 14

# assign default values if not set
[ -z "$mqtt_client_id" ] &&
  mqtt_client_id="${network_hostname}"

# parse strftime templates
mqtt_message=$(date +"$mqtt_message")

command="mosquitto_pub"
command="${command} -h ${mqtt_host}"
command="${command} -p ${mqtt_port}"
command="${command} -t ${mqtt_topic}"
command="${command} -i ${mqtt_client_id}"
command="${command} -m \"${mqtt_message}\""

# MQTT credentials, if given
[ -n "$mqtt_username" ] &&
  command="${command} -u ${mqtt_username}"
[ -n "$mqtt_password" ] &&
  command="${command} -P ${mqtt_password}"

# SOCK5 proxy, if needed
if [ "true" = "$mqtt_socks5_enabled" ]; then
  source /etc/webui/socks5.conf
  command="${command} --proxy socks5h://${socks5_login}:${socks5_password}@${socks5_host}:${socks5_port}"
fi

log "$command"
eval "$command" >>$LOG_FILE 2>&1

[ "1" = "$verbose" ] && cat $LOG_FILE

exit 0
