#!/usr/bin/env bash

set -e

while read app; do
	echo "installing $app"
	fdroidcl install $app
done <<<"com.jonjomckay.fritter
com.tailscale.ipn
com.wireguard.android
de.danoeh.antennapod
ml.docilealligator.infinityforreddit
net.mullvad.mullvadvpn
nl.viter.glider
org.mian.gitnex
org.mozilla.fennec_fdroid
org.schabi.newpipe
org.shadowice.flocke.andotp
org.xbmc.kore
se.leap.riseupvpn"
