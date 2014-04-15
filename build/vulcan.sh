#!/bin/bash
set -e

mkdir /app/local
mkdir /app/local/lib
mkdir /app/local/bin
mkdir /app/local/include
mkdir /app/apache
mkdir /app/php

cd /tmp
curl -O http://mirrors.us.kernel.org/ubuntu/pool/universe/m/mcrypt/mcrypt_2.6.8-1_amd64.deb
curl -O http://mirrors.us.kernel.org/ubuntu/pool/universe/libm/libmcrypt/libmcrypt4_2.5.8-3.1_amd64.deb
curl -O http://mirrors.us.kernel.org/ubuntu/pool/universe/libm/libmcrypt/libmcrypt-dev_2.5.8-3.1_amd64.deb
ls -tr *.deb > packages.txt
while read l; do
    ar x $l
    tar -xzf data.tar.gz
    rm data.tar.gz
done < packages.txt

cp -a /tmp/usr/include/* /app/local/include
cp -a /tmp/usr/lib/* /app/local/lib

export APACHE_MIRROR_HOST="http://www.apache.org/dist"

echo "downloading PCRE"
curl -L ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.34.tar.gz -o /tmp/pcre-8.34.tar.gz
echo "downloading apr"
curl -L ${APACHE_MIRROR_HOST}/apr/apr-1.5.0.tar.gz -o /tmp/apr-1.5.0.tar.gz
echo "downloading apr-util"
curl -L ${APACHE_MIRROR_HOST}/apr/apr-util-1.5.3.tar.gz -o /tmp/apr-util-1.5.3.tar.gz
echo "downloading httpd"
curl -L ${APACHE_MIRROR_HOST}/httpd/httpd-2.4.9.tar.gz -o /tmp/httpd-2.4.9.tar.gz
echo "downloading php"
curl -L http://us.php.net/get/php-5.5.11.tar.gz/from/us2.php.net/mirror -o /tmp/php-5.5.11.tar.gz
echo "downloading zlib"
curl -L http://zlib.net/zlib-1.2.8.tar.gz -o /tmp/zlib-1.2.8.tar.gz
echo "downloading freetype"
curl -L http://download.savannah.gnu.org/releases/freetype/freetype-2.5.3.tar.gz -o /tmp/freetype-2.5.3.tar.gz
echo "downloading ICU"
curl -L http://download.icu-project.org/files/icu4c/52.1/icu4c-52_1-src.tgz -o /tmp/icu4c-52_1-src.tgz

tar -C /tmp -xzf /tmp/pcre-8.34.tar.gz
tar -C /tmp -xzf /tmp/httpd-2.4.9.tar.gz

tar -C /tmp/httpd-2.4.9/srclib -xzf /tmp/apr-1.5.0.tar.gz
mv /tmp/httpd-2.4.9/srclib/apr-1.5.0 /tmp/httpd-2.4.9/srclib/apr

tar -C /tmp/httpd-2.4.9/srclib -xzf /tmp/apr-util-1.5.3.tar.gz
mv /tmp/httpd-2.4.9/srclib/apr-util-1.5.3 /tmp/httpd-2.4.9/srclib/apr-util

tar -C /tmp -xzf /tmp/php-5.5.11.tar.gz
tar -C /tmp -xzf /tmp/zlib-1.2.8.tar.gz
tar -C /tmp -xzf /tmp/freetype-2.5.3.tar.gz
tar -C /tmp -xzf /tmp/icu4c-52_1-src.tgz

export CFLAGS='-g0 -O2 -s -m64 -march=core2 -mtune=generic -pipe '
export CXXFLAGS="${CFLAGS}"
export CPPFLAGS="-I/app/local/include"
export LD_LIBRARY_PATH="/app/local/lib"
export MAKE="/usr/bin/make"

cd /tmp/icu/source
CXX=g++ ./configure --prefix=/app/local &&
${MAKE} && ${MAKE} install

cd /tmp/freetype-2.5.3
./configure --prefix=/app/local --enable-shared
${MAKE} && ${MAKE} install

cd /tmp/zlib-1.2.8
./configure --prefix=/app/local --64
${MAKE} && ${MAKE} install

cd /tmp/pcre-8.34
./configure --prefix=/app/local --enable-jit --enable-utf8
${MAKE} && ${MAKE} install

cd /tmp/httpd-2.4.9
./configure --prefix=/app/apache --enable-rewrite --enable-so --enable-deflate --enable-expires --enable-headers --enable-proxy-fcgi --with-mpm=event --with-included-apr --with-pcre=/app/local
${MAKE} && ${MAKE} install

cd /tmp
git clone git://github.com/ByteInternet/libapache-mod-fastcgi.git
cd /tmp/libapache-mod-fastcgi/
patch -p1 < debian/patches/byte-compile-against-apache24.diff 
sed -e "s%/usr/local/apache2%/app/apache%" Makefile.AP2 > Makefile
${MAKE} && ${MAKE} install

cd /tmp/php-5.5.11
./configure --prefix=/app/php --with-pdo-pgsql --with-pgsql --with-mysql=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv --with-gd --with-curl=/usr/lib --with-config-file-path=/app/php --enable-soap=shared --with-openssl --enable-mbstring --with-mhash --enable-mysqlnd --with-pear --with-mysqli=mysqlnd --with-jpeg-dir --with-png-dir --with-mcrypt=/app/local --enable-static --enable-fpm --with-pcre-dir=/app/local --disable-cgi --enable-zip --with-icu-dir=/app/local --enable-intl --with-xmlrpc --with-gd --with-freetype-dir=/app/local --with-bz2
${MAKE}
${MAKE} install

/app/php/bin/pear config-set php_dir /app/php
echo " " | /app/php/bin/pecl install apc-3.1.13
/app/php/bin/pecl install igbinary

echo '2.4.9' > /app/apache/VERSION
echo '5.5.11' > /app/php/VERSION
mkdir /tmp/build
mkdir /tmp/build/local
mkdir /tmp/build/local/lib
mkdir /tmp/build/local/lib/sasl2
cp -a /app/apache /tmp/build/
cp -a /app/php /tmp/build/
cp -aL /app/local/lib/libmcrypt.so.4 /tmp/build/local/lib/
cp -aL /app/local/lib/libpcre.so.1 /tmp/build/local/lib/
cp -aL /app/local/lib/libicu* /tmp/build/local/lib/

rm -rf /tmp/build/apache/manual/

