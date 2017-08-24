# See https://github.com/docker-library/php/blob/4677ca134fe48d20c820a19becb99198824d78e3/7.0/fpm/Dockerfile
FROM php:7.1-fpm


MAINTAINER Keaton Burleson <keaton.burleson@me.com>

RUN apt-get update && apt-get install -y \
    git \
    unzip \
    tzdata

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN composer --version

# Type docker-php-ext-install to see available extensions
RUN docker-php-ext-install pdo pdo_mysql

############################################################
# Arguments
############################################################
ENV TZ "America/Chicago"
ENV MEMORY_LIMIT "512M"

############################################################
# Update Timezone
############################################################

RUN echo $TZ > /etc/timezone && \
    rm /etc/localtime && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata && \
    apt-get clean


############################################################
# Create 'ducky' user
############################################################

RUN useradd -ms /bin/bash ducky
USER ducky
WORKDIR /home/ducky

RUN echo 'export PATH=$HOME/.config/composer/vendor/bin/:$PATH' >> .bash_profile

RUN mkdir -p /home/ducky/.composer/

# Add the default composer.json
COPY conf/composer.json /home/ducky/.composer/composer.json

# Update Composer

RUN composer config --global github-protocols https && \
    composer global update

# Switch to ducky
WORKDIR /home/ducky

# Update the phpcs coding standard
RUN /home/ducky/.composer/vendor/bin/phpcs --config-set installed_paths /home/ducky/.composer/vendor/escapestudios/symfony2-coding-standard

############################################################
# Install xdebug
############################################################
USER root

RUN pecl install xdebug
RUN docker-php-ext-enable xdebug
RUN echo "error_reporting = E_ALL" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo "session.save_path = /tmp" > /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo "display_startup_errors = On" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo "display_errors = On" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo "xdebug.remote_enable=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo "xdebug.remote_connect_back=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo "xdebug.idekey=\"PHPSTORM\"" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo "xdebug.remote_port=9001" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo "session.gc_maxlifetime = 3600" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo "max_execution_time = 0" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo "memory_limit = $MEMORY_LIMIT"  >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo "date.timezone = $TZ" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini


RUN echo 'alias sf="php app/console"' >> ~/.bashrc
RUN echo 'alias sf3="php bin/console"' >> ~/.bashrc
RUN mkdir -p /var/lib/php/sessions/
RUN chmod o+wx /var/lib/php/sessions/

WORKDIR /var/www/html/
USER ducky
RUN echo 'alias sf="php app/console"' >> ~/.bashrc
RUN echo 'alias sf3="php bin/console"' >> ~/.bashrc
