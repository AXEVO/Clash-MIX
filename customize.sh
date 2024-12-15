SKIPUNZIP=1

unzip -o "$ZIPFILE" -x 'META-INF/*' -d $MODPATH >&2
chmod 755 -Rf $MODPATH
