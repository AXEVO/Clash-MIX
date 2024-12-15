SKIPUNZIP=1

rm -rf $MODPATH/*
unzip -o $ZIPFILE /Clash -d $TMPDIR >&2
mv $TMPDIR/Clash/* $MODPATH
chmod 755 -Rf $MODPATH
