# HaaS (Honeypot as a Service)

![Docker Image Size (latest by date)](https://img.shields.io/docker/image-size/mikromcz/haas?style=flat-square)
![Docker Stars](https://img.shields.io/docker/stars/mikromcz/haas?style=flat-square)
![Docker Pulls](https://img.shields.io/docker/pulls/mikromcz/haas?style=flat-square)
![Docker Image Version (latest semver)](https://img.shields.io/docker/v/mikromcz/haas?style=flat-square)

> **_NOTE:_**  This is just my Docker version as a Docker version from CZ.NIC was discontinued (but can be still installed via pip, deb, rpm).

### What is a honeypot?
Honeypot is a special software which simulates an operating system and allows an attacker to log in via SSH or telnet and execute commands or download malware. Commands are recorded and used to analyze the behavior. Malware can be analyzed as well.

### How does it work?
Volunteers interested in joining the research will register on this site and add the first device to get an identification token.

You install and run the HaaS proxy application, downloadable from our website, which forwards incoming traffic from port 22 (commonly used for SSH) to the HaaS server, where Cowrie honeypot simulates a device and records executed commands.

More information at https://haas.nic.cz.

## Notes

- Version: 2.0.2 (2020-07-29)
- You can consider using separate network in Docker, or maybe an own IP address by using macvlan.

## Installation

1. Forward your port `22` from WAN to the port `2222` of the Docker machine.
2. Obtain `DEVICE_TOKEN` for your session and put it instead `<YOUR_TOKEN>`.
3. `LOG_LEVEL` parameter is optional. If not set `LOG_LEVEL=info` is used.
4. Run Docker container

#### **Docker Compose**
```yaml
version: "3"
services:
  haas:
    container_name: haas
    image: mikromcz/haas
    restart: unless-stopped
    environment:
      - DEVICE_TOKEN=<YOUR_TOKEN>
      - LOG_LEVEL=<error,warning,debug,info>
    ports:
      - 2222:2222
```
#### **Docker**
```bash
docker run -d \
  --name haas \
  --restart=unless-stopped \
  -e "DEVICE_TOKEN=<YOUR_TOKEN>" \
  -e "LOG_LEVEL=<error,warning,debug,info>" \
  -p 2222:2222 \
  mikromcz/haas
```
