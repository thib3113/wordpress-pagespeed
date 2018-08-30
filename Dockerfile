#version 0.1

FROM julianxhokaxhiu/docker-awesome-wordpress
MAINTAINER Thibaut SEVERAC

RUN apt update && apt install wget -y

ENV DEBIAN_FRONTEND noninteractive

#add mod-pagespeed
RUN \
    wget -q https://dl-ssl.google.com/dl/linux/direct/mod-pagespeed-stable_current_amd64.deb && \
    dpkg -i mod-pagespeed-*.deb && \
    apt-get -f install -y && \
    rm mod-pagespeed-*.deb

#add SSL
RUN \
    apt-get install ssl-cert && \
    make-ssl-cert generate-default-snakeoil && \
    usermod --append --groups ssl-cert www-data && \
    ls -l /etc/ssl/certs/ssl-cert-snakeoil.pem /etc/ssl/private/ssl-cert-snakeoil.key && \
    a2enmod ssl && \
    a2ensite default-ssl

RUN apt remove --purge -y wget && \
    apt-get autoremove -y && \
    apt-get clean

EXPOSE 80 443