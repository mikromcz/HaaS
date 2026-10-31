# HaaS (Honeypot as a Service) Proxy Dockerfile
# v20261031

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

# Upgrade base image packages to pick up security fixes, then install necessary packages
# haas_proxy calls "sshpass ... ssh" to connect to the HaaS server - only SSH client is needed, not sshd
RUN apk upgrade --no-cache && \
    apk add --no-cache openssh-client sshpass

# Install haas_proxy and its dependencies (twisted, requests, cachetools)
RUN pip3 install --no-cache-dir --upgrade haas-proxy && \
    # Pre-generate Twisted plugin cache (dropin.cache) as root, so non-root user
    # doesn't need write access to site-packages (replaces former chmod 777).
    # Same sys.path tweak as haas_proxy/__main__.py, so haas_proxy/twisted/plugins is included too
    python3 -c "import sys, sysconfig; sys.path.append(sysconfig.get_paths()['purelib'] + '/haas_proxy'); from twisted.plugin import IPlugin, getPlugins; list(getPlugins(IPlugin))" && \
    # pip is not needed at runtime. Its vendored libs (setuptools, msgpack, urllib3...)
    # are the only findings in vulnerability scans, so remove it completely
    pip3 uninstall -y pip && \
    rm -rf /root/.cache

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

# Run as non-root user. Nothing needs to be writable (no PID file, logs go to stdout)
RUN adduser -D -u 1000 -s /sbin/nologin haas
USER haas

# Expose haas port
EXPOSE 2222

# Healthcheck to see if haas_proxy is running
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s \
    CMD pgrep -f "haas_proxy" || exit 1

# Final command. Without square brackets it is run from shell, bracketed version never work for me.
# --pidfile '' disables PID file (not needed in container, healthcheck uses pgrep)
CMD ["sh", "-c", "python3 -m haas_proxy --nodaemon --pidfile '' haas_proxy --device-token ${DEVICE_TOKEN} --log-level ${LOG_LEVEL}"]
