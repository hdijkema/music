#!/bin/bash

SPOTIFY_USER=$1
SPOTIFY_PASS=$2

if [ "$SPOTIFY_USER" = "" -o "$SPOTIFY_PASS" = "" ]; then
   echo "./install.sh <spotify user> <spotify pass>"
   exit 1
fi


BASE=/opt/music
echo "Installing to $BASE"
echo "---------------------------------------------------------------"


echo "Creating $BASE/<subdirs>"
echo "---------------------------------------------------------------"
mkdir -p $BASE
mkdir -p $BASE/etc
mkdir -p $BASE/librespot
mkdir -p $BASE/mpd
mkdir -p $BASE/shairpoint-sync
mkdir -p $BASE/src
mkdir -p $BASE/log
mkdir -p $BASE/run


echo "Installing Librespot Scripts"
echo "---------------------------------------------------------------"

cd librespot
for file in *
do
   cat $file | sed -e 's%{BASE}%$BASE%g' > $BASE/librespot/$file
done
mkfifo $BASE/run/librespot.fifo
cd ..

echo ""
echo "cargo librespot"
echo "---------------------------------------------------------------"

apt install cargo binutils g++ autoconf 
apt install aplay
cargo install --root=$BASE/cargo  --locked librespot

echo ""
echo "done."
echo ""

