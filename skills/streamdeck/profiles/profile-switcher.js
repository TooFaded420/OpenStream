/**
 * OpenClaw Workspace Profile Switcher v1.1
 * Handles profile switching (dev/content/ops) with preset updates
 * Integrates with Gateway Setup Wizard and Stream Deck SDK v5
 */

const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

// Config paths
const CONFIG_DIR = path.join(process.env.USERPROFILE || process.env.HOME, '.openclaw');
const PROFILES_PATH = path.join(CONFIG_DIR, 'workspace-profiles.json');
const STREAMDECK_DIR = path.join(CONFIG_DIR, 'workspace', 'skills', 'streamdeck');

// Default profiles configuration
const DEFAULT_PROFILES = {
  version: '1.1.0',
  description: 'OpenClaw Workspace Profiles - Switch between dev/content/ops modes',
  activeProfile: 'dev',
  profiles: {
    dev: {
      name: 'Developer',
      description: 'Coding, debugging, and software development',
      icon: '💻',
      theme: 'pip',
      presets: {
        model: 'synthetic/hf:nvidia/Kimi-K2.5-NVFP4',
        searchProvider: 'brave',
        defaultTask: 'code review',
        subagentTemplate: 'coding',
        ttsEnabled: false,
        timeoutMs: 15000
      },
      tools: {
        enabled: ['code', 'debug', 'git', 'test', 'web_search', 'browser', 'session'],
        disabled: ['image_generation', 'voice_recording']
      },
      shortcuts: {
        spawnTask: 'Review and improve the following code:',
        webSearchQuery: 'latest programming best practices'
      }
    },
    content: {
      name: 'Content Creator',
      description: 'Writing, media creation, and content production',
      icon: '🎨',
      theme: 'coral',
      presets: {
        model: 'synthetic/vertex/gemini-2.5-pro',
        searchProvider: 'brave',
        defaultTask: 'content ideas',
        subagentTemplate: 'creative',
        ttsEnabled: true,
        ttsVoice: 'Nova',
        timeoutMs: 20000
      },
      tools: {
        enabled: ['tts', 'image_generation', 'web_search', 'browser', 'message', 'session'],
        disabled: ['debug', 'git']
      },
      shortcuts: {
        spawnTask: 'Generate creative ideas for content about:',
        webSearchQuery: 'trending topics in content creation'
      }
    },
    ops: {
      name: 'Operations',
      description: 'System monitoring, automation, and infrastructure',
      icon: '⚙️',
      theme: 'command',
      presets: {
        model: 'synthetic/hf:nvidia/Kimi-K2.5-NVFP4',
        searchProvider: 'brave',
        defaultTask: 'system status',
        subagentTemplate: 'ops',
        ttsEnabled: false,
        timeoutMs: 10000
      },
      tools: {
        enabled: ['nodes', 'subagents', 'session', 'status', 'restart', 'config', 'web_search'],
        disabled: ['image_generation', 'tts']
      },
      shortcuts: {
        spawnTask: 'Check system health and report status',
        webSearchQuery: 'server monitoring best practices'
      }
    }
  },
  global: {
    autoSwitchOnAppFocus: true,
    showNotifications: true,
    persistProfilePerSession: true,
    profileSwitchCooldownMs: 2000
  },
  mappings: {
    appProfiles: {
      'Code.exe': 'dev',
      'code': 'dev',
      'devenv.exe': 'dev',
      'cursor.exe': 'dev',
      'notion.exe': 'content',
      'obs64.exe': 'content',
      'chrome.exe': 'content',
      'discord.exe': 'content',
      'pwsh.exe': 'ops',
      'powershell.exe': 'ops',
      'wt.exe': 'ops'
    }
  }
};

class ProfileSwitcher {
  constructor() {
    this.profiles = null;
    this.activeProfile = null;
    this.lastSwitchTime = 0;
    this.init();
  }

