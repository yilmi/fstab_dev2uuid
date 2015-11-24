#!/bin/bash
# Credits : Buuntu from ubuntu forums :http://ubuntuforums.org/showthread.php?t=1508991
# This script will change all fstab entries form device name format to UUID names format

#Working directories
WD=/etc
GRUBWD=/boot/grub
GRUBLIST=menu.lst

#Check for superuser uid
if [ `id -u` -ne 0 ]; 
	then
        echo "This script must be run as root" >&2
        exit 1
fi

#Check for existing backup, if file exist, user will have to remove it manually 
if [[ -f $WD/fstab.backup || -f $GRUBWD/$GRUBLIST.backup ]]
	then
	echo "Backup file found in $WD/fstab.backup or $GRUBWD/$GRUBLIST.backup, please delete backup"
	exit
else 
	#Backup fstab file
	cp $WD/fstab $WD/fstab.backup

        #Backup grub menu list
	cp $GRUBWD/$GRUBLIST $GRUBWD/$GRUBLIST.backup
	
fi

#List devices with name starting with hd or sd from $WD/fstab and extract those to /tmp/devices as /dev/sdx - /dev/hdx
sed -n 's|^/dev/\([sh]d[a-z][0-9]\).*|\1|p' <$WD/fstab >/tmp/devices

#Prepare fstab_uuid
cp $WD/fstab $WD/fstab_uuid

#Prepare grub_uuid
cp $GRUBWD/$GRUBLIST $GRUBWD/$GRUBLIST.uuid

#Parse /tmp/devices and look for /dev/disk/by-uuid symlinks to map uuid to block device 
while read LINE; do                                                     # For each line in /tmp/devices
        UUID=`ls -l /dev/disk/by-uuid | grep "$LINE" | sed -n 's/^.* \([^ ]*\) -> .*$/\1/p'`	# Sets the UUID name for that device
        sed -i "s|^/dev/${LINE}|UUID=${UUID}|" $WD/fstab_uuid   				# output UUID based to fstab_uuid file
        sed -i "s|^/dev/${LINE}|UUID=${UUID}|" $GRUBWD/$GRUBLIST.uuid
done </tmp/devices

#Check if there is any content to write to file
if [[ -s $WD/fstab_uuid ]] 
	then
	#if 1st switch is -y will not ask for confirmation
	if  [ "$1"!="-y" ] 
		then
		
		echo -e "\nThe following content will be added to fstab"
		cat $WD/fstab_uuid
		
		echo -e "\nThe following content will be added to grub menu"		
		cat $GRUBWD/$GRUBLIST.uuid
		
		printf "\n\nWrite changes to $WD/fstab and $GRUBWD/$GRUBLIST ? (y/n) "
		read RESPONSE;
		
	elif [ "$1"="-y"]
                then
		echo -e "\nAdding following content to fstab"
                cat $WD/fstab_uuid 
		RESPONSE="y"
	fi
else
	RESPONSE="no"
	echo -e "\nNo changes to write !"
fi

#Check if change should be written
case "$RESPONSE" in
        [yY]|[yY][eE][sS])                                              # If answer is yes, update $WD/fstab with $WD/fstab_uuid
                echo "Writing changes to $WD/fstab..."
		cp $WD/fstab_uuid $WD/fstab
		cp $GRUBWD/$GRUBLIST.uuid $GRUBWD/$GRUBLIST
                ;;
        [nN]|[nN][oO]|"")                                               # If answer is no, or if the user just pressed Enter
                echo "Aborting: Not saving changes..."                  # don't save the new fstab file and remove processed file
                rm $WD/fstab_uuid 2>/dev/null
                ;;
        *)                                                              # If answer is anything else, exit and don't save changes
                echo "Exiting"
                rm $WD/fstab_uuid 2>/dev/null
                exit 1
                ;;
esac
rm /tmp/devices
echo "DONE!"

