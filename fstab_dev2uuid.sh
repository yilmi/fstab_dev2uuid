#!/bin/bash
# Credits : Buuntu from ubuntu forums :http://ubuntuforums.org/showthread.php?t=1508991
# This script will change all fstab entries form device name format to UUID names format

#Check for superuser uid
if [ `id -u` -ne 0 ]; 
	then
        echo "This script must be run as root" >&2                      
        exit 1
fi

#First backup fstab file
cp /etc/fstab /etc/fstab.backup

#List devices with name starting with hd or sd from /etc/fstab and extract those to /tmp/devices as /dev/sdx - /dev/hdx 
sed -n 's|^/dev/\([sh]d[a-z][0-9]\).*|\1|p' </etc/fstab >/tmp/devices   

#Parse /tmp/devices and look for /dev/disk/by-uuid symlinks to map uuid to block device 
while read LINE; do                                                     # For each line in /tmp/devices
        UUID=`ls -l /dev/disk/by-uuid | grep "$LINE" | sed -n 's/^.* \([^ ]*\) -> .*$/\1/p'`	# Sets the UUID name for that device
        sed -i "s|^/dev/${LINE}|UUID=${UUID}|" /etc/fstab_uuid               			# output UUID based fstab file
done </tmp/devices

#Check if there is any content to write to file
if cat /etc/fstab_uuid 
	then
	#if 1st switch is -y will not ask for confirmation
	if  [ "$1"!="-y" ] 
		then
		echo -e "\nThe following content will be"
		cat /etc/fstab_uuid 2>/dev/null
		printf "\n\nWrite changes to /etc/fstab? (y/n) "
		read RESPONSE;
	elif [ "$1"="-y"] ;
		then
		RESPONSE="y"
	fi
else
	echo -e "\nNo changes to write !"
fi
#Check if change should be written
case "$RESPONSE" in
        [yY]|[yY][eE][sS])                                              # If answer is yes, update /etc/fstab with /etc/fstab_uuid
                echo "Writing changes to /etc/fstab..."
		cp /etc/fstab_uuid /etc/fstab
                ;;
        [nN]|[nN][oO]|"")                                               # If answer is no, or if the user just pressed Enter
                echo "Aborting: Not saving changes..."                  # don't save the new fstab file
                rm /etc/fstab_uuid 2>/dev/null
                ;;
        *)                                                              # If answer is anything else, exit and don't save changes
                echo "Exiting"
                rm /etc/fstab_uuid2 >/dev/null
                exit 1
                ;;
esac
rm /tmp/devices
echo "DONE!"

