# Multi-Gateway Configuration for Stream Deck
# Configure this to switch between your gateways

$GatewayConfig = @{
    # Your local Windows machine (Origin)
    primary = "http://127.0.0.1:18790"
    
    # Your Mac Mini (via Tailscale)
    secondary = "http://100.92.222.41:18789"
    
    # You can add more:
    # work = "http://work-server:18790"
    # home = "http://192.168.1.100:18790"
}

# Save configuration
$ConfigPath = "$env:USERPROFILE\.openclaw\streamdeck-plugin\gateway-config.json"
$GatewayConfig | ConvertTo-Json | Out-File $ConfigPath -Encoding UTF8

Write-Host "✅ Gateway configuration saved!" -ForegroundColor Green
Write-Host ""
Write-Host "Configured Gateways:"
Write-Host "  🖥️  Primary (Origin): $($GatewayConfig.primary)"
Write-Host "  🍎  Secondary (Mac): $($GatewayConfig.secondary)"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Create a 'Switch Gateway' button in Stream Deck"
Write-Host "  2. Set action to: gateway-switch"
Write-Host "  3. Press to toggle between Origin and Mac Mini"
Write-Host ""
Read-Host "Press Enter to exit"