  init() {
    this.loadProfiles();
    console.log('[ProfileSwitcher] Initialized with profile:', this.activeProfile);
  }

  /**
   * Load profiles from config file or create defaults
   */
  loadProfiles() {
    try {
      if (fs.existsSync(PROFILES_PATH)) {
        const data = JSON.parse(fs.readFileSync(PROFILES_PATH, 'utf-8'));
        this.profiles = { ...DEFAULT_PROFILES, ...data };
        this.activeProfile = this.profiles.activeProfile || 'dev';
        console.log('[ProfileSwitcher] Loaded profiles from', PROFILES_PATH);
      } else {
        this.profiles = DEFAULT_PROFILES;
        this.activeProfile = 'dev';
        this.saveProfiles();
        console.log('[ProfileSwitcher] Created default profiles at', PROFILES_PATH);
      }
    } catch (e) {
      console.error('[ProfileSwitcher] Failed to load profiles:', e.message);
      this.profiles = DEFAULT_PROFILES;
      this.activeProfile = 'dev';
    }
  }

  /**
   * Save profiles to config file
   */
  saveProfiles() {
    try {
      if (!fs.existsSync(CONFIG_DIR)) {
        fs.mkdirSync(CONFIG_DIR, { recursive: true });
      }
      fs.writeFileSync(PROFILES_PATH, JSON.stringify(this.profiles, null, 2), 'utf-8');
      console.log('[ProfileSwitcher] Saved profiles to', PROFILES_PATH);
      return true;
    } catch (e) {
      console.error('[ProfileSwitcher] Failed to save profiles:', e.message);
      return false;
    }
  }

  /**
   * Get list of available profile keys
   */
  getProfileKeys() {
    return Object.keys(this.profiles.profiles);
  }

  /**
   * Get current profile configuration
   */
  getCurrentProfile() {
    return {
      key: this.activeProfile,
      ...this.profiles.profiles[this.activeProfile]
    };
  }

  /**
   * Get a specific profile by key
   */
  getProfile(key) {
    return this.profiles.profiles[key] || null;
  }

  /**
   * Switch to a different profile
   * @param {string} profileKey - 'dev', 'content', or 'ops'
   * @param {Object} options - Switch options
   * @returns {Object} Switch result
   */
  async switchProfile(profileKey, options = {}) {
    const now = Date.now();
    const cooldown = this.profiles.global?.profileSwitchCooldownMs || 2000;
    
    // Check cooldown
    if (now - this.lastSwitchTime < cooldown && !options.force) {
      return {
        success: false,
        error: 'Profile switch on cooldown',
        cooldownRemaining: cooldown - (now - this.lastSwitchTime)
      };
    }

    // Validate profile exists
    if (!this.profiles.profiles[profileKey]) {
      return {
        success: false,
        error: `Profile '${profileKey}' not found`,
        availableProfiles: this.getProfileKeys()
      };
    }

    // Already on this profile
    if (this.activeProfile === profileKey && !options.force) {
      return {
        success: true,
        switched: false,
        message: `Already on profile: ${profileKey}`,
        profile: this.getProfile(profileKey)
      };
    }

    const previousProfile = this.activeProfile;
    const profile = this.profiles.profiles[profileKey];

    try {
      // Apply presets to gateway if connected
      if (!options.dryRun) {
        await this.applyPresets(profile.presets, options.gateway);
      }

      // Update active profile
      this.activeProfile = profileKey;
      this.profiles.activeProfile = profileKey;
      this.lastSwitchTime = now;

      // Save configuration
      if (!options.dryRun) {
        this.saveProfiles();
      }

      // Show notification if enabled
      if (this.profiles.global?.showNotifications && !options.silent) {
        this.showNotification(`Switched to ${profile.name} mode`, profile.description);
      }

      return {
        success: true,
        switched: true,
        previousProfile,
        currentProfile: profileKey,
        profile,
        presetsApplied: !options.dryRun
      };
    } catch (e) {
      console.error('[ProfileSwitcher] Switch failed:', e.message);
      return {
        success: false,
        error: e.message,
        previousProfile,
        attemptedProfile: profileKey
      };
    }
  }

