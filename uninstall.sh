#!/bin/bash

BASE=/opt/music

echo ""
echo "Stopping and disabling services"
systemctl stop mympd
systemctl stop mpd
systemctl stop mpd.socket
systemctl stop spotify-connect
systemctl disable mympd
systemctl disable mpd
systemctl disable mpd.socket
systemctl disable spotify-connect

echo ""
echo "Removing installation from $BASE"

rm -rf $BASE
rm -rf src/*

echo ""
echo "done"
echo ""

