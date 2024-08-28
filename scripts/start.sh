#!/usr/bin/env bash

export DBUS_SYSTEM_BUS_ADDRESS=unix:path=/host/run/dbus/system_bus_socket

# Optional step - it takes couple of seconds (or longer) to establish a WiFi connection
# sometimes. In this case, following checks will fail and wifi-connect
# will be launched even if the device will be able to connect to a WiFi network.
# If this is your case, you can wait for a while and then check for the connection.
LOG_FILE=/logs/start.log
exec > >(tee ${LOG_FILE}) 2>&1

# Check if the file exists
if [ ! -f "$LOG_FILE" ]; then
    # If the file doesn't exist, create it
    touch "$LOG_FILE"
    echo "File '$LOG_FILE' created."
else
    echo "File '$LOG_FILE' already exists."
fi 

echo "starting start script..."
sleep 10
export PORTAL_SSID="Tekara-connect-${RESIN_DEVICE_UUID:0:5}"
# Choose a condition for running WiFi Connect according to your use case:

# 1. Is there a default gateway?
# ip route | grep default

# 2. Is there Internet connectivity?
#nmcli -t g | grep full

# 3. Is there Internet connectivity via a google ping?
# wget --spider http://google.com 2>&1

# 4. Is there an active WiFi connection?

check_connection() {
    # Get the SSID of the connected WiFi network
    SSID=$(iwgetid -r)
    
    if [ -n "$SSID" ]; then
        echo "Connected to WiFi network: $SSID."
        
        # Check if connected to Balena Cloud
        if ping -c 1 api.balena-cloud.com > /dev/null 2>&1; then
            echo "Connected to Balena Cloud. Skipping WiFi Connect."
            return 0
        else
            echo "Connected to WiFi network: $SSID, but failed to connect to Balena Cloud."
        fi
    else
        echo "Not connected to any WiFi network."
    fi
    
    return 1
}

check_connection
connection=$? 

if [ "$connection" -eq 0 ]; then
    printf 'Skipping WiFi Connect\n'
else
    printf 'Starting WiFi Connect\n'
    ./wifi-connect
fi

sleep infinity