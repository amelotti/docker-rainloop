FROM ubuntu:latest
MAINTAINER Luiz A. Amelotti <luiz@amelotti.com>

ENV DEBIAN_FRONTEND noninteractive
ENV SHELL /bin/bash

RUN apt-get update \
    && apt-get -y upgrade

# Install basic stuff
RUN apt-get install -y --no-install-recommends runit curl ca-certificates apt-utils apt-transport-https lsb-release unzip nginx nginx-extras php-fpm php-curl php-pgsql php-mysql php-sqlite3 php-json php-xml build-essential supervisor

# Set the locale and timezone
RUN apt-get install -y locales
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Install lates Rainloop
ADD http://www.rainloop.net/repository/webmail/rainloop-community-latest.zip /tmp
RUN mkdir /var/www/rainloop \
 && unzip /tmp/rainloop-community-latest.zip -d /var/www/rainloop \
 && find /var/www/rainloop -type d -exec chmod 755 {} \; \
 && find /var/www/rainloop -type f -exec chmod 644 {} \; \
 && chown -R www-data:www-data /var/www/rainloop

# Setup Nginx
ADD nginx.conf /etc/nginx/nginx.conf
ADD rainloop.conf /etc/nginx/sites-available/rainloop.conf
RUN ln -s /etc/nginx/sites-available/rainloop.conf /etc/nginx/sites-enabled/rainloop.conf \
 && sed -i 's/;daemonize = yes/daemonize = no/g' /etc/php/7.0/fpm/php-fpm.conf \
 && sed -i 's/post_max_size.*$/post_max_size = 128M/g' /etc/php/7.0/fpm/php.ini \
 && sed -i 's/upload_max_filesize.*$/upload_max_filesize = 128M/g' /etc/php/7.0/fpm/php.ini

# Forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/rainloop/access.log \
 && ln -sf /dev/stderr /var/log/rainloop/error.log

# Setup Supervisor
RUN mkdir -p /var/log/supervisor
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 80

CMD ["/usr/bin/supervisord"]

