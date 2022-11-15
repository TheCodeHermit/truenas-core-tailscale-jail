#!/bin/sh

# Author: Kornel Jahn
# License: BSD-3-Clause

if [ $# -lt 1 ]; then
  {
    echo "usage: $(basename "$0") <host-ip-address> [<ports>]"
    echo ''
    echo 'where <ports> takes the form "proto1/port1 proto2/port2 ..."'
  } 1>&2
  exit 1
fi

# Install nginx
pkg install -y nginx

# Create reverse proxy to forward ports
# Default selection:
#   TCP 22: SSH
#   TCP 443: WebUI HTTPS
#   TCP 2049: NFS4
#   TCP 5201: iperf3
host="$1"
proto_ports="${2:-tcp/22 tcp/443 tcp/2049 tcp/5201}"
{
  echo 'load_module /usr/local/libexec/nginx/ngx_stream_module.so;'
  echo ''
  echo 'events { }'
  echo ''
  echo 'stream {'
  i=0
  for proto_port in $proto_ports; do
    port="${proto_port##*/}"
    echo "  upstream srv$i { server $host:$port; }"
    echo "  server { listen $port; proxy_pass srv$i; }"
    i=$((i+1))
  done
  echo '}'
} > /usr/local/etc/nginx/nginx.conf

# Enable and start nginx
service nginx enable
service nginx start

# vim: set ts=2 sw=2 sts=2 et:
