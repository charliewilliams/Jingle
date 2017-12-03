#!/bin/sh

# Set the given Info.plist's build number based on the current date and optionally 
# a prefix which is passed in

if [ $# -lt 1 ]; then
    echo usage: $0 plistfilepath [prefix-number] 
    exit 1
fi

timeStampSuffix=($(date -u +"%Y.%m.%d.%H.%M"))

prefix="$2"
if [[ ! -z "$prefix" ]]; then
    timeStampSuffix="${prefix}.${timeStampSuffix}"
fi
echo "build number: ${timeStampSuffix}";

plist="${1}"

/usr/libexec/Plistbuddy -c "Set CFBundleVersion $timeStampSuffix" "$plist";

echo "Done bumping build number 💅 ";
