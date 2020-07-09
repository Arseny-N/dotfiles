#!/bin/bash


TITLE=ScreenOCR # set yad variables
ICON=gnome-screenshot

# - tesseract won't work if LC_ALL is unset so we set it here
# - you might want to delete or modify this line if you 
#   have a different locale:

export LC_ALL=en_US.UTF-8

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

if [ "$RET" = 252 ] || [ "$RET" = 1 ]  # WM-Close or "cancel"
  then
      exit
fi

echo "Language set to $LANG"


# PREFIX=$(yad \
#     --width 300 --entry --title "$TITLE" \
#     --image=$ICON \
#     --window-icon=$ICON \
#     --button="ok:0" --button="cancel:1" \
#     --text "Input prefix (leave empty for default):" \
#     --entry)
#
#if [ -z $PREFIX ]; then
PREFIX="CropperScreenshot"
#fi


RET=$? # check return status

if [ "$RET" = 252 ] || [ "$RET" = 1 ]  # WM-Close or "cancel"
  then
      exit
fi

echo "Prefix set to $PREFIX"
# - You can modify the list of available languages by editing the line above
# - Make sure to use the same ISO codes tesseract does (man tesseract for details)
# - Languages will of course only work if you have installed their respective
#   language packs (https://code.google.com/p/tesseract-ocr/downloads/list)

mkdir -p $HOME/Pictures/ScreenShots

FILE=$(date +"$HOME/Pictures/ScreenShots/${PREFIX}_%Y-%m-%d_%H:%M:%S.png")

scrot -s $FILE -q 100 

tesseract -l $LANG $FILE stdout | yad --text-info --title "Tesseracted"

feh $FILE

# yad --plug=12345 --tabnum=1 --text="first tab with text" &> res1 &
# yad --plug=12345 --tabnum=2 --text="second tab" --entry &> res2 &
# yad --notebook --key=12345 --tab="Tab 1" --tab="Tab 2"

exit