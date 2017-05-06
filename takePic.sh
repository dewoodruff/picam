#!/bin/bash

OUTPUTDIR="/images"
SCRIPTSDIR="/root/picam/"
DRIVEUUID="7309-DD8D"
LOGFILE="$OUTPUTDIR/images.log"
SLEEPBETWEENPICS=300  ## note: delay will actually be this value plus the time it takes for the pi to boot and shutdown
# latitude and longitude for your location
LAT="43.049876N"
LON="-77.593224E"

mount -U $DRIVEUUID $OUTPUTDIR

# check to see if the script should run or not, based on the external switch position
echo "21" > /sys/class/gpio/export
echo "in" > /sys/class/gpio/gpio21/direction
sleep 1
SWITCH=`cat /sys/class/gpio/gpio21/value`
echo "21" > /sys/class/gpio/unexport

# if the switch is on, then exit and let the pi continue to operate
if [ "$SWITCH" -eq "1" ]; then
	exit
fi

# overwrite the original if there are any updates to the scripts on the USB
cp $OUTPUTDIR/scripts/takePic.sh $SCRIPTSDIR
cp $OUTPUTDIR/scripts/timediff.sh $SCRIPTSDIR

# take the picture
DATE=$(date +"%Y-%m-%d_%H%M")
raspistill -o "$OUTPUTDIR/image-$DATE.jpg" -ts --exif -ex=auto

# time stuff to figure out sleep delay so pictures aren't taken over night
RISESETSTRING=`$SCRIPTSDIR/sunwait/sunwait list $LAT $LON`
# split the string into two separate elements, one for rise, one for set
IFS=', ' read -r -a TIMEARR <<< $RISESETSTRING
RISETIME="${TIMEARR[0]}"
SETTIME="${TIMEARR[1]}"
NOW=`date "+%H:%M"`
# time between now and sunset
SUNSETDIFF=`$SCRIPTSDIR/timediff.sh "$NOW" "$SETTIME"`

# if we've already passed sunset, this will be negative and we'll want to sleep until sunrise
if [ $SUNSETDIFF -lt 0 ];
then
	# next picture should be after sunrise
	NOWTOMIDNIGHT=`$SCRIPTSDIR/timediff.sh "$NOW" "23:59:59"`
	MIDNIGHTTORISE=`$SCRIPTSDIR/timediff.sh "00:00:01" "$RISETIME"`
	SLEEPBETWEENPICS=$((NOWTOMIDNIGHT + MIDNIGHTTORISE))
fi

# write to log
echo "`date` - `sudo mopicli -v -v1 -v2 | tr '\n' ' '` SLEEP FOR: $SLEEPBETWEENPICS" >> $LOGFILE

# next power up
mopicli -won $SLEEPBETWEENPICS
# shutdown
mopicli -wsd 1
