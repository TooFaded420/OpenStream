# Multi-Gateway Network Buttons

## For Users with Multiple OpenClaw Instances

### Your Setup Example:
- **Main PC** (localhost:18790) - Primary workstation
- **Mac Mini** (192.168.1.50:18790) - Secondary computer
- Both on same network

---

## New Buttons Available:

### **1. Gateway Status** 🔗
Shows health of all gateways
- Green = Online
- Red = Offline
- Shows latency for each

### **2. Switch Gateway** 🔄
Switches to best available gateway
- Auto-selects lowest latency
- Falls back if primary fails
- Shows which gateway is active

### **3. Broadcast Message** 📢
Sends message to ALL gateways simultaneously
- "Good morning" → All devices
- "Deploy complete" → All channels
- Emergency notifications

### **4. Sync Sessions** 🔄
Syncs session state across all gateways
- Keep contexts in sync
- Share agent states
- Unified experience

### **5. Gateway A/B/C/D** 🔘
Direct buttons for each gateway:
- Gateway A → Main PC
- Gateway B → Mac Mini
- Gateway C → Laptop
- Gateway D → Server

---

## Configuration

Edit your Stream Deck button settings:

```json
{
  "gateways": {
    "primary": "http://localhost:18790",
    "macmini": "http://192.168.1.50:18790",
    "laptop": "http://192.168.1.75:18790"
  },
  "autoFailover": true,
  "activeGateway": "primary"
}
```

---

## Use Cases

### **Developer with Multiple Machines**
- PC for coding (heavy tasks)
- Mac Mini for testing (light tasks)
- Switch between them instantly
- Broadcast "deploy" to all

### **Home Lab Setup**
- Main server (always on)
- Gaming PC (sometimes on)
- Laptop (mobile)
- Always uses best available

### **Team Environment**
- Share gateways with team
- Sync contexts
- Broadcast team messages
- Failover if one goes down

---

## How It Works

```
Stream Deck
    ↓
Gateway Manager
    ↓
Checks all gateways
    ↓
Uses best/lowest latency
    ↓
Or broadcasts to all
```

**Automatic Failover:**
If Gateway A fails → Auto-switch to Gateway B

**Manual Override:**
Press "Switch Gateway" to force change

---

## Network Requirements

- All gateways on same network (or accessible via IP)
- Port 18790 open on each device
- Firewall rules allow connections

**Example Network:**
```
Router: 192.168.1.1
  ├── PC: 192.168.1.100:18790
  ├── Mac: 192.168.1.50:18790
  └── Laptop: 192.168.1.75:18790
```

---

## Buttons for Your 2-Gateway Setup

1. **Gateway: PC** - Always uses main PC
2. **Gateway: Mac Mini** - Always uses Mac
3. **Auto-Switch** - Uses best available
4. **Broadcast** - Send to both
5. **Sync** - Sync sessions

---

**Want me to add these buttons to the plugin?** 🦞
