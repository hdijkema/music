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

RUST=`rustc -vV`
if [ "$RUST" = "" ]; then
   echo "Execute "
   echo ""
   echo "    curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh"
   echo "    source $HOME/.cargo/env"
   echo ""
   echo "Make sure u use the right rust build for raspberry, preferrable 'nightly'"
   echo "Also pick 'minimal' for the raspberry PI, to save disk space"
   echo "When building librespot, a log of memory is needed. Be sure to have about"
   echo "2GB of virtual memory available (on a 1GB system)"
   echo ""
   echo "first"
   exit 0
fi

BASE=/opt/music
MUSIC_DIR=`cat /tmp/music.conf | grep music_dir | sed -e 's/[^=]*[=]\\s*//' | sed -e 's/\\s*$//'`
echo "Installing to $BASE"
echo "Music Dir = $MUSIC_DIR"
echo "---------------------------------------------------------------"

if [ ! -e $MUSIC_DIR ]; then
   echo "Music Dir '$MUSIC_DIR' does not exist"
   exit 1
fi


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

apt-get install aptitude

MYMPD=`aptitude search mympd`
if [ "$MYMPD" = "" ]; then
  # Download JCorporation's signing key locally and install it in a dedicated keyring
  curl http://download.opensuse.org/repositories/home:/jcorporation/Debian_11/Release.key | gpg --no-default-keyring --keyring /usr/share/keyrings/jcorporation.github.io.gpg --import

  # ⚠️ VERIFY the fingerprint of the downloaded key (A37A ADC4 0A1C C6BE FB75  372F AA09 B8CC E895 BD7D - home:jcorporation OBS Project <home:jcorporation@build.opensuse.org>) 
  gpg --no-default-keyring --keyring /usr/share/keyrings/jcorporation.github.io.gpg --fingerprint

  # Make the imported keyring world-readable
  chmod 644 /usr/share/keyrings/jcorporation.github.io.gpg

  # Get Debian VERSION_ID from os-release file
  source /etc/os-release
  echo $VERSION_ID

  # Add JCorporation APT repository and ensure releases are signed with the repository's official keys
  cat <<EOF > /etc/apt/sources.list.d/jcorporation.list
deb [signed-by=/usr/share/keyrings/jcorporation.github.io.gpg] http://download.opensuse.org/repositories/home:/jcorporation/Debian_$VERSION_ID/ ./
EOF
  cat /etc/apt/sources.list.d/jcorporation.list
fi

apt-get -y update
apt-get -y install git \
                   libao-dev libasound2-dev libc6-dev libcrypt-dev libexpat1-dev libffi-dev \
                   libflac-dev libgcc-12-dev libicu-dev libncurses-dev libnsl-dev libogg-dev \
                   libpopt-dev libpython3-dev libpython3.11-dev librust-alsa-sys-dev librust-libc-dev \
                   librust-pkg-config-dev libstd-rust-dev libstdc++-12-dev libtinfo-dev libtirpc-dev libxml2-dev \
                   libz3-dev linux-libc-dev llvm-14-dev python3-dev python3.11-dev zlib1g-dev \
                   libasound2-dev libasound2-plugin-bluez libasound2-plugin-smixer libasound2-plugins alsaplayer-alsa \
                   binutils g++ autoconf automake pkg-config \
                   mpg123 mpd mympd mpc shairport-sync gcc

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
   cat $file | sed -e "s%{BASE}%$BASE%g" > $BASE/$tfile
done
mkfifo $BASE/run/librespot.fifo

chmod 755 $BASE/librespot/*.sh
chmod 600 $BASE/etc/music.conf

(cd $BASE/librespot; gcc -o player player.c)

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
cat configs/mpd.conf | sed -e "s%{BASE}%$BASE%g" -e "s%{MUSIC_DIR}%$MUSIC_DIR%g" > /etc/mpd.conf
cat configs/shairport-sync.conf | sed -e "s%{BASE}%$BASE%g" -e "s%{MUSIC_DIR}%$MUSIC_DIR%g" > /etc/shairport-sync.conf
cp configs/asound.conf /etc
cp configs/libao.conf /etc
cp configs/mympd/* /var/lib/mympd/config

echo ""
echo "flac 123"
echo "---------------------------------------------------------------"
mkdir -p src
cd src
git clone https://github.com/flac123/flac123.git
cd flac123
./configure --prefix=$BASE
make
make install
cd ..


echo ""
echo "bluetooth"
echo "---------------------------------------------------------------"
apt-get -y install libasound2-plugin-bluez bluez-tools bluez-alsa-utils rfkill


echo ""
echo "installing services"
echo "---------------------------------------------------------------"
systemctl enable mpd
systemctl enable mympd
systemctl enable spotify-connect
systemctl enable bluetooth
systemctl enable bluealsa
systemctl enable bluealsa-aplay
systemctl start mpd
systemctl start mympd
systemctl start spotify-connect
systemctl start bluetooth
systemctl start bluealsa
systemctl start bluealsa-aplay

echo ""
echo "removing /tmp/music.conf"
echo "---------------------------------------------------------------"
rm -f /tmp/music.conf

echo ""
echo "done."
echo ""
echo "Consider enabling the hardware watchdog on raspberry pi"
echo "Also look closely at /etc/asound.conf to configure the right sound card (aplay -L)"
echo ""

