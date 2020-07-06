#!/bin/bash

THEME_NAME=Cecilia

if [[ $EUID -ne 0 ]]; then
    echo "Root privileges needed" 1>&2
    exit 1
fi

if ! command -v grub-mkconfig >/dev/null 2>&1 ; then
    echo "Command 'grub-mkconfig' not found" 1>&2
    exit 1
fi

if command -v xrandr >/dev/null 2>&1 ; then
    [ $(xrandr --listmonitors | awk -F= 'NR==1' | awk -F': ' '{print $2}') -gt 1 ] && read -n 1 -p "Please unplug external monitors and press any key to process..."
else
    read -n 1 -p "Please unplug external monitors and press any key to process..."
fi

# Find out the screen dpi
SCALING=1
if ! command -v hwinfo >/dev/null 2>&1 ; then
    echo "Command 'hwinfo' not found. Cannot determine monitor dpi"
else
    MONITOR=`hwinfo --monitor`
    if [ -n "$MONITOR" ]; then
        MODEL=$(echo "$MONITOR" | grep -m 1 Model)
        if [ -n "$MODEL" ]; then
            echo "Found monitor"$MODEL
        fi
        SIZE=$(echo "$MONITOR" | grep -m 1 Size | sed -n -E 's/ *Size[ :]*([0-9]+)x[0-9]+.*/\1/p')
        if [ -n "$SIZE" ]; then
            RES=$(echo "$MONITOR" | grep -m 1 Resolution | sed -n -E 's/ *Resolution[ :]*([0-9]+)x[0-9]+.*/\1/p')
            # Round to nearest number
            SCALING=$(((($RES / $SIZE) + 1) / 3))
            SCALING=$(($SCALING<1?1:$SCALING))
            SCALING=$(($SCALING>4?4:$SCALING))
        fi
    fi
fi

# Change sizes according to dpi
FONT_SIZE=$((13 * $SCALING)) 
ICON_WIDTH=$((25 * $SCALING))
ICON_HEIGHT=$((25 * $SCALING))
ITEM_ICON_SPACE=$((7 * $SCALING))
ITEM_HEIGHT=$((30 * $SCALING))
ITEM_SPACING=$((5 * $SCALING))

echo "Scaling factor: ${SCALING} => Apply font size: ${FONT_SIZE}"

# Copy folder to themes
rm -rf /boot/grub/themes/$THEME_NAME
cp -rf $THEME_NAME /boot/grub/themes
cp "Fonts/dejavu_"$FONT_SIZE".pf2" /boot/grub/themes/$THEME_NAME
sed -i 's/THEME_NAME/'"$THEME_NAME"'/' /boot/grub/themes/$THEME_NAME/theme.txt
sed -i 's/ICON_WIDTH/'"$ICON_WIDTH"'/' /boot/grub/themes/$THEME_NAME/theme.txt
sed -i 's/ICON_HEIGHT/'"$ICON_HEIGHT"'/' /boot/grub/themes/$THEME_NAME/theme.txt
sed -i 's/ITEM_ICON_SPACE/'"$ITEM_ICON_SPACE"'/' /boot/grub/themes/$THEME_NAME/theme.txt
sed -i 's/ITEM_HEIGHT/'"$ITEM_HEIGHT"'/' /boot/grub/themes/$THEME_NAME/theme.txt
sed -i 's/ITEM_SPACING/'"$ITEM_SPACING"'/' /boot/grub/themes/$THEME_NAME/theme.txt

# Replace GRUB_THEME variable
sed -i '/GRUB_THEME=/d' /etc/default/grub
sed -i -e '$a\' /etc/default/grub
echo "GRUB_THEME=\"/boot/grub/themes/"$THEME_NAME"/theme.txt\"" >> /etc/default/grub

# Update grub config
grub-mkconfig -o /boot/grub/grub.cfg

echo -e $THEME_NAME" GRUB theme installed, please reboot"



