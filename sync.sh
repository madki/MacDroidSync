#! /bin/bash

# function to parse android date to epoch
function parseDate() {
  epochDate=$(date -j -f "%Y-%m-%d %H:%M" "$1" +%s)
  echo $epochDate
}

# function to delete file from mac
function macDelete() {
  rm $comp_path/"$*"
}

# function to copy a file to mac
function cpToMac() {
  adb pull $mobile_path/"$*" $comp_path/
}

# function to delete file from phone
function mobDelete() {
  adb shell rm $mobile_path/"$*"
}

# function to copy a file to phone
function cpToMob() {
  adb push $comp_path/"$*" $mobile_path/
}

# Reading config file and saving paths
comp_path=$(grep 'comp ' config.txt | sed 's/comp //')
mobile_path=$(grep 'mobile ' config.txt | sed 's/mobile //')

# acquiring the file list with modified times
find $comp_path -type f -print0 | xargs -0 stat -f "%N %m" | grep -v '/\.'| sed 's/.*\///' > comp_files.tmp
adb shell ls -l $mobile_path | grep ".mp3" | sed "s/.*\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\} [0-9]\{2\}:[0-9]\{2\}\) \(.*.mp3\)/\2 \1/" > mob_files.tmp
adb shell ls -l $mobile_path | grep ".jpg" | sed "s/.*\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\} [0-9]\{2\}:[0-9]\{2\}\) \(.*.jpg\)/\2 \1/" >> mob_files.tmp

sed 's|\(.*\)\.\(.*\) \(.*\)|\1\.\2|' comp_files.tmp > comp_file_names.tmp
sed 's|\(.*\)\.\([^ ]*\) .*|\1\.\2|' mob_files.tmp > mob_file_names.tmp
#ls $comp_path > comp_file_names.tmp
#adb shell ls $mobile_path > mob_file_names.tmp

while read
do
    cpToMob "$REPLY"
    echo "copied $REPLY"
done < <(comm -13 <(sort mob_file_names.tmp) <(sort comp_file_names.tmp))

while read
do
    mobDelete "$REPLY"
    echo "deleted $REPLY"
done < <(comm -23 <(sort mob_file_names.tmp) <(sort comp_file_names.tmp))
adb shell am broadcast -a android.intent.action.MEDIA_MOUNTED -d file:///mnt/sdcard/Music
