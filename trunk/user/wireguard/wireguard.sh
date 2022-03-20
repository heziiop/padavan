#!/bin/sh

start_wg() {
	privatekey="$(nvram get wireguard_localkey)"
	listenport="$(nvram get wireguard_listenport)"
	localip="$(nvram get wireguard_localip)"
	peerkey="$(nvram get wireguard_peerkey)"
	presharedkey="$(nvram get wireguard_presharedkey)"
	allowedips="$(nvram get wireguard_allowedips)"
	peerip="$(nvram get wireguard_peerip)"
	keepalive="$(nvram get wireguard_keepalive)"
	logger -t "WIREGUARD" "正在启动WireGuard"
	ifconfig wg0 down
	ip link del dev wg0
	ip link add dev wg0 type wireguard
	ip link set dev wg0 mtu 1420
	ip addr add $localip dev wg0
	echo "$privatekey" > /tmp/privatekey
	wg set wg0 private-key /tmp/privatekey
	[ ! $listenport ] || wg set wg0 listen-port $listenport
	[ ! $keepalive ] && keepalive=0
	
	if [ ! $presharedkey ] && [ ! $peerip ]; then
		wg set wg0 peer $peerkey persistent-keepalive $keepalive allowed-ips $allowedips
	elif [ ! $presharedkey ]; then
		wg set wg0 peer $peerkey persistent-keepalive $keepalive allowed-ips $allowedips endpoint $peerip
	elif [ ! $peerip ]; then
		echo "$presharedkey" > /tmp/presharedkey
		wg set wg0 peer $peerkey preshared-key /tmp/presharedkey persistent-keepalive $keepalive allowed-ips $allowedips
	else
		echo "$presharedkey" > /tmp/presharedkey
		wg set wg0 peer $peerkey preshared-key /tmp/presharedkey persistent-keepalive $keepalive allowed-ips $allowedips endpoint $peerip
	fi
	
	iptables -t nat -A POSTROUTING -o wg0 -j MASQUERADE
	ifconfig wg0 up
}


stop_wg() {
	ifconfig wg0 down
	ip link del dev wg0
	logger -t "WIREGUARD" "正在关闭WireGuard"
	}



case $1 in
start)
	start_wg
	;;
stop)
	stop_wg
	;;
*)
	echo "check"
	#exit 0
	;;
esac
