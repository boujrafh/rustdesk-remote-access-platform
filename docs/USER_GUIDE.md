# RustDesk User Guide

Welcome to RustDesk! This guide will help you connect to and use the remote desktop platform.

## Table of Contents

1. [Getting Started](#getting-started)
2. [Installing the Client](#installing-the-client)
3. [Configuring the Connection](#configuring-the-connection)
4. [Connecting to a Remote Computer](#connecting-to-a-remote-computer)
5. [Features & Controls](#features--controls)
6. [Troubleshooting](#troubleshooting)
7. [Security Tips](#security-tips)
8. [FAQ](#faq)

---

## Getting Started

RustDesk is a remote desktop application that allows you to access and control computers from anywhere securely. Before you begin, you'll need:

- **Your Server Address**: Provided by your IT administrator (e.g., rustdesk.yourdomain.com)
- **Your Login Credentials**: If Active Directory is enabled, use your company username and password
- **RustDesk Client**: Download from the official website or your IT department

---

## Installing the Client

### Windows

1. Download RustDesk installer from:
   - Official: https://rustdesk.com/
   - Or: Contact your IT administrator for the company-approved version

2. Run the installer `rustdesk-x.x.x-x86_64.exe`

3. Follow the installation wizard:
   - Click "Next" through the setup
   - Choose installation location (default recommended)
   - Select "Install"

4. Launch RustDesk from Desktop or Start Menu

### macOS

1. Download RustDesk for Mac: `rustdesk-x.x.x.dmg`

2. Open the .dmg file

3. Drag RustDesk to Applications folder

4. First launch:
   - Right-click RustDesk in Applications
   - Select "Open"
   - Click "Open" in the security dialog

### Linux

#### Ubuntu/Debian

```bash
# Download .deb package
wget https://github.com/rustdesk/rustdesk/releases/download/x.x.x/rustdesk-x.x.x-x86_64.deb

# Install
sudo dpkg -i rustdesk-x.x.x-x86_64.deb

# Install dependencies if needed
sudo apt-get install -f
```

#### Fedora/RHEL

```bash
# Download .rpm package
wget https://github.com/rustdesk/rustdesk/releases/download/x.x.x/rustdesk-x.x.x-x86_64.rpm

# Install
sudo dnf install rustdesk-x.x.x-x86_64.rpm
```

### Mobile (Android/iOS)

1. **Android**: Download from Google Play Store or company portal
2. **iOS**: Download from Apple App Store

---

## Configuring the Connection

### First-Time Setup

1. **Launch RustDesk**

2. **Open Settings** (Click the menu icon ⋮ or gear ⚙️)

3. **Configure Network**:
   - Click on "Network" or "ID/Relay Server"
   - Enter your server details:

   ```
   ID Server: rustdesk.yourdomain.com:21116
   Relay Server: rustdesk.yourdomain.com:21117
   API Server: https://rustdesk.yourdomain.com (optional)
   Key: (Leave blank or enter if provided by IT)
   ```

4. **Click "OK"** or "Apply"

5. The connection indicator should turn green ✓

### Configuration Screenshot Guide

```
┌─────────────────────────────────────┐
│  RustDesk Settings                  │
├─────────────────────────────────────┤
│  ID/Relay Server                    │
│  ┌───────────────────────────────┐ │
│  │ ID Server:                    │ │
│  │ rustdesk.yourdomain.com:21116 │ │
│  └───────────────────────────────┘ │
│  ┌───────────────────────────────┐ │
│  │ Relay Server:                 │ │
│  │ rustdesk.yourdomain.com:21117 │ │
│  └───────────────────────────────┘ │
│  ┌───────────────────────────────┐ │
│  │ API Server (optional):        │ │
│  │ https://rustdesk.yourdomain   │ │
│  └───────────────────────────────┘ │
│                                     │
│  [ Test Connection ]  [ OK ]        │
└─────────────────────────────────────┘
```

### Getting Your ID

After configuration, your unique RustDesk ID will be displayed on the main screen:

```
Your Desktop ID: 123456789
Password: abc123
```

**Share this ID** with someone who needs to connect to your computer.

---

## Connecting to a Remote Computer

### Method 1: Direct Connection (ID)

1. **Open RustDesk**

2. **Enter Remote ID**:
   - In the "Remote ID" field, type the ID of the computer you want to connect to
   - Example: `987654321`

3. **Click "Connect"**

4. **Enter Password**:
   - If prompted, enter the remote computer's password
   - Or use your Active Directory credentials (if configured)

5. **Wait for Connection**:
   - The remote desktop will appear in a new window

### Method 2: Address Book (Saved Connections)

1. **Click "Address Book"** (book icon 📖)

2. **Add New Contact**:
   - Click "+" or "Add"
   - Enter:
     - Name: Friendly name (e.g., "Office PC")
     - ID: Remote computer's RustDesk ID
     - Username: (Optional) Your username
     - Tags: (Optional) For organization

3. **Connect**:
   - Double-click the saved connection
   - Enter password if prompted

### Method 3: Web Console (If Enabled)

1. Open browser: `https://rustdesk.yourdomain.com`

2. Log in with your credentials

3. Browse available computers

4. Click "Connect" on desired computer

---

## Features & Controls

### During a Remote Session

#### Toolbar Icons

| Icon | Function | Shortcut |
|------|----------|----------|
| 🖱️ | Mouse Control | Default |
| ⌨️ | Keyboard Input | Click to focus |
| 📋 | Clipboard Sync | Ctrl+C / Ctrl+V |
| 📁 | File Transfer | Click to open |
| 💬 | Chat | Alt+C |
| 🔊 | Audio | Toggle sound |
| 📹 | Record Session | (if enabled) |
| ⚙️ | Settings | Adjust quality |
| 🔒 | Lock Screen | Lock remote PC |
| ⏸️ | Minimize | Hide window |
| ❌ | Disconnect | End session |

### File Transfer

1. **During Remote Session**:
   - Click the 📁 File Transfer icon
   - Or press `Ctrl+Shift+F`

2. **Transfer Window**:
   - Left panel: Your computer
   - Right panel: Remote computer

3. **To Send Files**:
   - Select file on left panel
   - Click "→ Send" or drag to right panel

4. **To Receive Files**:
   - Select file on right panel
   - Click "← Receive" or drag to left panel

### Clipboard Sharing

- **Enable**: Settings → "Clipboard" → "Enable clipboard sync"
- **Usage**: Copy/paste works automatically between computers
- **Text**: Ctrl+C / Ctrl+V
- **Files**: Copy files, paste in remote session

### Chat Function

1. Click 💬 Chat icon or press `Alt+C`

2. Type message in text box

3. Press Enter to send

4. Useful for:
   - Asking questions to the remote user
   - Sending instructions
   - Notifying before disconnecting

### Quality & Performance Settings

**Adjust during session**:

1. Click ⚙️ Settings icon

2. **Image Quality**:
   - Low (faster, pixelated)
   - Medium (balanced)
   - High (slower, clearer)
   - Best (requires fast connection)

3. **FPS (Frames Per Second)**:
   - 10 FPS: Slow connections
   - 30 FPS: Normal work
   - 60 FPS: Smooth, requires good bandwidth

4. **Codec**:
   - VP8: Better compatibility
   - VP9: Better compression
   - H264/H265: Hardware acceleration (if available)

### Multi-Monitor Support

If remote computer has multiple monitors:

1. Click "Display" or monitor icon

2. Select which screen to view:
   - Screen 1
   - Screen 2
   - All Screens (side by side)

3. Switch between monitors during session

---

## Troubleshooting

### Cannot Connect to Server

**Symptom**: "Connection failed" or "ID Server offline"

**Solutions**:

1. **Check Internet Connection**:
   ```
   - Open browser
   - Visit https://rustdesk.yourdomain.com
   - If webpage loads, network is OK
   ```

2. **Verify Server Address**:
   - Settings → ID/Relay Server
   - Confirm: `rustdesk.yourdomain.com:21116`
   - No extra spaces or characters

3. **Firewall/VPN**:
   - Disable VPN temporarily
   - Check corporate firewall settings
   - Contact IT if behind proxy

4. **Test Connection**:
   ```bash
   # On Windows (Command Prompt)
   telnet rustdesk.yourdomain.com 21116
   
   # On macOS/Linux
   nc -zv rustdesk.yourdomain.com 21116
   ```

### Black Screen / No Display

**Symptom**: Connected but see black screen

**Solutions**:

1. **Wait 5-10 seconds** (remote PC may be waking up)

2. **Check Remote PC**:
   - Ensure it's powered on
   - Not in sleep/hibernation mode

3. **Change Display Quality**:
   - Settings → Lower quality
   - Try different codec

4. **Restart RustDesk** on both computers

### Slow Performance / Lag

**Symptom**: Delayed mouse/keyboard, choppy video

**Solutions**:

1. **Reduce Quality**:
   - Settings → Image Quality: Low
   - FPS: 10-15

2. **Close Other Applications**:
   - On both local and remote PC
   - Especially browsers and video players

3. **Check Network Speed**:
   - Minimum: 1 Mbps
   - Recommended: 5+ Mbps
   - Test: speedtest.net

4. **Use Wired Connection**:
   - Ethernet instead of WiFi (if possible)

### Authentication Failed

**Symptom**: "Wrong password" or "Authentication error"

**Solutions**:

1. **Verify Credentials**:
   - Check username (if using AD)
   - Verify password (case-sensitive)
   - Check Caps Lock

2. **Reset Remote Password**:
   - On remote PC, open RustDesk
   - Click "Set permanent password"
   - Enter new password

3. **Active Directory Users**:
   - Use: `username` (not email)
   - Domain: Usually auto-detected
   - If fails: `DOMAIN\username`

4. **Contact IT**:
   - Account may be locked
   - Password expired

### Audio Not Working

**Symptom**: No sound from remote computer

**Solutions**:

1. **Enable Audio**:
   - Click 🔊 icon in toolbar
   - Ensure not muted

2. **Check Remote PC**:
   - Volume not muted
   - Audio device working

3. **Update RustDesk**:
   - Audio requires recent version
   - Update both client and server

### File Transfer Fails

**Symptom**: Files won't send/receive

**Solutions**:

1. **Check File Size**:
   - Large files (>1GB) may timeout
   - Split into smaller chunks

2. **Permissions**:
   - Write access to destination folder
   - Not transferring to system directories

3. **Antivirus**:
   - May block file transfer
   - Temporarily disable or add exception

4. **Use Alternative**:
   - Shared network drive
   - Cloud storage (OneDrive, Google Drive)

---

## Security Tips

### 🔒 Protect Your Account

1. **Strong Passwords**:
   - Minimum 12 characters
   - Mix of letters, numbers, symbols
   - Don't reuse passwords

2. **Permanent Password**:
   - Set a permanent password for unattended access
   - Settings → Security → "Set permanent password"

3. **Two-Factor Authentication** (if available):
   - Enable in Security settings
   - Requires additional code on login

### 🛡️ Safe Remote Access

1. **Verify Connection Requests**:
   - Unexpected connection? Don't accept
   - Confirm identity via phone/email first

2. **Monitor Active Sessions**:
   - Check who's connected
   - Disconnect unknown sessions

3. **Lock When Away**:
   - Lock your PC before leaving
   - Windows: `Win+L`
   - macOS: `Ctrl+Cmd+Q`

4. **End Sessions Properly**:
   - Don't just close window
   - Click Disconnect button
   - Verify session ended

### 🚨 Recognize Phishing

**Beware of**:
- Emails asking for RustDesk credentials
- Fake RustDesk login pages
- Unsolicited connection requests

**Legitimate**:
- IT will NEVER ask for your password via email
- Always use official company server
- Verify requests through official channels

### 📢 Reporting Security Concerns

If you notice:
- Unauthorized access
- Suspicious activity
- Account compromise

**Immediately**:
1. Disconnect from RustDesk
2. Change your password
3. Contact IT Security: security@yourdomain.com
4. Report incident details

---

## FAQ

### General Questions

**Q: Is RustDesk free?**  
A: The client is open-source and free. Your company hosts the server.

**Q: Can I use RustDesk from home?**  
A: Yes, if allowed by your company policy. Check with IT.

**Q: Does RustDesk work on mobile?**  
A: Yes, Android and iOS apps are available.

**Q: How many monitors can I view?**  
A: All monitors on the remote computer, viewable individually or together.

**Q: Can I print from a remote session?**  
A: Yes, printers should be accessible through the remote computer.

### Technical Questions

**Q: What ports does RustDesk use?**  
A: TCP 21116 (ID server), TCP 21117 (Relay server). Your IT admin configures these.

**Q: Is the connection encrypted?**  
A: Yes, RustDesk uses end-to-end encryption for all connections.

**Q: Can IT see my screen during remote sessions?**  
A: Only if they initiate a connection to your computer (with your permission).

**Q: What's the difference between ID and Relay servers?**  
A: ID server helps establish connections, Relay server transfers data when direct connection isn't possible.

**Q: Will RustDesk work behind a firewall?**  
A: Usually yes, but corporate firewalls may require IT configuration.

### Usage Questions

**Q: Can I transfer folders?**  
A: Yes, but it's faster to zip the folder first, then transfer the .zip file.

**Q: Can multiple people connect to one computer?**  
A: Yes, if configured for multiple sessions. Check with IT.

**Q: Can I use RustDesk for gaming?**  
A: Not recommended. RustDesk is optimized for productivity, not low-latency gaming.

**Q: How do I permanently connect to my office PC?**  
A: Set a permanent password on your office PC, save it in Address Book on your home PC.

**Q: Can I schedule remote access?**  
A: Not directly, but you can ensure the remote PC is always on and RustDesk starts with Windows.

---

## Quick Reference Card

### Connection Quick Start

```
1. Open RustDesk
2. Enter Remote ID
3. Click Connect
4. Enter Password
5. Start Working!
```

### Keyboard Shortcuts

| Action | Windows/Linux | macOS |
|--------|---------------|-------|
| File Transfer | Ctrl+Shift+F | Cmd+Shift+F |
| Chat | Alt+C | Option+C |
| Minimize | Ctrl+M | Cmd+M |
| Disconnect | Ctrl+D | Cmd+D |
| Refresh | Ctrl+R | Cmd+R |
| Fullscreen | F11 | Cmd+Ctrl+F |
| Settings | Ctrl+, | Cmd+, |

### Support Contacts

- **IT Help Desk**: helpdesk@yourdomain.com
- **Phone**: +1-XXX-XXX-XXXX
- **Internal Portal**: https://support.yourdomain.com
- **Emergency**: XXX-XXXX (24/7)

---

## Getting Help

### Self-Service Resources

1. **This User Guide** - Covers most common scenarios
2. **Company Intranet** - Internal knowledge base
3. **Video Tutorials** - Available on company portal

### Contacting Support

**Before contacting IT**:
- ✓ Check this guide
- ✓ Restart RustDesk
- ✓ Test internet connection
- ✓ Note error messages

**When contacting support, provide**:
- Your RustDesk ID
- Remote computer ID (if connecting)
- Error message (screenshot if possible)
- What you were trying to do
- Steps to reproduce the issue

**Response Times**:
- Critical (system down): 1 hour
- High (cannot work): 4 hours
- Normal (inconvenience): 1 business day
- Low (question): 2 business days

---

**Document Version**: 1.0  
**Last Updated**: November 2025  
**For**: End Users  

**Need help?** Contact IT Support: helpdesk@yourdomain.com
