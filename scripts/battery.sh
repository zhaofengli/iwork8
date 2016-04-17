#!/bin/bash
modprobe i2c-dev
modprobe test_power


	#search AXP288 chip on /dev/i2c-dev?
	for i in `seq 1 12`;
 	do
	     RET=$(i2cget -f -y $i 0x34 0|cut -d 'x' -f1)
	     if [ $RET -eq 0 ]; then 
	     #echo /dev/i2c-dev$i
	     I2C_DEV=$i
	     break	 
	     else I2C_DEV=-1;   
        fi
	done

	if [ $I2C_DEV -eq -1 ]; then
	echo "No AXP288 PMIC on i2c Bus"
	exit 113
	fi 	

	# force ADC enable for battery voltage and current
	i2cset -y -f $I2C_DEV 0x34 0x82 0xC3


while true
do

	CAPACITY=$((-128+16#$(i2cget -f -y $I2C_DEV 0x34 0xB9|cut -d 'x' -f 2)))
	if [ -z $CAPACITY ]; then
		echo "Could not read battery level; let's be more careful right now"
	else
		echo "Battery level: $CAPACITY%"
		echo $CAPACITY%>/sys/module/test_power/parameters/battery_capacity
	fi
	sleep 60
	CHGCURR=$((16#$(i2cget -f -y $I2C_DEV 0x34 0x7A|cut -d 'x' -f 2)))
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
	
	BAT_CURRENT_LSB=$(i2cget -y -f $I2C_DEV 0x34 0x7B)
	BAT_CURRENT_MSB=$(i2cget -y -f $I2C_DEV 0x34 0x7A)
	BAT_AMP_BIN=$(( $(($BAT_CURRENT_MSB << 4)) | $(($(($BAT_CURRENT_LSB & 0xF0)) >> 4)) )) 
	BAT_CURRENT_CHARGE=$(echo "$BAT_AMP_BIN")
	echo "Current Charge = "$BAT_CURRENT_CHARGE"mA"

	BAT_CURRENT_DISCHARGE_LSB=$(i2cget -y -f $I2C_DEV 0x34 0x7D)
	BAT_CURRENT_DISCHARGE_MSB=$(i2cget -y -f $I2C_DEV 0x34 0x7C)
	BAT_BIN=$(( $(($BAT_CURRENT_DISCHARGE_MSB << 4)) | $(($(($BAT_CURRENT_DISCHARGE_LSB & 0xF0)) >> 4)) )) 
	BAT_CURRENT_DISCHARGE=$(echo "$BAT_BIN")
	echo "Current DisCharge = "$BAT_CURRENT_DISCHARGE"mA"


	#read battery voltage	79h, 78h	0 mV -> 000h,	1.1 mV/bit	FFFh -> 4.5045 V 
	BAT_VOLT_LSB=$(i2cget -y -f $I2C_DEV 0x34 0x79) 
	BAT_VOLT_MSB=$(i2cget -y -f $I2C_DEV 0x34 0x78) 
	#echo $BAT_VOLT_MSB $BAT_VOLT_LSB 
	BAT_BIN=$(( $(($BAT_VOLT_MSB << 4)) | $(($(($BAT_VOLT_LSB & 0xF0)) >> 4)) ))
	BAT_VOLT=$(echo "$BAT_BIN")
	echo "Battery voltage = "$BAT_VOLT"mV"

	echo $BAT_VOLT >      /sys/module/test_power/parameters/battery_voltage 	


	sleep 60
done


