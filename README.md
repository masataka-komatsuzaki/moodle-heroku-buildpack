Apache2.4+PHP5.4 build pack for Moodle
========================

This is a build pack bundling PHP and Apache for Heroku apps.

Configuration
-------------

The config files are bundled with the build pack itself:

* conf/httpd.conf
* conf/php.ini
* conf/config.php (Moodle default configuration)


Pre-compiling binaries
----------------------

Required software
 - Ubuntu 10.04
 - curl
 - ANSI-C compiler

This script will set up a heroku cedar platform (Ubuntu 10.04)
 1. Compile apache 2.4.3 and install on /app/apache
 2. Compile php 5.4.11+ required extensions and install on /app/php

    apt-get install curl
    mkdir -p /app

Prepare the filesystem

    mkdir -p /tmp/build
    cd /tmp/build

Compiling Apache

    curl -L http://www.carfab.com/apachesoftware/httpd/httpd-2.4.3.tar.gz | tar xzf -
    cd httpd-2.4.3
    cd srclib
    curl http://www.us.apache.org/dist//apr/apr-1.4.6.tar.gz | tar xzf -
    mv apr-1.4.6 apr
    curl http://www.us.apache.org/dist//apr/apr-util-1.5.1.tar.gz | tar xzf -
    mv apr-util-1.5.1 apr-util
    cd ..
    apt-get install libpcre3
    apt-get install libpcre3-dev
    ./configure --prefix=/app/apache --with-included-apr --enable-rewrite
    make && make install
    cd ..

Apache libraries

    mkdir -p /app/php/ext
    cp /app/apache/lib/libapr-1.so.0 /app/php/ext
    cp /app/apache/lib/libaprutil-1.so.0 /app/php/ext
    cd /app/php/ext
    ln -s libapr-1.so.0 libapr-1.so
    ln -s libaprutil-1.so.0 libaprutil-1.so
    cd /tmp/build

Compiling PHP

    apt-get install libxml2
    apt-get install libxml2-dev
    apt-get install libssl-dev
    apt-get install libvpx-dev
    apt-get install libjpeg-dev
    apt-get install libpng-dev
    apt-get install libXpm-dev
    apt-get install libbz2-dev
    apt-get install libmcrypt-dev
    apt-get install libcurl4-openssl-dev
    apt-get install libfreetype6-dev
    apt-get install postgresql-server-dev-8.4

    curl -L http://php.net/get/php-5.4.11.tar.gz/from/us1.php.net/mirror | tar xzf -
    cd php-5.4.11
    ./configure --prefix=/app/php --with-apxs2=/app/apache/bin/apxs --with-mysql --with-pdo-mysql --with-pgsql --with-pdo-pgsql --with-iconv --with-gd --with-curl=/usr/lib --with-config-file-path=/app/php --enable-soap=shared --enable-libxml --enable-simplexml --enable-session --with-xmlrpc --with-openssl --enable-mbstring --with-bz2 --with-zlib --with-gd --with-freetype-dir=/usr/lib --with-jpeg-dir=/usr/lib --with-png-dir=/usr/lib --with-xpm-dir=/usr/lib
    make && make install
    cd ..

PHP Extensions

    apt-get install libmysqlclient-dev
    cd /app/php/ext
    cp /usr/lib/libmysqlclient.so.16.0.0 .
    ln -s libmysqlclient.so.16.0.0 libmysqlclient.so.16
    ln -s libmysqlclient.so.16.0.0 libmysqlclient.so
    cd /tmp/build

Apache php module

    cp /tmp/build/php-5.4.11/.libs/libphp5.so /app/apache/modules/

APC

    apt-get install autoconf
    curl http://pecl.php.net/get/APC/3.1.14 | tar xzf -
    cd APC-3.1.14
    /app/php/bin/phpize
    ./configure --enable-apc --enable-apc-mmap --with-php-config=/app/php/bin/php-config
    make && make install
    cp .libs/apc.so /app/php/ext
    cd ..

Create packages
    cd /app
    echo '2.4.3' > apache/VERSION
    tar -zcvf apache-2.4.3.tar.gz apache
    echo '5.4.11' > php/VERSION
    tar -zcvf php-5.4.11.tar.gz php

Upload to your Amazon S3 s3cmd

    # s3cmd apache.tar.gz s3://yourbucket/path/to
    # s3cmd php.tar.gz s3://yourbucket/path/to
    # Dont forget to add a permission for everyone to read



Hacking
-------

To change this buildpack, fork it on Github. Push up changes to your fork, then create a test app with --buildpack <your-github-url> and push to it.


Meta
----

Froked from https://github.com/grahamjenson/heroku-buildpack-mahara
