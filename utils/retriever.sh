#!/bin/sh
#
######################################################################
## retriever.sh
## 
## Fetch only the freshest of dbdumps for our shenanigans.
######################################################################

MIRROR=ftp://ftp.musicbrainz.org/pub/musicbrainz/data/fullexport
LOCALDIR=/talecaster/musicbrainz/dbdump

get_latest()
{
	## XXX: Always use IPv4 due to some issues with IPv6
	wget -q -4 -O $LOCALDIR/LATEST $MIRROR/LATEST
	if [ $? -ne 0 ]; then
		echo "Retrieving LATEST identifier failed: $?"
		exit 255
	fi
	echo "Retrieved LATEST"
	echo "LATEST is $(cat $LOCALDIR/LATEST)"
	
	export LATEST=$(cat $LOCALDIR/LATEST)
}

get_checksums()
{
	## This is the easiest way to get a quick file list.
	for f in MD5SUMS SHA256SUMS MD5SUMS.asc SHA256SUMS.asc; do
		wget -q -4 -O $LOCALDIR/$f $MIRROR/$LATEST/$f
		if [ $? -ne 0 ]; then
			RC=$?
			echo "Failed to retrieve $f: $RC"
			exit $RC
		fi
	done
}

retrieve_files()
{
	## We make fun.
	for rf in `cat $LOCALDIR/MD5SUMS | awk '{print $2}' | sed -e 's/\*//g'`; do
		wget -q -4 -O "$LOCALDIR/$rf".asc "$MIRROR/$LATEST/$rf".asc
		if [ $? -ne 0 ]; then
			RC=$?
			echo "Failed to retrieve '$rf'.asc : $RC"
			exit $RC
		fi
		wget --progress=dot -4 -O "$LOCALDIR/$rf" "$MIRROR/$LATEST/$rf"
		if [ $? -ne 0 ]; then
			RC=$?
			echo "Failed to retrieve '$rf' : $RC"
			exit $RC
		fi
	done
}

md5_validate()
{
	pushd $LOCALDIR/ && md5sum -c $LOCALDIR/MD5SUMS && popd
}

gpg_validate()
{
	gpg --recv-keys C777580F
	gpg --verify-files $LOCALDIR/*.asc
}

get_latest
get_checksums
retrieve_files
md5_validate
gpg_validate
