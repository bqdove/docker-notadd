FROM php:7.1-apache

# install the PHP extensions we need
RUN apt-get update && apt-get install -y vim git-core libsqlite3-dev libpq-dev libmcrypt-dev libpng12-dev libjpeg-dev libz-dev libmemcached-dev libphp-predis && rm -rf /var/lib/apt/lists/* \
        && docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
        && docker-php-ext-install gd mysqli mcrypt zip mbstring pdo pdo_mysql pdo_sqlite pdo_pgsql json \
	&& pecl install redis xdebug \
	&& docker-php-ext-enable redis xdebug

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

RUN a2enmod rewrite expires

VOLUME /var/www/html

RUN curl -sS https://getcomposer.org/installer | php \
        && mv composer.phar /usr/local/bin/composer

RUN cd /usr/src \		
      && git clone https://github.com/notadd/notadd.git \		
      && cd notadd \		
      && composer install --no-interaction --prefer-dist

# COPY config/*.php /usr/src/october/config/

RUN chown -R www-data:www-data /usr/src/notadd

COPY docker-entrypoint.sh /usr/local/bin/
RUN ln -s usr/local/bin/docker-entrypoint.sh /entrypoint.sh # backwards compat

# ENTRYPOINT resets CMD
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]