  /**
   * Cycle to next profile
   */
  async cycleProfile(direction = 'next', options = {}) {
    const keys = this.getProfileKeys();
    const currentIdx = keys.indexOf(this.activeProfile);
    
    let nextIdx;
    if (direction === 'next') {
      nextIdx = (currentIdx + 1) % keys.length;
    } else {
      nextIdx = (currentIdx - 1 + keys.length) % keys.length;
    }
    
    return this.switchProfile(keys[nextIdx], options);
  }

  /**
   * Apply profile presets to OpenClaw gateway
   */
  async applyPresets(presets, gatewayOverride = null) {
    const gateway = gatewayOverride || this.getCurrentGateway();
    if (!gateway) {
      console.warn('[ProfileSwitcher] No gateway available for preset application');
      return false;
    }

    const results = [];

    // Apply model if specified
    if (presets.model) {
      try {
        const res = await this.callGateway('/session.set', 'POST', { 
          model: presets.model 
        }, gateway);
        results.push({ preset: 'model', success: res.ok });
      } catch (e) {
        results.push({ preset: 'model', success: false, error: e.message });
      }
    }

    // Apply TTS settings
    if (presets.ttsEnabled !== undefined) {
      try {
        const res = await this.callGateway('/config.patch', 'POST', {
          path: 'messages.tts.enabled',
          value: presets.ttsEnabled
        }, gateway);
        results.push({ preset: 'ttsEnabled', success: res.ok });
      } catch (e) {
        results.push({ preset: 'ttsEnabled', success: false, error: e.message });
      }
    }

    // Apply TTS voice if specified
    if (presets.ttsVoice) {
      try {
        const res = await this.callGateway('/config.patch', 'POST', {
          path: 'messages.tts.voice',
          value: presets.ttsVoice
        }, gateway);
        results.push({ preset: 'ttsVoice', success: res.ok });
      } catch (e) {
        results.push({ preset: 'ttsVoice', success: false, error: e.message });
      }
    }

    console.log('[ProfileSwitcher] Applied presets:', results);
    return results.every(r => r.success);
  }

  /**
   * Get current gateway from gateway config
   */
  getCurrentGateway() {
    try {
      const gatewayConfigPath = path.join(CONFIG_DIR, 'streamdeck-gateways.json');
      if (fs.existsSync(gatewayConfigPath)) {
        const config = JSON.parse(fs.readFileSync(gatewayConfigPath, 'utf-8'));
        const active = config.active || 'default';
        return config.gateways?.[active] || { url: 'http://127.0.0.1:18790' };
      }
    } catch (e) {
      console.error('[ProfileSwitcher] Failed to get gateway:', e.message);
    }
    return { url: 'http://127.0.0.1:18790' };
  }

  /**
   * Call OpenClaw gateway API
   */
  async callGateway(path, method = 'GET', body, gateway = null) {
    const gw = gateway || this.getCurrentGateway();
    const url = `${gw.url}${path}`;
    
    try {
      const response = await fetch(url, {
        method,
        headers: {
          'Content-Type': 'application/json',
          ...(gw.token ? { 'Authorization': `Bearer ${gw.token}` } : {})
        },
        ...(body ? { body: JSON.stringify(body) } : {})
      });
      
      const data = await response.json().catch(() => ({}));
      return { ok: response.ok, status: response.status, data };
    } catch (e) {
      return { ok: false, error: e.message };
    }
  }

