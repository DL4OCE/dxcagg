#!/bin/bash

apt update
apt install apache2 libapache2-mod-php php-mysql php-mysqli mysql-server php-cli php-common php-json php-curl php-mbstring php-bcmath php-pear php-dev php-xdebug jq libnet-telnet-perl libdbi-perl libdbd-mysql-perl
systemctl enable apache2
systemctl enable mysql
systemctl start apache2
systemctl start mysql

