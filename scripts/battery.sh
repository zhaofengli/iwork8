#!/bin/bash
modprobe i2c-dev
modprobe test_power
while true
do
	CAPACITY=$((-128+16#$(i2cget -y 12 0x34 0xB9|cut -d 'x' -f 2)))
	if [ -z $CAPACITY ]; then
		echo "Could not read battery level; let's be more careful right now"
	else
		echo "Battery level: $CAPACITY%"
		echo $CAPACITY%>/sys/module/test_power/parameters/battery_capacity
	fi
	sleep 120
	CHGCURR=$((16#$(i2cget -y 12 0x34 0x7A|cut -d 'x' -f 2)))
	if [ -z $CHGCURR ]; then
		echo "Could not read charging current; let's be more careful right now"
		sleep 5
	else
		echo -n "Charging current: $CHGCURR "
		if [ $CHGCURR -eq 0 ]; then
			echo "(discharging)"
			echo discharging>/sys/module/test_power/parameters/battery_status
			echo off >/sys/module/test_power/parameters/usb_online
			echo off >/sys/module/test_power/parameters/ac_online

		else
			echo "(charging)"
			echo charging>/sys/module/test_power/parameters/battery_status
			echo on >/sys/module/test_power/parameters/usb_online
			echo on >/sys/module/test_power/parameters/ac_online
		fi
	fi
	sleep 120
done
