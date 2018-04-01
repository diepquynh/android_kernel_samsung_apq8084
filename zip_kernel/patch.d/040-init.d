#!/sbin/sh

. "$env";

cd "$tmp" && [ "$(ls)" ] || exit 0;

# Make init.d path if non-existent
print "Initializing init.d support...";
mkdir /system/etc/init.d;
chmod 755 /system/etc/init.d;

# Copy busybox into system
cp -f system/bin/busybox /system/bin/busybox;
cp -f system/etc/init.d/* /system/etc/init.d/;

# Change permissions
chmod 755 /system/bin/busybox;
chmod -R 755 /system/etc/init.d;

print "Done!";
exit 0;
