#version 0.1

FROM julianxhokaxhiu/docker-awesome-wordpress
MAINTAINER Thibaut SEVERAC

RUN apt update && apt install wget ssl-cert sendmail -y

ENV DEBIAN_FRONTEND noninteractive

#add mod-pagespeed
RUN \
    wget -q https://dl-ssl.google.com/dl/linux/direct/mod-pagespeed-stable_current_amd64.deb && \
    dpkg -i mod-pagespeed-*.deb && \
    apt-get -f install -y && \
    rm mod-pagespeed-*.deb

#add SSL
RUN \
    make-ssl-cert generate-default-snakeoil && \
    usermod --append --groups ssl-cert www-data && \
    ls -l /etc/ssl/certs/ssl-cert-snakeoil.pem /etc/ssl/private/ssl-cert-snakeoil.key && \
    a2enmod ssl && \
    a2ensite default-ssl

#set sendmail
RUN { \
    echo "sendmail_path = /usr/sbin/sendmail -t -i"; \
  } > /usr/local/etc/php/conf.d/mail.ini

RUN update-rc.d sendmail defaults


RUN apt remove --purge -y wget && \
    apt-get autoremove -y && \
    apt-get clean

EXPOSE 80 443