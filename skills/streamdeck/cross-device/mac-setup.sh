#!/bin/bash
# OpenClaw Cross-Device Network Setup for Mac
# Mac Mini ↔ Windows PC bidirectional connection

# Network Configuration
MAC_IP="192.168.1.50"
MAC_PORT="18790"
MAC_TOKEN="oc_gw_mac_token_$(openssl rand -hex 8)"

WINDOWS_IP="192.168.1.100"
WINDOWS_PORT="18790"

# Self-Healing Configuration
HEALTH_CHECK_INTERVAL=30
FAILOVER_THRESHOLD=3
AUTO_RESTART=true

# Health Check Function
check_device_health() {
    local device_ip=$1
    local device_name=$2
    local failures=0
    
    while [ $failures -lt $FAILOVER_THRESHOLD ]; do
        if curl -s "http://$device_ip:$WINDOWS_PORT/status" > /dev/null; then
            echo "✓ $device_name is healthy"
            return 0
        else
            failures=$((failures + 1))
            echo "✗ $device_name failed check ($failures/$FAILOVER_THRESHOLD)"
            sleep 5
        fi
    done
    
    return 1
}

# Self-Healing Loop
start_self_healing() {
    echo "Starting self-healing monitor..."
    
    while true; do
        # Check Windows PC
        if ! check_device_health $WINDOWS_IP "Windows-PC"; then
            echo "Windows PC unhealthy! Attempting recovery..."
            # Send restart command
            curl -X POST "http://$WINDOWS_IP:$WINDOWS_PORT/gateway.restart" 2>/dev/null
        fi
        
        # Check Mac (self-check)
        if ! curl -s "http://localhost:$MAC_PORT/status" > /dev/null; then
            echo "Mac OpenClaw unhealthy! Restarting..."
            openclaw gateway restart
        fi
        
        # Sync sessions
        sync_sessions
        
        sleep $HEALTH_CHECK_INTERVAL
    done
}

# Sync Sessions Between Devices
sync_sessions() {
    # Get Mac sessions
    mac_sessions=$(curl -s "http://localhost:$MAC_PORT/sessions.list")
    
    # Get Windows sessions
    win_sessions=$(curl -s "http://$WINDOWS_IP:$WINDOWS_PORT/sessions.list")
    
    # Sync to both
    curl -X POST "http://localhost:$MAC_PORT/sessions.sync" \
        -H "Content-Type: application/json" \
        -d "{\"sessions\": $win_sessions}" 2>/dev/null
    
    curl -X POST "http://$WINDOWS_IP:$WINDOWS_PORT/sessions.sync" \
        -H "Content-Type: application/json" \
        -d "{\"sessions\": $mac_sessions}" 2>/dev/null
}

# Export Configuration
export_config() {
    cat > ~/.openclaw/cross-device-config.json << EOF
{
  "Mac": {
    "Name": "Mac-Mini",
    "IP": "$MAC_IP",
    "Port": $MAC_PORT,
    "Token": "$MAC_TOKEN",
    "Device": "Mac Mini M2",
    "Role": "secondary"
  },
  "Windows": {
    "Name": "Origin-PC",
    "IP": "$WINDOWS_IP",
    "Port": $WINDOWS_PORT,
    "Token": "$(cat ~/.openclaw/windows-token.txt 2>/dev/null || echo 'unknown')",
    "Device": "Windows Desktop",
    "Role": "primary"
  }
}
EOF
    echo "Configuration exported to ~/.openclaw/cross-device-config.json"
}

# Setup Instructions
print_setup() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║     OpenClaw Cross-Device Setup - Mac Configuration       ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Mac Configuration:"
    echo "  IP: $MAC_IP"
    echo "  Port: $MAC_PORT"
    echo "  Token: $MAC_TOKEN"
    echo ""
    echo "Windows Configuration:"
    echo "  IP: $WINDOWS_IP"
    echo "  Port: $WINDOWS_PORT"
    echo ""
    echo "Next Steps:"
    echo "  1. Copy Mac Token to Windows config"
    echo "  2. Copy Windows Token to Mac config"
    echo "  3. Run: start_self_healing"
    echo ""
}

# Main
export_config
print_setup
