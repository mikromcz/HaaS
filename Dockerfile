# Use Alpine with preinstalled Python is the easiest
FROM python:3.12-alpine

# Dirty workaround for pip warnings about running under the root user
ENV PIP_ROOT_USER_ACTION="ignore"

# Supress deprecation Warnings from HaaS - not working :/
# /usr/local/lib/python3.12/site-packages/twisted/conch/ssh/transport.py:106: CryptographyDeprecationWarning: Blowfish has been deprecated
# /usr/local/lib/python3.12/site-packages/twisted/conch/ssh/transport.py:110: CryptographyDeprecationWarning: CAST5 has been deprecated
# /usr/local/lib/python3.12/site-packages/twisted/conch/ssh/transport.py:115: CryptographyDeprecationWarning: Blowfish has been deprecated
# /usr/local/lib/python3.12/site-packages/twisted/conch/ssh/transport.py:116: CryptographyDeprecationWarning: CAST5 has been deprecated
ENV PYTHONWARNINGS="ignore:.*:DeprecationWarning"

# Supress "CRITICAL twisted 'channel open failed, direct-tcpip is not allowed'" message - no solution :/
# https://forum.turris.cz/t/haas-proxy-channel-failed/14699
# https://gitlab.nic.cz/haas/proxy/-/issues/19

# Set a default LOG_LEVEL if not provided
ENV LOG_LEVEL=info

# Update and install necessary packages
RUN apk add --update --no-cache openssh sshpass

# Install haas_proxy
RUN pip3 install --upgrade pip
RUN pip3 install --no-cache haas-proxy

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

# Those labels are added during build to be sure they are correct
# $ docker build -t haas --label "org.opencontainers.image.version"="2.0.2" --label "org.opencontainers.image.created"="$(date +'%m/%d/%Y')" .

# Run as non-root user, but we have to add permisions for /haas/haas.pid file (and twisted plugins)
RUN chmod -R 777 /usr/local/lib/python3.12/site-packages/twisted/plugins/ /usr/local/lib/python3.12/site-packages/haas_proxy/twisted/plugins/ && \
    mkdir /haas && \
    adduser -D haas && \
    chown haas -R /haas
USER haas

# Expose haas port
EXPOSE 2222

# Final command. Without square brackets it is run from shell, bracketed version never work for me.
# python[3] -m haas_proxy --pidfile /var/run/haas.pid haas_proxy -l /var/log/haas.log --log-level warning --device-token XXX

# The form with brackets is generally used for commands that don't require shell processing. 
# If your Twisted application is not working with the array form, it might be due to the way it handles arguments.
# In this case, you can use the shell form of CMD and specify your command as a single string
#CMD ["python3", "-m", "haas_proxy", "--nodaemon", "haas_proxy", "--device-token", "${DEVICE_TOKEN}"]

#CMD python3 -m haas_proxy --nodaemon --pidfile /haas/haas.pid haas_proxy --device-token ${DEVICE_TOKEN}
CMD python3 -m haas_proxy --nodaemon --pidfile /haas/haas.pid haas_proxy --device-token ${DEVICE_TOKEN} --log-level $LOG_LEVEL | tee /proc/1/fd/1
