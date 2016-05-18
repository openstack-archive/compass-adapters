#!/bin/sh
mysql -uroot -Dmysql <<EOF
use mysql;
delete from user where user='';
EOF
