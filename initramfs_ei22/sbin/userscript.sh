#!/sbin/sh
# Remount filesystems RW
busybox mount -o remount,rw /
busybox mount -o remount,rw /system

# Install busybox and clean prior links if not detected
if busybox test ! -f /system/xbin/busybox -a ! -f /system/bin/busybox; then
  for dir in bin xbin; do
    for link in `busybox find /system/$dir -type l`; do
      linktest="`busybox readlink $link`"
      if busybox test "`echo $linktest | grep busybox`" != "" -o "`echo $linktest | grep recovery`" != ""; then 
        busybox rm $link
        if busybox test -e $linktest -a "$linktest" != "/sbin/busybox"; then
          busybox rm $linktest
        fi
      fi
    done
  done
  mkdir /bin
  for link in `busybox --list`; do
    busybox ln -s /sbin/busybox /sbin/$link
  done
  busybox ln -s /sbin/busybox /system/xbin/busybox
fi

sync

# Setup su binary
if test ! -f /system/bin/su; then
  busybox rm -f /system/xbin/su
  busybox cp -f /sbin/su /system/bin/su
  busybox chmod 6755 /system/bin/su
fi
busybox rm -f /bin/su
busybox rm -f /sbin/su
busybox rm -f /xbin/su

# Install Superuser.apk (only if not installed)
if test ! -f /system/app/Superuser.apk -a ! -f /data/app/Superuser.apk  -a  ! -f /data/app/com.noshufou.android.su*; then
  dfsys=`busybox df /system | busybox grep system | busybox awk -F ' ' '{ print $4 }'`
  if test $dfsys -lt 1000; then
    busybox cp /sbin/Superuser.apk /data/app/Superuser.apk
  else
    busybox cp /sbin/Superuser.apk /system/app/Superuser.apk
  fi
# remove pre-existing data (if exists)
  busybox test -d /data/data/com.noshufou.android.su || busybox rm -r /data/data/com.noshufou.android.su
fi
sync

# Enable init.d support
if test -d /system/etc/init.d; then
  logwrapper busybox run-parts /system/etc/init.d
fi
sync

# Fix screwy ownerships
for blip in default.prop fota.rc init init.rc lib lpm.rc recovery.rc sbin bin
do
  chown root.shell /$blip
  chown root.shell /$blip/*
done

chown root.shell /lib/modules/*

#setup proper passwd and group files for 3rd party root access
# Thanks DevinXtreme
if test ! -f /system/etc/passwd; then
  echo "root::0:0:root:/data/local:/system/bin/sh" > /system/etc/passwd
  chmod 0666 /system/etc/passwd
fi
if test ! -f /system/etc/group; then
  echo "root::0:" > /system/etc/group
  chmod 0666 /system/etc/group
fi

# fix busybox DNS while system is read-write
if test ! -f /system/etc/resolv.conf; then
  echo "nameserver 8.8.8.8" >> /system/etc/resolv.conf
  echo "nameserver 8.8.4.4" >> /system/etc/resolv.conf
fi

sync

if test -f /system/media/bootanimation.zip; then
  ln -s /system/media/bootanimation.zip /system/media/sanim.zip
fi

# remount read only and continue
busybox  mount -o remount,ro /
busybox  mount -o remount,ro /system
