#!/bin/bash

BASE={BASE}
EVENT_FILE=$BASE/run/last_event.librespot

echo "event: $PLAYER_EVENT" >>/tmp/event
if [ "$PLAYER_EVENT" = "sink" ]; then
  if [ "$SINK_STATUS" = "running" ]; then
     echo "play" >$EVENT_FILE
  else
     echo "stop" >$EVENT_FILE
  fi
fi

