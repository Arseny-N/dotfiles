#!/bin/bash
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#


#
# Предыстория
# -----------
#
# Для работы на серверах лаборатории я использую ssh для проброски портов и sshfs для 
# удаленного доступа к файлам. Обе эти программы имеют свои недостатки. Проброска портов 
# через ssh не всегда удобна так как их нужно прописывать вручную. sshfs же иногда, 
# довольно неприятно ломается.
#
# Я долго решал эти проблемы откапывая нужные команды в истории. В какой-то момент мне 
# это надоело и я написал удобный скрипт, который решает обе эти проблемы. 
#
# Вот этот скрипт. 
#
# Скрипт позволяет чинить сломанные sshfs маунты и автоматически пробрасывать открытые 
# пользователем порты c сервера. 
#
# Получилось очень удобно. Если что-то не так с сетью и подвис ssh туннель или файлы не 
# сохраняются на сервере я просто перезапускаю скрипт и это обычно решает проблему.
#
#
#
# Если возникнут вопросы, пишите:
# 
# 	Email: arseny-n@yandex.ru
# 	Telegram: @ArsenyNerinovsky
# 


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

#
# setup_mounts <ssh_host> <mount_path>
#
#   Checks if <mount_path> is a broken sshfs mount, if so unmount it 
#   and mount the root of <ssh_host> to <mount_path>. Otherwise just mount 
#   the root of <ssh_host> to <mount_path> if it is not already mounted.
#
setup_mounts() {

	local host=$1 path=$2

	fix_mounts $path

	[ -f ${path}/etc/os-release ] || { 
		echo Mounting $host to $path
		# https://askubuntu.com/questions/1090715/fuse-bad-mount-point-mnt-transport-endpoint-is-not-connected
		sshfs -o allow_other -o reconnect -o ServerAliveInterval=15 ${host}:/ $path & 
	} 
}

#
# setup_ports <ssh_host> <ct_user> <port_prefix>
#
#   Starts port forwarding from <ct_user>@<ssh_host> to local host. All 
#   open ports on <ssh_host> by <ct_user> are forwarded with the addition 
#   of 8889,8888,6006,8097. 
#
#   Forwarding of all open ports is quite convenient since it allows 
#   to just restart the script if I want to forward a previously unforwarded 
#   port.
#
#   By default remote ports are forwarded to the same local ports. Since 
#   this is sometimes undesirable the <port_prefix> argument could be used in 
#   order to prefix the local ports with a user supplied prefix. If this is 
#   not needed it could be leaved empty.
#   
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

# My local computer configuration.
# 
# If you are tailoring this script to your needs 
# this can be safely removed.
(
	is_online box && {
		echo box is online, mounting
		setup_mounts box $HOME/mnt/box arseni 4
	} || echo box is offline
)& 


# CTLab configuration.
#
# Substitute anerinovsky with your CTLab username.
# Substitute laplas.r, turing.r with the correct ssh hosts.
# 
# If it does not work try doing `ssh <ssh_host>`. It should 
# get you a shell in order for this to work.

setup_mounts laplas.r $HOME/mnt/laplas
setup_ports  laplas.r anerinovsky 0 &

setup_mounts turing.r $HOME/mnt/turing
setup_ports  turing.r anerinovsky 1 &


# Killing the script will kill all port forwarding 
wait