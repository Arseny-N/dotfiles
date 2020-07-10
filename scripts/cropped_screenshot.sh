#!/bin/bash


TITLE=ScreenOCR # set yad variables
ICON=gnome-screenshot

# - tesseract won't work if LC_ALL is unset so we set it here
# - you might want to delete or modify this line if you 
#   have a different locale:

export LC_ALL=en_US.UTF-8

PREFIX="CropperScreenshot"
SCREENSHOT_ROOT=$HOME/Pictures/ScreenShots

# language selection dialog
LANG=$(yad \
    --width 300 --entry --title "$TITLE" \
    --image=$ICON \
    --window-icon=$ICON \
    --button="ok:0" --button="cancel:1" \
    --text "Select language:" \
    --entry-text \
    "eng" "ita" "ru" "fr")
RET=$? # check return status



# WM-Close or "cancel"
if [ "$RET" = 252 ] || [ "$RET" = 1 ]; then exit; fi

echo "Language set to $LANG"


mkdir -p SCREENSHOT_ROOT

FILE=$(date +"${SCREENSHOT_ROOT}/${PREFIX}_%Y-%m-%d_%H:%M:%S.png")

scrot -s $FILE -q 100 

TEXT=$(tesseract -l $LANG $FILE stdout) 

KEY=$RANDOM

yad --file --add-preview --filename $FILE --plug=$KEY --tabnum=1 &
echo $TEXT | yad --text-info --plug=$KEY --tabnum=2 &

yad --notebook --key=$KEY --tab="Image" --tab="Text"

feh $FILE

exit