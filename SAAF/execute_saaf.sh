#!/usr/bin/env bash

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
export PATH

PWD=`pwd`
SAAF="${PWD}/SAAF.jar"

GOOGLE_PLAY_DIR="${PWD}/google_play"
THIRD_PARTY_DIR="${PWD}/third_party"

GOOGLE_PLAY_APKS="${GOOGLE_PLAY_DIR}/*"
THIRD_PARTY_APKS="${THIRD_PARTY_DIR}/*"

echo -e "\nStart runing SAAF on APK files....\n"

for GOOGLE_PLAY_APK in ${GOOGLE_PLAY_APKS}
do
	echo -e "Processing ${GOOGLE_PLAY_APK} file ....\n"
	echo -e "${GOOGLE_PLAY_APK}\n"
	java -jar ${SAAF} -hl ${GOOGLE_PLAY_APK}
done

for THIRD_PARTY_APK in ${THIRD_PARTY_APKS}
do
	echo -e "Processing ${THIRD_PARTY_APK} file ....\n"
	echo -e "${THIRD_PARTY_APK}\n"
	java -jar ${SAAF} -hl ${THIRD_PARTY_APK}
done
