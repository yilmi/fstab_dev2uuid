#!/bin/bash
# Credits : Buuntu from ubuntu forums :http://ubuntuforums.org/showthread.php?t=1508991
# This script will change all fstab entries form device name format to UUID names format

#Check for superuser uid
if [ `id -u` -ne 0 ]; 
	then
        echo "This script must be run as root" >&2
        exit 1
fi



#Check for existing backup
if [[ -f /etc/fstab.backup ]]
	then
	echo "Backup file found (/etc/fstab.backup), please delete backup"
	exit
else 
	#Backup fstab file
	cp /etc/fstab /etc/fstab.backup
fi

#Prepare fstab_uuid
cp /etc/fstab /etc/fstab_uuid

#List devices with name starting with hd or sd from /etc/fstab and extract those to /tmp/devices as /dev/sdx - /dev/hdx
sed -n 's|^/dev/\([sh]d[a-z][0-9]\).*|\1|p' </etc/fstab >/tmp/devices

#Parse /tmp/devices and look for /dev/disk/by-uuid symlinks to map uuid to block device 
while read LINE; do                                                     # For each line in /tmp/devices
        UUID=`ls -l /dev/disk/by-uuid | grep "$LINE" | sed -n 's/^.* \([^ ]*\) -> .*$/\1/p'`	# Sets the UUID name for that device
        sed -i "s|^/dev/${LINE}|UUID=${UUID}|" /etc/fstab_uuid   				# output UUID based to fstab_uuid file
done </tmp/devices

#Check if there is any content to write to file
if [[ -s /etc/fstab_uuid ]] 
	then
	#if 1st switch is -y will not ask for confirmation
	if  [ "$1"!="-y" ] 
		then
		echo -e "\nThe following content will be added to fstab"
		cat /etc/fstab_uuid
		printf "\n\nWrite changes to /etc/fstab? (y/n) "
		read RESPONSE;
	elif [ "$1"="-y"] ;
		then
		cho -e "\nAdding following content to fstab"
                cat /etc/fstab_uuid 
		RESPONSE="y"
	fi
else
	RESPONSE="no"
	echo -e "\nNo changes to write !"
fi

#Check if change should be written
case "$RESPONSE" in
        [yY]|[yY][eE][sS])                                              # If answer is yes, update /etc/fstab with /etc/fstab_uuid
                echo "Writing changes to /etc/fstab..."
		cp /etc/fstab_uuid /etc/fstab
                ;;
        [nN]|[nN][oO]|"")                                               # If answer is no, or if the user just pressed Enter
                echo "Aborting: Not saving changes..."                  # don't save the new fstab file and remove processed file
                rm /etc/fstab_uuid 2>/dev/null
                ;;
        *)                                                              # If answer is anything else, exit and don't save changes
                echo "Exiting"
                rm /etc/fstab_uuid 2>/dev/null
                exit 1
                ;;
esac
rm /tmp/devices
echo "DONE!"

