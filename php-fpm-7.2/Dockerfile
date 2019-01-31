FROM d2cio/php-fpm:7.2-base

ARG MAGENTO_VERSION=2.3.0

ENV SERVICE=magento2 \
	SERVICE_VERSION=$MAGENTO_VERSION \
	\
	MAGENTO_VERSION=$MAGENTO_VERSION

RUN set -x && \
#
	apt update && \
	apt-mark showmanual > /tmp/savedAptMark && \
#
	docker-php-source extract && \
# bcmath
	docker-php-ext-install bcmath && \
# gd
	apt-get install -y --no-install-recommends libjpeg-dev libpng-dev libfreetype6-dev libwebp-dev libgif-dev && \
	docker-php-ext-configure gd --with-jpeg-dir --with-png-dir --with-freetype-dir --with-webp-dir --with-gd && \
	docker-php-ext-install gd && \
# intl
	apt-get install -y --no-install-recommends libicu-dev && \
	docker-php-ext-install intl && \
# mysqli
	docker-php-ext-install mysqli && \
# opcache
	docker-php-ext-install opcache && \
# pdo_mysql
	docker-php-ext-install pdo_mysql && \
# soap
	apt-get install -y --no-install-recommends libxml2-dev && \
	docker-php-ext-install soap && \
# xsl
	apt-get install -y --no-install-recommends libxslt1-dev && \
	docker-php-ext-install xsl && \
# zip
	apt-get install -y --no-install-recommends zlib1g-dev libzip-dev && \
	docker-php-ext-configure zip --with-libzip && \
	docker-php-ext-install zip && \
# pecl: redis
	pecl install -f redis && \
	docker-php-ext-enable redis && \
#
	docker-php-source delete && \
#
	apt-mark auto '.*' > /dev/null && \
	[ -z "$(cat /tmp/savedAptMark)" ] || apt-mark manual $(cat /tmp/savedAptMark) && \
	find /usr/local -type f -name '*.so*' -exec ldd '{}' ';' | awk '/=>/ { print $(NF-1) }' | sort -u | \
		xargs -r dpkg-query --search | cut -d: -f1 | sort -u | xargs -r apt-mark manual && \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false && \
	rm -rf /tmp/* ~/.pearrc /var/lib/apt/lists/* && \
#
	mkdir -p /var/www/$SERVICE && \
	curl -sL https://codeload.github.com/magento/$SERVICE/tar.gz/$MAGENTO_VERSION | tar xz -C /var/www/$SERVICE --strip-components=1 && \
	chown -R www-data:www-data /var/www/$SERVICE && \
#
	su -l www-data -s /bin/bash -c "cd /var/www/$SERVICE && composer install" && \
#
	tar cJf /usr/src/$SERVICE-$SERVICE_VERSION.tar.xz -C /var/www $SERVICE && \
	rm -rf /var/www/$SERVICE

ADD *.sh /
RUN set -x && \
	chmod +x /*.sh && \
	ln -s /docker-entrypoint.sh /usr/local/bin/cmd

ENTRYPOINT ["/docker-entrypoint.sh"]
