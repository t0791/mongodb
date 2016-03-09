#!/bin/bash

unset http_proxy
unset https_proxy

echo `curl -XPUT http://<%= SINGLE_ETCD_IP %>:5678/v2/keys/skydns/config -d value='{"dns_addr":"<%= SKYDNS_IP %>:53","domain":"paas","ttl":60, "nameservers": ["<%= NAMESERVER_IP %>:53"]}'` 

if [ $? -eq 0 ]; then
   echo "init skydns date on etcd failed!"
   exit 1
else
   echo "init skydns date successfully!"
   exit 0

fi
