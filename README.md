# BrightnessGUI
This is a Brightness and gamma GUI for xrandr.  Don't leave yet!  I've hated xrandr for forever.  However, xrandr has a --gamma option that is exactly like xgamma but without needing xgamma installed!  This only works for one monitor.

# Requirements
xrandr:

`apt install x11-xserver-utils`

`pacman -S xorg-xrandr`

yad:

`apt install yad`

`pacman -S yad`

awk:

`apt install gawk`

`pacman -S gawk`

# Additional Installation Notes

1. Give the sh script execution permission: `chmod +x brightnessAdjust.sh`
2. Make sure the .desktop and bash .sh script are in the same directory
