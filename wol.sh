exec 1> >(logger -t $(basename $0)) 2>&1
base_dir=/root/wol
socat -u udp-recv:9 - | 
stdbuf -o0 xxd -c 6 -p |
stdbuf -o0 uniq |
stdbuf -o0 grep -v 'ffffffffffff' |
stdbuf -o0 tr [:lower:] [:upper:] |
while read
do
	MAC=${REPLY:0:2}:${REPLY:2:2}:${REPLY:4:2}:${REPLY:6:2}:${REPLY:8:2}:${REPLY:10:2}
	echo Received Address: $MAC
	eval `grep -i "^$MAC" $base_dir/wol.config | awk -F "," '{print "node="$2 ; print "name="$3 }'`
	if [[ -n "$node" ]]
	then 
		name=${name:="unknown"}
		echo "Starting node $node ($name)" 
		qm start $node
	else
		echo "$MAC not found in wol.config" 
	fi
done
