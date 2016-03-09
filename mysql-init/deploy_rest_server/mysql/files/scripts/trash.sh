#!/bin/bash
sudo chmod 750 ${mysql_config}
sudo chmod 777 ${mysql_init_file}
sudo echo -n "" > ${mysql_init_file}
sudo chmod 600 ${mysql_init_file}
sudo chmod 700 ${mysql_config}
