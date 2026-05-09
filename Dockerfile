# HaaS (Honeypot as a Service) Proxy Dockerfile
# v202600509

# Use Alpine with preinstalled Python is the easiest
FROM python:3.14-alpine

# Dirty workaround for pip warnings about running under the root user
ENV PIP_ROOT_USER_ACTION="ignore"

# Supress deprecation Warnings from HaaS - not working :/
# /usr/local/lib/python3.*/site-packages/twisted/conch/ssh/transport.py:106: CryptographyDeprecationWarning: Blowfish has been deprecated
# /usr/local/lib/python3.*/site-packages/twisted/conch/ssh/transport.py:110: CryptographyDeprecationWarning: CAST5 has been deprecated
# /usr/local/lib/python3.*/site-packages/twisted/conch/ssh/transport.py:115: CryptographyDeprecationWarning: Blowfish has been deprecated
# /usr/local/lib/python3.*/site-packages/twisted/conch/ssh/transport.py:116: CryptographyDeprecationWarning: CAST5 has been deprecated
ENV PYTHONWARNINGS="ignore:.*:DeprecationWarning"

# Supress "CRITICAL twisted 'channel open failed, direct-tcpip is not allowed'" message - no solution :/
# https://forum.turris.cz/t/haas-proxy-channel-failed/14699
# https://gitlab.nic.cz/haas/proxy/-/issues/19
ENV TWISTED_LOG_LEVEL="error"

# Set a default LOG_LEVEL if not provided
ENV LOG_LEVEL=info

# Update and install necessary packages
RUN apk add --update --no-cache openssh sshpass

# Install haas_proxy
RUN pip3 install --upgrade pip && \
    pip3 install --no-cache haas-proxy

# Some labels with credit to CZ.NIC
LABEL org.opencontainers.image.title="HaaS (Honeypot as a Service)"
LABEL org.opencontainers.image.description=" \
    It does not matter whether you are a volunteer, an organization or a company. \
    Anyone can participate in research project Honeypot as a Service (HaaS) and \
    contribute to the improvement of cyber security and preparedness for cyber attacks. \
    Additionally, you will learn interesting facts about the attacks made on your device."
LABEL org.opencontainers.image.url=https://haas.nic.cz
LABEL org.opencontainers.image.source=https://gitlab.nic.cz/haas/proxy/
LABEL org.opencontainers.image.licenses=GPL-3.0
LABEL org.opencontainers.image.base.name=python:alpine

# Those labels are added during build to be sure they are up to date
# $ docker build -t haas --label "org.opencontainers.image.version"="2.0.2" --label "org.opencontainers.image.created"="$(date +'%m/%d/%Y')" .

# Create working directory
WORKDIR /haas

# Run as non-root user, but we have to add permisions for /haas/haas.pid file (and twisted plugins)
RUN chmod -R 777 /usr/local/lib/python3.*/site-packages/twisted/plugins/ /usr/local/lib/python3.*/site-packages/haas_proxy/twisted/plugins/ && \
    adduser -D haas && \
    chown haas -R /haas
USER haas

# Expose haas port
EXPOSE 2222

# Healthcheck to see if cron is running
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s \
    CMD pgrep -f "haas_proxy" || exit 1

# Final command. Without square brackets it is run from shell, bracketed version never work for me.
CMD ["sh", "-c", "python3 -m haas_proxy --nodaemon --pidfile /haas/haas.pid haas_proxy --device-token ${DEVICE_TOKEN} --log-level ${LOG_LEVEL}"]
