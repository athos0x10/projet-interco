FROM debian:stable-slim
RUN apt-get update
RUN yes | apt-get -y install iptables apt-utils iproute2 net-tools systemd telnet nano iputils-ping tcpdump inetutils-traceroute isc-dhcp-server isc-dhcp-client
RUN apt-get -f install
RUN mkdir /etc/scripts
ENV PATH "/etc/scripts:$PATH"
RUN echo 'export PS1="\[\e[38;5;196m\]\u\[\e[38;5;202m\]@\[\e[38;5;208m\]\h \[\e[38;5;220m\]\w \[\033[0m\]$ "' >> /root/.bashrc
RUN echo "alias ip='ip -color=auto'" >> /root/.bashrc
CMD ["/bin/bash"]