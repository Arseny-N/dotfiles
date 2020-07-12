#!/bin/bash
#
# Orignal source taken from some Ubuntu forum thread 
#



PICTURE_PREFIX="CropperScreenshot"
SCREENSHOT_ROOT="$HOME/Pictures/ScreenShots"

WINDOW_STYLE="--title ScreenshotPlus --window-icon=gnome-screenshot"


# TODO: Does tesseract work for non english without the right locale ?
export LC_ALL=en_US.UTF-8


# Language selection dialog
LANG=$(yad $WINDOW_STYLE\
    --width 300 --entry \
    --button="ok:0" --button="cancel:1" \
    --text "Select language:" \
    --entry-text \
    "eng" "ita" "ru" "fr")
RET=$? 
# WM-Close or "cancel"
if [ "$RET" = 252 ] || [ "$RET" = 1 ]; then exit; fi

echo "Language set to $LANG"


FILE=$(date +"${SCREENSHOT_ROOT}/${PICTURE_PREFIX}_%Y-%m-%d_%H:%M:%S.png")

scrot -s $FILE -q 100 

TEXT=$(tesseract -l $LANG $FILE stdout) 

KEY=$RANDOM

yad --file --add-preview --filename $FILE --plug=$KEY --tabnum=1 &
echo $TEXT | yad --text-info --plug=$KEY --tabnum=2 &

yad $WINDOW_STYLE --notebook --key=$KEY --tab="Image" --tab="Text"
RET=$? 
if [ "$RET" = 252 ] || [ "$RET" = 1 ]; then exit; fi

feh $FILE

exit