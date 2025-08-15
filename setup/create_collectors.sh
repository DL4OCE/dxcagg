#!/bin/bash

# remove old collector service definition files
# for file in /etc/systemd/system/dxcagg_collector_*; do
#     if [ -e $file ]; then
#         echo $file
#         systemctl status "$(basename "$file")"
#         systemctl disable "$(basename "$file")"
#         systemctl status "$(basename "$file")"
#         rm -f $file
#     fi
# done

# create new service definition files
for file in ../config/collectors/*; do
    # printf "############\n$file\n"
    # collector_name=$(basename "$file" .json)
    collector_config=$(cat $file|/usr/bin/jq)
    # echo $collector_config

    eval "$(jq -r '. | to_entries | .[] | .key + "=" + (.value | @sh)' < $file)"
    # echo "$dxc_hostname" "$dxc_port" "$dxc_expect_prompt" "$dxc_my_call"

    service_file="/etc/systemd/system/dxcagg_collector_${dxc_hostname}.service"
    cat > "$service_file" <<EOF
[Unit]
Description=DXC Aggregator Collector ($dxc_hostname)
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/perl /var/www/html/dxcagg/collector/perl/collector.pl "$dxc_type" "$dxc_hostname" "$dxc_port" "$dxc_expect_prompt" "$dxc_my_call"
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    systemctl enable dxcagg_collector_${dxc_hostname}.service
    systemctl status dxcagg_collector_${dxc_hostname}.service

done
