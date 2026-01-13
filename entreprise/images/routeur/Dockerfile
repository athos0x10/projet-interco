FROM debian:stable-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        procps \
        openvpn \
        openvpn-auth-ldap \
        easy-rsa \
        iproute2 \
        iptables \
        apt-utils \
        net-tools \
        systemd \
        telnet \
        iputils-ping \
        nano \
        tcpdump \
        inetutils-traceroute \
        isc-dhcp-client \
        isc-dhcp-server \
        dnsutils \
        slapd \
        ldap-utils \
        alsa-utils \
        dbus-x11 \
        frr \
        frr-pythontools \
        wget && \
    rm -rf /var/lib/apt/lists/*
# Active OSPF
RUN sed -i 's/ospfd=no/ospfd=yes/g' /etc/frr/daemons
RUN mkdir /etc/scripts
ENV PATH "/etc/scripts:$PATH"
RUN echo 'export PS1="\[\e[38;5;196m\]\u\[\e[38;5;202m\]@\[\e[38;5;208m\]\h \[\e[38;5;220m\]\w \[\033[0m\]$ "' >> /root/.bashrc
RUN echo "alias ip='ip -color=auto'" >> /root/.bashrc
CMD ["/bin/bash"]