  /**
   * Show Windows notification
   */
  showNotification(title, message) {
    try {
      // Use PowerShell for notification (Windows)
      const psScript = `
Add-Type -AssemblyName System.Windows.Forms
$global:balloon = New-Object System.Windows.Forms.NotifyIcon
$balloon.Icon = [System.Drawing.SystemIcons]::Information
$balloon.BalloonTipIcon = 'Info'
$balloon.BalloonTipTitle = '${title.replace(/'/g, "''")}'
$balloon.BalloonTipText = '${message.replace(/'/g, "''")}'
$balloon.Visible = $true
$balloon.ShowBalloonTip(3000)
Start-Sleep -Seconds 4
$balloon.Dispose()
`;
      spawn('powershell.exe', ['-Command', psScript], { 
        detached: true, 
        stdio: 'ignore',
        windowsHide: true
      }).unref();
    } catch (e) {
      console.error('[ProfileSwitcher] Notification failed:', e.message);
    }
  }

  /**
   * Get profile for currently focused application
   */
  getProfileForActiveWindow() {
    if (!this.profiles.global?.autoSwitchOnAppFocus) {
      return null;
    }

    try {
      // Get active window process name (requires PowerShell)
      const psScript = `
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class WinAPI {
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
}
"@
$hwnd = [WinAPI]::GetForegroundWindow()
$pid = 0
[void][WinAPI]::GetWindowThreadProcessId($hwnd, [ref]$pid)
$proc = Get-Process -Id $pid -ErrorAction SilentlyContinue
$proc.ProcessName
`;
      
      const result = spawn('powershell.exe', ['-Command', psScript], { 
        encoding: 'utf-8',
        windowsHide: true
      });
      
      // For now, return null as auto-switch requires async handling
      return null;
    } catch (e) {
      console.error('[ProfileSwitcher] Failed to get active window:', e.message);
      return null;
    }
  }

  /**
   * Export profile configuration for Stream Deck
   */
  exportForStreamDeck() {
    const profile = this.getCurrentProfile();
    return {
      active: this.activeProfile,
      name: profile.name,
      icon: profile.icon,
      theme: profile.theme,
      presets: profile.presets,
      shortcuts: profile.shortcuts,
      availableProfiles: this.getProfileKeys().map(key => ({
        key,
        name: this.profiles.profiles[key].name,
        icon: this.profiles.profiles[key].icon
      }))
    };
  }

  /**
   * Get profile status for dashboard
   */
  getStatus() {
    const profile = this.getCurrentProfile();
    return {
      active: this.activeProfile,
      name: profile.name,
      description: profile.description,
      icon: profile.icon,
      theme: profile.theme,
      presets: profile.presets,
      tools: profile.tools,
      lastSwitch: this.lastSwitchTime,
      available: this.getProfileKeys()
    };
  }
}

// Export for use in other modules
module.exports = { ProfileSwitcher };

// If run directly, show status
if (require.main === module) {
  const switcher = new ProfileSwitcher();
  
  const command = process.argv[2];
  const arg = process.argv[3];

  switch (command) {
    case 'status':
      console.log(JSON.stringify(switcher.getStatus(), null, 2));
      break;
    case 'switch':
      switcher.switchProfile(arg || 'dev').then(result => {
        console.log(result.success ? `✓ Switched to ${result.currentProfile}` : `✗ ${result.error}`);
        process.exit(result.success ? 0 : 1);
      });
      break;
    case 'cycle':
      switcher.cycleProfile(arg || 'next').then(result => {
        console.log(result.success ? `✓ Cycled to ${result.currentProfile}` : `✗ ${result.error}`);
        process.exit(result.success ? 0 : 1);
      });
      break;
    case 'export':
      console.log(JSON.stringify(switcher.exportForStreamDeck(), null, 2));
      break;
    default:
      console.log(`
OpenClaw Workspace Profile Switcher v1.1

Usage:
  node profile-switcher.js [command] [arg]

Commands:
  status              Show current profile status
  switch <profile>    Switch to profile (dev|content|ops)
  cycle [next|prev]   Cycle to next/previous profile
  export              Export config for Stream Deck

Examples:
  node profile-switcher.js switch dev
  node profile-switcher.js cycle next
  node profile-switcher.js status
`);
  }
}
