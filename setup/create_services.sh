#!/bin/bash

# create housekeeping service definition file
eval "$(jq -r '. | to_entries | .[] | .key + "=" + (.value | @sh)' < ../config/main.json)"

# service_file="/etc/systemd/system/dxcagg_housekeeping.service"
service_file=dxcagg_housekeeping.service
rm -f /etc/systemd/system/${service_file}
cat > /etc/systemd/system/${service_file} <<EOF
[Unit]
Description=DXC aggregator database housekeeping
After=network.target

[Service]
Type=simple
WorkingDirectory=/var/www/html/dxcagg/collector/
ExecStart=/usr/bin/perl /var/www/html/dxcagg/collector/database_housekeeping.pl
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    systemctl stop ${service_file}
    systemctl disable ${service_file}
    systemctl status ${service_file}
    systemctl enable ${service_file}
    systemctl status ${service_file}

# remove old collector service definition files
for file in /etc/systemd/system/dxcagg_collector_*; do
    if [ -e $file ]; then
        echo $file
        systemctl stop dxcagg_collector_${dxc_hostname}.service
        systemctl status "$(basename "$file")"
        systemctl disable "$(basename "$file")"
        systemctl status "$(basename "$file")"
        rm -f $file
    fi
done

# create new collectors' service definition files
for file in ../config/collectors/*; do
    collector_config=$(cat $file|/usr/bin/jq)
    eval "$(jq -r '. | to_entries | .[] | .key + "=" + (.value | @sh)' < $file)"
    service_file="/etc/systemd/system/dxcagg_collector_${dxc_hostname}.service"
    cat > "$service_file" <<EOF
[Unit]
Description=DXC Aggregator Collector ($dxc_hostname)
After=network.target

[Service]
Type=simple
WorkingDirectory=/var/www/html/dxcagg/collector/
ExecStart=/usr/bin/perl /var/www/html/dxcagg/collector/collector.pl "$dxc_type" "$dxc_hostname" "$dxc_port" "$dxc_expect_prompt" "$dxc_my_call"
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    systemctl enable dxcagg_collector_${dxc_hostname}.service
    systemctl stop dxcagg_collector_${dxc_hostname}.service
    systemctl status dxcagg_collector_${dxc_hostname}.service
    systemctl start dxcagg_collector_${dxc_hostname}.service
    systemctl status dxcagg_collector_${dxc_hostname}.service

done

