# HaaS (Honeypot as a Service) Docker Container

![Docker Image Size (latest by date)](https://img.shields.io/docker/image-size/mikromcz/haas?style=flat-square)
![Docker Stars](https://img.shields.io/docker/stars/mikromcz/haas?style=flat-square)
![Docker Pulls](https://img.shields.io/docker/pulls/mikromcz/haas?style=flat-square)
![Docker Image Version (latest semver)](https://img.shields.io/docker/v/mikromcz/haas?style=flat-square)

> **Note:** This is an unofficial Docker implementation of CZ.NIC's HaaS proxy. The official Docker version was discontinued, but the service remains available via pip, deb, and rpm packages.

## Overview

**HaaS (Honeypot as a Service)** is a research project by [CZ.NIC](https://nic.cz) that allows anyone to contribute to cybersecurity research by running SSH/Telnet honeypots. This Docker container makes it easy to participate in the project.

### What is a Honeypot?

A honeypot is specialized software that simulates a vulnerable system to attract and monitor cyber attacks. It acts like a decoy, allowing attackers to connect via SSH or Telnet, execute commands, and download malware - all while secretly recording their activities for security research.

### How HaaS Works

1. **You register** at [haas.nic.cz](https://haas.nic.cz) and obtain a device token
2. **HaaS proxy** (this container) forwards incoming SSH traffic from port 22 to CZ.NIC's servers
3. **Cowrie honeypot** on CZ.NIC's infrastructure simulates a real system and logs attacker behavior
4. **Research data** helps improve cybersecurity understanding and defense mechanisms

### Why Participate?

- **Contribute to cybersecurity research** and help protect the internet
- **Learn about attack patterns** targeting your region/network
- **Zero maintenance** - the honeypot simulation runs on CZ.NIC's servers
- **Privacy-focused** - only attack data is collected, not your personal traffic

## Quick Start

### Prerequisites

- Docker and Docker Compose installed
- Port 22 accessible from the internet (port forwarding configured)
- Device token from [haas.nic.cz](https://haas.nic.cz)

### Getting Your Device Token

1. Visit [haas.nic.cz](https://haas.nic.cz)
2. Register for an account
3. Add a new device to get your unique `DEVICE_TOKEN`

### Installation

#### Option 1: Docker Compose (Recommended)

Create a `docker-compose.yml` file:

```yaml
version: "3.8"
services:
  haas:
    container_name: haas
    image: mikromcz/haas:latest
    restart: unless-stopped
    hostname: haas
    security_opt:
      - no-new-privileges:true
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Prague  # Adjust to your timezone
      - DEVICE_TOKEN=YOUR_DEVICE_TOKEN_HERE
      - LOG_LEVEL=info    # Options: error, warning, info, debug
    ports:
      - "2222:2222"
    networks:
      - haas_network

networks:
  haas_network:
    driver: bridge
```

Run with:
```bash
docker-compose up -d
```

#### Option 2: Docker Command

```bash
docker run -d \
  --name haas \
  --restart=unless-stopped \
  --security-opt=no-new-privileges:true \
  -e "DEVICE_TOKEN=YOUR_DEVICE_TOKEN_HERE" \
  -e "LOG_LEVEL=info" \
  -e "TZ=Europe/Prague" \
  -p 2222:2222 \
  mikromcz/haas:latest
```

## Network Configuration

### Port Forwarding

**Critical:** You must forward external port 22 (SSH) to the container's port 2222:

- **Router/Firewall:** WAN port 22 → Docker host port 2222
- **Docker:** Host port 2222 → Container port 2222

```
Internet (port 22) → Router → Docker Host (port 2222) → Container (port 2222)
```

### Firewall Considerations

- Allow incoming TCP traffic on port 22 from the internet
- Ensure your real SSH service is either moved to a different port or properly secured
- Consider using a dedicated IP address or VLAN for the honeypot

## Configuration

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `DEVICE_TOKEN` | ✅ Yes | - | Your unique device token from haas.nic.cz |
| `LOG_LEVEL` | ❌ No | `info` | Logging verbosity: `error`, `warning`, `info`, `debug` |
| `TZ` | ❌ No | `UTC` | Container timezone |
| `PUID` | ❌ No | `1000` | User ID for running the service |
| `PGID` | ❌ No | `1000` | Group ID for running the service |

## Monitoring and Logs

### Viewing Logs

```bash
# Real-time logs
docker logs -f haas

# Recent logs
docker logs --tail 50 haas
```

### Expected Log Messages

**Normal operation:**
```
2025-09-07T19:30:15 info Starting HaaS proxy...
2025-09-07T19:30:16 info Connected to HaaS server
2025-09-07T19:30:17 info Listening on port 2222
```

**Note:** You may see occasional error messages like:
- `CRITICAL twisted 'channel open failed, direct-tcpip is not allowed'`
- `Unhandled Error` in SSH transport

These are **normal** and indicate your honeypot is receiving and rejecting malicious connection attempts.

### Verifying Operation

1. **Check container status:** `docker ps` should show the container running
2. **Test connectivity:** `telnet your-ip 22` should connect
3. **Monitor dashboard:** Check [haas.nic.cz](https://haas.nic.cz) for recorded sessions

## Security Considerations

⚠️ **Important Security Notes:**

- **Move your real SSH service** to a different port (e.g., 2223) before deploying
- **This honeypot will attract attackers** to your IP address
- **Use a dedicated network segment** if possible (Docker macvlan or separate VLAN)
- **Monitor your logs** for any unexpected activity
- **Keep your real systems updated** and secure

## Troubleshooting

### Common Issues

**Container won't start:**
- Check if port 2222 is already in use: `netstat -tlnp | grep 2222`
- Verify your `DEVICE_TOKEN` is correct

**No connections being logged:**
- Confirm port forwarding is configured correctly
- Check firewall rules allow incoming connections on port 22
- Test external connectivity: `nmap -p22 your-external-ip`

**High CPU/memory usage:**
- This is normal during active attacks
- Consider lowering `LOG_LEVEL` to `error` to reduce log verbosity

### Getting Help

- **HaaS Issues:** Contact [CZ.NIC support](https://haas.nic.cz)
- **Docker Issues:** Check container logs and GitHub issues
- **Network Issues:** Verify port forwarding and firewall configuration

## Contributing

This is an unofficial Docker implementation. For:
- **Issues with this Docker container:** Open an issue on this repository
- **HaaS service issues:** Contact CZ.NIC directly
- **Feature requests:** Consider contributing via pull request

## Legal and Privacy

- **Data collected:** Only attack traffic directed at the honeypot
- **Your privacy:** Personal traffic is not intercepted or logged
- **Legal compliance:** Ensure honeypot deployment complies with local laws
- **Terms of service:** Review CZ.NIC's terms at [haas.nic.cz](https://haas.nic.cz)

## Version Information

- **Current Version:** 2.0.2 (released 2020-07-29)
- **Base Image:** `python:3.12-alpine`
- **HaaS Proxy:** Latest version from PyPI

## Links

- **HaaS Website:** https://haas.nic.cz
- **CZ.NIC:** https://nic.cz
- **Source Code:** https://gitlab.nic.cz/haas/proxy/
- **Docker Hub:** https://hub.docker.com/r/mikromcz/haas

---

**Disclaimer:** This project is not officially affiliated with CZ.NIC. It's a community-maintained Docker implementation of their HaaS proxy service.