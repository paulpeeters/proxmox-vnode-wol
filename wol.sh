exec 1> >(logger -t $(basename $0)) 2>&1
BASE_DIR=/root/wol
CONFIG_FILE=$BASE_DIR/wol.config
NODE_CONFIGURATION_FILES=/etc/pve/nodes/proxmox/qemu-server/*.conf
socat -u udp-recv:9 - |
stdbuf -o0 xxd -c 6 -p |
stdbuf -o0 uniq |
stdbuf -o0 grep -v 'ffffffffffff' |
stdbuf -o0 tr [:lower:] [:upper:] |
while read
do
	node=""
	name=""
	MAC=${REPLY:0:2}:${REPLY:2:2}:${REPLY:4:2}:${REPLY:6:2}:${REPLY:8:2}:${REPLY:10:2}
	echo Received Address: $MAC
	# first try to find MAC in config file
	if [ -f "$CONFIG_FILE" ]
	then
		eval `grep -i "^$MAC" $CONFIG_FILE | awk -F "," '{print "node="$2 ; print "name="$3 }'`
		if  [[ -n "$node" ]]
		then
			echo "found $MAC in $CONFIG_FILE"
		fi
	fi
	# if not found, try to find $MAC in node configuration files
	if [[ -z "$node" ]]
	then
		for file in $NODE_CONFIGURATION_FILES
		do
			# entries we need from conf file are name and net0, for example
			#	name: hostname-01
			#	net0: e1000=AA:BB:CC:DD:EE:FF,bridge=vmbr0,firewall=1

			node_mac=`cat $file | grep ^net0: | cut -d ":" -f 2- | xargs | cut -d "," -f 1 | cut -d "=" -f 2`
			if [[ "${MAC,,}" = "${node_mac,,}" ]]
			then
				echo "found $MAC in $file"
				name=`cat $file | grep ^name: | cut -d ":" -f 2 | xargs`
				node=`basename $file .conf`
				break
			fi
		done
	fi

	if [[ -n "$node" ]]
	then
		name=${name:="unknown"}
		echo "Starting node $node ($name)" 
		qm start $node
	else
		echo "$MAC not found" 
	fi
done
