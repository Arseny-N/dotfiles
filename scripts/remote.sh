#!/bin/bash


fix_mounts::is_broken_mount() {

	ls "$1" >/dev/null 2>&1
	exit_code=$?

	test $exit_code -eq 2
}

fix_mounts::is_hung_mount() {
	
	timeout -s 9 1s ls "$1" >/dev/null 2>&1
	exit_code=$?

	test $exit_code -eq 137
}

fix_mounts() {
	echo -n "Testing if the $1 mount is hung: "

	fix_mounts::is_hung_mount $1 && {
		echo Yes
		# FIXME: _might_ kill the wrong sshfs. 
		pgrep -a sshfs | grep $1 | cut -d ' ' -f 1 | xargs kill -9
		fusermount -u $1
	} || echo No

	echo -n "Testing if the $1 mount is broken: "
	fix_mounts::is_broken_mount $1 && {
		echo Yes
		fusermount -u $1

		fix_mounts::is_broken_mount $1 && sudo umount -l $1
	} || echo No
}


setup_mounts() {

	local host=$1 path=$2

	fix_mounts $path

	[ -f ${path}/etc/os-release ] || { 
		echo Mounting $host to $path
		# https://askubuntu.com/questions/1090715/fuse-bad-mount-point-mnt-transport-endpoint-is-not-connected
		sshfs -o allow_other -o reconnect -o ServerAliveInterval=15 ${host}:/ $path & 
	} 
}

setup_ports() {

	local host=$1 user=$2 port_prefix=$3

	DEFAULT_PORTS=":8889 :8888 :6006 :8097"

	echo Getting currently open ports...

	OPEN_PORTS=$(ssh $host lsof -Panw -u${user} -i -FnT | \
	 		grep -B 1 LISTEN | grep ':8[0-9][0-9][0-9]$' | \
	 		cat - <(echo $DEFAULT_PORTS | sed 's/ /\n/g')  | \
	 		sed "s/.*:\(.*\)/-L ${port_prefix}\1:localhost:\1/" | sort -u | xargs)

	echo Forwarding ports form $host: $OPEN_PORTS
	ssh -N $OPEN_PORTS $host	
}

is_online() { ping -c 2 -W 1 $1 &> /dev/null ; }



#
# Config
#

(
	is_online box && {
		echo box is online, mounting
		setup_mounts box $HOME/mnt/box arseni 4
	} || echo box is offline
)& 




setup_mounts laplas.r $HOME/mnt/laplas
setup_ports  laplas.r anerinovsky 0 &

setup_mounts turing.r $HOME/mnt/turing
setup_ports  turing.r anerinovsky 1 &


# Killing the script will kill all port forwarding 
wait








