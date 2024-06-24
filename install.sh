#!/bin/bash

if [ ! -e music/music.conf ]; then 
   echo "First configure music.conf (use music.conf.def as definition file)"
   exit 1
fi

#if [ "$SPOTIFY_USER" = "" -o "$SPOTIFY_PASS" = "" ]; then
#   echo "./install.sh <spotify user> <spotify pass>"
#   exit 1
#fi


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

apt-get -y install libao-dev libasound2-dev libc6-dev libcrypt-dev libexpat1-dev libffi-dev
apt-get -y install libflac-dev libgcc-12-dev libicu-dev libncurses-dev libnsl-dev libogg-dev
apt-get -y install libpopt-dev libpython3-dev libpython3.11-dev librust-alsa-sys-dev librust-libc-dev
apt-get -y install librust-pkg-config-dev libstd-rust-dev libstdc++-12-dev libtinfo-dev libtirpc-dev libxml2-dev
apt-get -y install libz3-dev linux-libc-dev llvm-14-dev python3-dev python3.11-dev zlib1g-dev
apt-get -y install libasound2-dev libasound2-plugin-bluez libasound2-plugin-smixer libasound2-plugins alsaplayer-alsa

apt-get -y install cargo binutils g++ autoconf automake pkg-config

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

cargo install --root=$BASE/cargo  --locked librespot

echo ""
echo "librespot service installeren"
echo "---------------------------------------------------------------"
cp $BASE/librespot/spotify-connect.service /etc/systemd/system/


echo ""
echo "done."
echo ""

