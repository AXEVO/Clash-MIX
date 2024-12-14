SKIPUNZIP=1

rm -rf $MODPATH && mkdir -p $MODPATH
unzip -o "${ZIPFILE}" -x 'META-INF/*' 'customize.sh' -d $MODPATH >&2
mv $MODPATH/Clash/* $MODPATH && rm -rf $MODPATH/Clash/
chmod 755 -Rf $MODPATH
