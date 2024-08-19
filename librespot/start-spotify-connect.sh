#!/bin/bash

BASE=/opt/music
LOG_BASE="$BASE/log"

LOG=$LOG_BASE/librespot.log
APLAY_LOG=$LOG_BASE/aplay.librespot.log

STATUS_DEVICE=`cat $BASE/etc/music.conf | grep asound_status_device | sed -e 's/[^=]*[=]\\s*//' | sed -e 's/\\s*$//'`
SEC=`cat $BASE/etc/music.conf | grep status_check_interval | sed -e 's/[^=]*[=]\\s*//' | sed -e 's/\\s*$//'`
SPOTIFY_USER=`cat $BASE/etc/music.conf | grep spotify_user | sed -e 's/[^=]*[=]\\s*//' | sed -e 's/\\s*$//'`
SPOTIFY_PASS=`cat $BASE/etc/music.conf | grep spotify_pass | sed -e 's/[^=]*[=]\\s*//' | sed -e 's/\\s*$//'`
CONNECT_NAME=`cat $BASE/etc/music.conf | grep connect_name | sed -e 's/[^=]*[=]\\s*//' | sed -e 's/\\s*$//'`

echo "status_device=$STATUS_DEVICE" >>$LOG

if [ ! -e $STATUS_DEVICE ]; then 
   echo "Not found."
   exit 1
fi

echo "status_check_interval=$SEC" >>$LOG
echo "Spotify User=$SPOTIFY_USER" >>$LOG
echo "Spotify Connect Name=$CONNECT_NAME" >>$LOG

EVENT_HANDLER="$BASE/librespot/sink_event.sh"
EVENT_FILE=$BASE/run/last_event.librespot
FIFO=$BASE/run/librespot.fifo

echo "" >$EVENT_FILE

function log()
{
  DT=`date`
  echo "$DT - $@"	>>$LOG
}

function alog()
{
  DT=`date`
  echo "$DT - $@"	>>$APLAY_LOG
}

echo "#########################################" >>$LOG
echo "Spotify Connect Service ($@)" >>$LOG

if [ ! -e $FIFO ]; then
   mkdir -p $BASE/run
   mkfifo $FIFO
fi

export PATH=$PATH:$BASE/cargo/bin

rm -rf $BASE/runspotify-cache 

while [ 1 ]; do
  LIBRESPOT=`ps ax | grep librespot | grep -v start | grep -v aplay | grep -v grep | grep -v tail`
  if [ "$LIBRESPOT" = "" ]; then
    echo librespot --emit-sink-events --onevent $EVENT_HANDLER --backend pipe --device $FIFO -n "$CONNECT_NAME" -b 320 -c $BASE/runspotify-cache -u  "$SPOTIFY_USER" -p "<password>" >>$LOG 2>&1 &
    #librespot --emit-sink-events --onevent $EVENT_HANDLER --backend pipe --device $FIFO -n "$CONNECT_NAME" -b 320 -c $BASE/runspotify-cache -u "$SPOTIFY_USER" -p "$SPOTIFY_PASS" >>$LOG 2>&1 &
    #librespot --emit-sink-events --onevent $EVENT_HANDLER --backend rodio -n "$CONNECT_NAME" -b 320 -c $BASE/runspotify-cache -u "$SPOTIFY_USER" -p "$SPOTIFY_PASS" >>$LOG 2>&1 &
    librespot --initial-volume 100 --emit-sink-events --onevent $EVENT_HANDLER --backend pipe -n "$CONNECT_NAME" -b 320 -c $BASE/runspotify-cache -u "$SPOTIFY_USER" -p "$SPOTIFY_PASS" | /opt/music/librespot/player >>$LOG 2>&1 &
  fi

  STATUS=`cat $STATUS_DEVICE`
  if [ "$STATUS" = "closed" ]; then
     LAST_EVENT=`cat $EVENT_FILE`
     if [ "$LAST_EVENT" = "play" ]; then
        alog "Playback device: playing"
        aplay -f cd $FIFO >>$APLAY_LOG 2>&1
        alog "Playback device: stopped playing"
     fi
  fi

  sleep $SEC
done

