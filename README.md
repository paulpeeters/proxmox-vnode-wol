# proxmox-vnode-wol

This shell script can be installed as a service in de proxmox host. It will listen on magic packets broadcasted via UDP on port 9, find the MAC address in the packet, lookup that MAC in a configuration file and find the corresponding vnode id. If found, the script will start (wake) that vnode. 