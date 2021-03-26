totalSpace="$(df /home/$USER --output=size | tail -1)"
usedSpace="$(df /home/$USER --output=used | tail -1)"
availableSpace="$(df /home/$USER --output=avail | tail -1)"
reservedSpace="$(($totalSpace - $usedSpace - $availableSpace))"

totalSpace=9736500
usedSpace=8820784
availableSpace=401412
reservedSpace=514304

echo "totalSpace: $totalSpace"
echo "usedSpace: $usedSpace"
echo "availableSpace: $availableSpace"
echo "reservedSpace: $reservedSpace"

takenSpacePercentage=$(awk -v totalSpace="$totalSpace" -v usedSpace="$usedSpace" -v reservedSpace="$reservedSpace" 'BEGIN{print (usedSpace+reservedSpace)/totalSpace}' | tr ',' '.')
echo $takenSpacePercentage