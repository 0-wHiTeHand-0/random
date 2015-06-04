#!/bin/sh
# You should run this as root.
######## START EDITING #######
TIME=5 # time to wait
TEMPNAME="temp_BS"
######## STOP EDITING #######

if [ $# -ne 2 ]; then
	echo "Syntax: sudo sh script.sh [device] [dest path]"
	exit 1
fi

#set -e

SIZE=0
TEMP_SIZE=0
BEST_BS=0

for BLOCK_SIZE in 512 1024 2048 4096 8192 16384 32768 67108864 65536 131072 262144 524288 1048576 2097152 4194304 8388608 16777216 33554432 134217728
do
	OUT_FILE=$2"_"$TEMPNAME"_"$BLOCK_SIZE
	dd if=$1 of=$OUT_FILE bs=$BLOCK_SIZE& pid=$!
	echo "Checking $BLOCK_SIZE bytes..."
	sleep $TIME
	kill -9 $pid
        wait $pid
	TEMP_SIZE=$(stat -c "%s" $OUT_FILE)
	if [ $TEMP_SIZE -gt $SIZE ]; then
		BEST_BS=$BLOCK_SIZE
		SIZE=$TEMP_SIZE
	fi
	rm $OUT_FILE
done

echo "The best blocksize is $BEST_BS. Running:"
echo "dd if=$1 of=$2 bs=$BEST_BS"
dd if=$1 of=$2 bs=$BEST_BS
