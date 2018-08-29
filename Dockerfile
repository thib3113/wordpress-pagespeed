#version 0.1

FROM julianxhokaxhiu/docker-awesome-wordpress
MAINTAINER Thibaut SEVERAC

RUN apt update && apt install wget -y

#add mod-pagespeed
RUN \
    wget https://dl-ssl.google.com/dl/linux/direct/mod-pagespeed-stable_current_amd64.deb && \
    dpkg -i mod-pagespeed-*.deb && \
    apt-get -f install -y && \
    rm mod-pagespeed-*.deb

RUN apt remove --purge -y wget && apt autoremove -y && apt clean