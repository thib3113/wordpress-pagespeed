#version 8.2
FROM php:8.1-apache

LABEL org.opencontainers.image.authors="Thibaut SEVERAC"

ENV DEBIAN_FRONTEND noninteractive

# enable extra Apache modules
RUN a2enmod rewrite \
  && a2enmod headers \
  && a2enmod ldap \
  && a2enmod authnz_ldap

# Disable Certification validation for LDAP ( may be required if LDAPS is behind a custom self-signed certificate )
#RUN echo -e "\nTLS_REQCERT never\n" >> /etc/ldap/ldap.conf

# Install required dependencies
RUN apt-get update \
  && apt upgrade -y \
  && apt-get install -y --no-install-recommends \
  git zip zlib1g-dev libpng-dev libjpeg-dev libxml2-dev libxslt-dev libgraphicsmagick1-dev graphicsmagick libldap2-dev mcrypt libmcrypt-dev libltdl7 mariadb-client gnupg wget ssl-cert sendmail libzip-dev unzip

# install APCu from PECL
RUN pecl -vvv install apcu && docker-php-ext-enable apcu

# install GMagick from PECL
RUN pecl -vvv install gmagick-beta && docker-php-ext-enable gmagick

# install mcrypt
RUN pecl -vvv install mcrypt-1.0.5 && docker-php-ext-enable mcrypt

# install wddx
RUN wget https://github.com/php/pecl-text-wddx/archive/master.zip -O wddx.zip \
  && unzip wddx.zip \
  && mkdir -p /usr/src/php/ext/wddx \
  && cd pecl-text-wddx-master \
  && mv * /usr/src/php/ext/wddx \
  && cd .. \
  && rm -Rf wddx.zip pecl-text-wddx-master \
  && docker-php-ext-install wddx

# install the PHP extensions we need
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
  && docker-php-ext-configure ldap --with-libdir=lib/$(gcc --dumpmachine)/ \
  && docker-php-ext-install gd mysqli pdo pdo_mysql opcache gettext exif calendar soap sockets ldap zip

# Download WordPress CLI
RUN curl -L "https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar" > /usr/bin/wp \
  && chmod +x /usr/bin/wp

# Download Composer CLI
RUN curl --silent --show-error https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer \
  && chmod +x /usr/bin/composer

# NodeJS Build Stack dependencies
RUN mkdir -p /usr/share/man/man1 \
  && apt-get install -y ca-certificates-java openjdk-11-jre-headless libbatik-java \
  && curl -sL https://deb.nodesource.com/setup_lts.x | bash - \
  && apt-get install -y nodejs fontforge \
  && npm i -g ttf2eot \
  && rm -rf /var/lib/apt/lists/*

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
  echo 'opcache.memory_consumption=128'; \
  echo 'opcache.interned_strings_buffer=8'; \
  echo 'opcache.max_accelerated_files=4000'; \
  echo 'opcache.revalidate_freq=60'; \
  echo 'opcache.fast_shutdown=1'; \
  echo 'opcache.enable_cli=1'; \
  } > /usr/local/etc/php/conf.d/opcache-recommended.ini

# increase upload size
# see http://php.net/manual/en/ini.core.php
RUN { \
  echo "upload_max_filesize = 25M"; \
  echo "post_max_size = 50M"; \
  } > /usr/local/etc/php/conf.d/uploads.ini

# Iron the security of the Docker
RUN { \
  echo "expose_php = Off"; \
  echo "display_startup_errors = off"; \
  echo "display_errors = off"; \
  echo "html_errors = off"; \
  echo "log_errors = on"; \
  echo "error_log = /dev/stderr"; \
  echo "ignore_repeated_errors = off"; \
  echo "ignore_repeated_source = off"; \
  echo "report_memleaks = on"; \
  #    echo "track_errors = on"; \
  echo "docref_root = 0"; \
  echo "docref_ext = 0"; \
  echo "error_reporting = -1"; \
  echo "log_errors_max_len = 0"; \
  } > /usr/local/etc/php/conf.d/security.ini

RUN { \
  echo "ServerSignature Off"; \
  echo "ServerTokens Prod"; \
  echo "TraceEnable off"; \
  } >> /etc/apache2/apache2.conf


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

VOLUME /var/www/html
EXPOSE 80 443
