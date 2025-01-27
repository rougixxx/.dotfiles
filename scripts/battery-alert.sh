#!/bin/bash


# Send a notification if the laptop battery is either low or is fully charged.
# for debugging the service: `journalctl -u battery-alert.service`


export DISPLAY=:0
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/1000/bus"

# Battery percentage at which to notify
WARNING_LEVEL=15
CRITICAL_LEVEL=10
BATTERY_DISCHARGING=$(acpi -b | grep "Battery 0" | grep -c "Discharging")
BATTERY_LEVEL=$(acpi -b | grep "Battery 0" | grep -P -o '[0-9]+(?=%)')
echo $BATTERY_LEVEL
# Use files to store whether we've shown a notification or not (to prevent multiple notifications)
FULL_FILE=/tmp/batteryfull
EMPTY_FILE=/tmp/batteryempty
CRITICAL_FILE=/tmp/batterycritical

# Reset notifications if the computer is charging/discharging
if [ "$BATTERY_DISCHARGING" -eq 1 ] && [ -f $FULL_FILE ]; then
	rm $FULL_FILE
elif [ "$BATTERY_DISCHARGING" -eq 0 ] && [ -f $EMPTY_FILE ]; then
	rm $EMPTY_FILE
fi

# If the battery is charging and is full (and has not shown notification yet)
if [ "$BATTERY_LEVEL" -gt 97 ] && [ "$BATTERY_DISCHARGING" -eq 0 ] && [ ! -f $FULL_FILE ]; then
	notify-send "Battery Charged" "Battery is fully charged." -i ~/.dotfiles/icons/battery-full.png
	touch $FULL_FILE
	# If the battery is low and is not charging (and has not shown notification yet)
elif [ "$BATTERY_LEVEL" -le $WARNING_LEVEL ] && [ "$BATTERY_DISCHARGING" -eq 1 ] && [ ! -f $EMPTY_FILE ]; then
	notify-send "Low Battery" "${BATTERY_LEVEL}% of battery remaining." -u critical -i ~/.dotfiles/icons/battery-discharging.png 
	touch $EMPTY_FILE
	# If the battery is critical and is not charging (and has not shown notification yet)
elif [ "$BATTERY_LEVEL" -le $CRITICAL_LEVEL ] && [ "$BATTERY_DISCHARGING" -eq 1 ] && [ ! -f $CRITICAL_FILE ]; then
	notify-send   -u critical "Battery is LOW!!" "Plug the Charger!!!!." -i ~/.dotfiles/icons/battery-alert.png 
	touch $CRITICAL_FILE
	fi


# 2 options
# Option1: cronjob: */5 * * * * ~/battery-check.sh
# Option2: Create a systemd timer
# 	1.edit this file: /etc/systemd/system/battery-alert.service with this:
# 		[Unit]
# 		Description=Battery Check Notification

# 	[Service]
# 	ExecStart=/bin/bash /home/your-username/battery-check.sh

# 	2. edit this file: /etc/systemd/system/battery-alert.timer with this:
# 		[Unit]
# 		Description=Run Battery Check Every 5 Minutes

# 		[Timer]
# 		OnBootSec=5min
# 		OnUnitActiveSec=5min

# 		[Install]
# 		WantedBy=timers.target
# 	3. enable the service: `sudo systemctl enable --now battery-alert.timer`

