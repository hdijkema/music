#!/bin/bash

BASE={BASE}
LOG_BASE="$BASE/log"
LOG=$LOG_BASE/sink_event.log

EVENT_FILE=$BASE/run/last_event.librespot

echo "" >>$LOG
date >>$LOG
echo "event: $PLAYER_EVENT" >>$LOG

if [ "$PLAYER_EVENT" = "sink" ]; then
  if [ "$SINK_STATUS" = "running" ]; then
     CTRLS=`amixer scontrols | sed -e s/^[^\']*[\']// -e 's/[ ]/_/g' -e s/[\']//g`
     for CTRL in $CTRLS; do C=`echo $CTRL | sed -e 's/_/ /g'`; echo $C; amixer sset "$C" 100%; done >>$LOG 2>&1
     echo "play" >$EVENT_FILE
  else
     echo "stop" >$EVENT_FILE
  fi
fi

