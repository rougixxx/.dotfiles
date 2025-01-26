#!/bin/bash

# Extract the current brightness using brightnessctl
current_brightness=$(brightnessctl i | grep 'Current brightness' | awk '{print $4}' | tr -d '()' )
current="${current_brightness}"
echo $current
