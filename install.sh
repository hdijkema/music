#!/bin/bash

if [ ! -e /tmp/music.conf ]; then 
   echo ""
   echo "First configure music.conf (use music.conf.def as definition file)"
   echo "Copy etc/music.conf.def to /tmp/music.conf and modify the parameters as needed"
   echo ""
   echo "Set the music directory in configs/mpd.conf"
   echo ""
   echo ""
   exit 0
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
mkdir -p $BASE/shairport-sync
mkdir -p $BASE/src
mkdir -p $BASE/log
mkdir -p $BASE/run


echo "Installing libraries"
echo "---------------------------------------------------------------"

apt-get -y install git \
                   libao-dev libasound2-dev libc6-dev libcrypt-dev libexpat1-dev libffi-dev \
                   libflac-dev libgcc-12-dev libicu-dev libncurses-dev libnsl-dev libogg-dev \
                   libpopt-dev libpython3-dev libpython3.11-dev librust-alsa-sys-dev librust-libc-dev \
                   librust-pkg-config-dev libstd-rust-dev libstdc++-12-dev libtinfo-dev libtirpc-dev libxml2-dev \
                   libz3-dev linux-libc-dev llvm-14-dev python3-dev python3.11-dev zlib1g-dev \
                   libasound2-dev libasound2-plugin-bluez libasound2-plugin-smixer libasound2-plugins alsaplayer-alsa \
                   cargo binutils g++ autoconf automake pkg-config \ 
                   mpg123 mpd mympd

echo "Installing Librespot Scripts"
echo "---------------------------------------------------------------"
FILES=`ls librespot/* shairport-sync/* /tmp/music.conf`
for file in $FILES
do
   echo "handling $file"
   tfile=$file
   if [ "$file" = "/tmp/music.conf" ]; then
      tfile="etc/music.conf"
   fi
   cat $file | sed -e 's%{BASE}%$BASE%g' > $BASE/$tfile
done
mkfifo $BASE/run/librespot.fifo

chmod 755 $BASE/librespot/*.sh

echo ""
echo "cargo librespot"
echo "---------------------------------------------------------------"

cargo install --root=$BASE/cargo  --locked librespot

echo ""
echo "librespot service installeren"
echo "---------------------------------------------------------------"
cp $BASE/librespot/spotify-connect.service /etc/systemd/system/

echo ""
echo "copy configuration files"
echo "---------------------------------------------------------------"
cp configs/mpd.conf /etc
cp configs/shairport-sync.conf /etc
cp configs/asound.conf /etc
cp configs/libao.conf /etc

echo ""
echo "flac 123"
echo "---------------------------------------------------------------"
cd src
git clone https://github.com/flac123/flac123.git
cd flac123
./configure --prefix=$BASE
make
make install

echo ""
echo "installing services"
echo "---------------------------------------------------------------"
systemctl enable mpd
systemctl enable mympd
systemctl enable spotify-connect
systemctl start mpd
systemctl start mympd
systemctl start spotify-connect



echo ""
echo "done."
echo ""

