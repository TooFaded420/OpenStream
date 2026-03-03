#!/usr/bin/with-contenv bashio

# Home Assistant OpenClaw Stream Deck Addon

CONFIG_PATH=/data/options.json
GATEWAY_URL=$(bashio::config 'gateway_url')
DEVICE_TOKEN=$(bashio::config 'device_token')
AUTO_IMPORT=$(bashio::config 'auto_import')

bashio::log.info "Starting OpenClaw Stream Deck addon..."
bashio::log.info "Gateway: $GATEWAY_URL"

# Check if OpenClaw is reachable
if curl -s "$GATEWAY_URL/status" > /dev/null; then
    bashio::log.info "✓ OpenClaw gateway is online"
else
    bashio::log.warning "OpenClaw gateway not responding at $GATEWAY_URL"
    bashio::log.info "Make sure OpenClaw is running on your host machine"
fi

# Start web interface
python3 /app/web_server.py &

# Keep container running
tail -f /dev/null