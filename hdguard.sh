#!/bin/bash

getUsedSpacePercentage() {
    # Calculating it our own way that trims the decimal reminder
    # instead of rounding the result to the nearest integer like df does
    local totalSpace="$(df /home/$USER --output=size | tail -1)"
    local usedSpace="$(df /home/$USER --output=used | tail -1)"
    local availableSpace="$(df /home/$USER --output=avail | tail -1)"
    # There is also some unavailable space on the partition that we have to
    # take into account when calculating totals
    local reservedSpace="$(($totalSpace - $usedSpace - $availableSpace))"
    usedSpacePercentage=$(awk -v totalSpace="$totalSpace" -v usedSpace="$usedSpace" -v reservedSpace="$reservedSpace" 'BEGIN{print ((usedSpace+reservedSpace)/totalSpace)*100}' | tr ',' '.')
    echo $usedSpacePercentage
}

showPartitionInformation() {
    local partition=$(df /home/$USER --output=source | tail -1)
    echo "Partition containing /home/\$USER:  $partition"

    local disk="$(lsblk -no pkname $partition)"
    echo "Disk containing $partition:         $disk"

    local totalSpace="$(df /home/$USER -h --output=size | tail -1)"
    echo "Partition size:                   $totalSpace"

    local usedSpace="$(df /home/$USER -h --output=used | tail -1)"
    echo "Used space:                       $usedSpace"

    local availableSpace="$(df /home/$USER -h --output=avail | tail -1)"
    echo "Available space:                  $availableSpace"

    echo ""
}

showTitle() {
    echo ""
    echo "    _    _ _____       _____                     _ "
    echo "   | |  | |  __ \     / ____|                   | |"
    echo "   | |__| | |  | |   | |  __ _   _  __ _ _ __ __| |"
    echo "   |  __  | |  | |   | | |_ | | | |/ _\` | '__/ _\` |"
    echo "   | |  | | |__| |   | |__| | |_| | (_| | | | (_| |"
    echo "   |_|  |_|_____/     \_____|\__,_|\__,_|_|  \__,_|"
    echo ""
    showPartitionInformation
}

delayWithDots() {
    local delayLength=$1
    while [ $delayLength -gt 1 ]; do
        echo -n "."
        delayLength=$(($delayLength - 1))
        sleep 1
    done
}

help() {
    echo "hdguard [LIMIT] [-h]"
    echo ""
    echo "Monitor /home/\$USER partition free space."
    echo "Automatically prompt user with a list of suggested files to delete."
    echo "Files to delete are suggested based on their size."
    echo ""
    echo "  LIMIT          percentage of taken up partition space at which"
    echo "                   the script starts warning the user;"
    echo "                   numeric value, from 1 to 99"
    echo ""
    echo "Options:"
    echo "  -h, --help     display the help message"
    echo ""
    echo "Examples:"
    echo "  ./hdguard 70"
    echo "  ./hdguard 25"
}

showRunWithHelp() {
    echo "Run with --help to check how to use the script."
}

getLimitFromArguments() {
    local argumentAmount=$1
    local argument=$2
    if [ $argumentAmount -lt 1 ]; then
        echo "No arguments provided."
        showRunWithHelp
        exit 1
    fi
    if [ $argumentAmount -gt 1 ]; then
        echo "Passed too many arguments."
        showRunWithHelp
        exit 1
    fi
    if [[ "$argument" = "--help" || "$argument" = "-h" ]]; then
        help
        exit 1
    fi
    limit="$argument"
    local numberRegex='^[0-9]+$'
    if ! [[ "$limit" =~ $numberRegex ]]; then
        echo "Passed an invalid size limit value."
        showRunWithHelp
        exit 1
    fi
    if [[ "$limit" -lt 1 || "$limit" -gt 99 ]]; then
        echo "Passed an invalid size limit value."
        showRunWithHelp
        exit 1
    fi
}

fileDeletion() {
    echo ""
    echo "File deletion"
    echo ""

    rm -f /tmp/hdguard-file-list
    find /home/$USER -perm /u+w,g+w -user $USER -not -path '*/.*' -type f -ls | tr -s ' ' | sort -rn -k7 | cut --complement -d' ' -f1,2,3,4,5,6,7,9,10,11 | awk '{print 1 " " NR " " $0}' >/tmp/hdguard-file-list

    if ! [ -s /tmp/hdguard-file-list ]; then
        echo "No deletable files found"
        exit 1
    fi

    local totalSpace="$(df /home/$USER --output=size | tail -1)"
    local usedSpacePercentage=$(getUsedSpacePercentage)

    ### DEBUG ###
    # cat /tmp/hdguard-file-list | head -50
    # local usedSpace="$(df /home/$USER --output=used | tail -1)"
    # local availableSpace="$(df /home/$USER --output=avail | tail -1)"
    # local reservedSpace="$(($totalSpace - $usedSpace - $availableSpace))"
    echo "totalSpace:             $totalSpace KB"
    # echo "usedSpace:              $usedSpace"
    # echo "availableSpace:         $availableSpace"
    # echo "reservedSpace:          $reservedSpace"
    echo "usedSpacePercentage:      $usedSpacePercentage%"
    # head -10 </tmp/hdguard-file-list
    ### DEBUG ###

    local percentageToDelete=$(echo "$usedSpacePercentage - $limit" | bc)
    echo "Total space % to delete:  $percentageToDelete%"
    local KBToDelete=$(echo "($percentageToDelete * $totalSpace / 100) + 1" | bc)
    echo "KB to delete:             $KBToDelete KB"
    local bytesToDelete=$(echo "$KBToDelete * 1024" | bc)
    echo "bytesToDelete: $          $bytesToDelete B"

    suggestedFilesSize=0
    while IFS= read -r line; do
        local fileSize=$(awk -F' ' '{print $3}' <<<$line)
        suggestedFilesSize=$(($suggestedFilesSize + $fileSize))
        if [ $suggestedFilesSize -gt $bytesToDelete ]; then
            break
        fi
    done </tmp/hdguard-file-list

    if [ $bytesToDelete -gt $suggestedFilesSize ]; then
        echo "Not enough deletable files found to free up disk space usage to $limit%"
        exit 1
    fi

    echo "suggestedFilesSize:       $suggestedFilesSize B"

}

limitReachedAction() {
    echo "Available space limit reached."
    echo ""
    echo "1) Delete files to free up space"
    echo "2) Ignore warning"
    echo "3) Ignore this and all future warnings"
    read -rsn1 selection
    case $selection in
    1)
        fileDeletion
        delayWithDots $timeDelay
        ;;
    2)
        echo ""
        echo "Ignored warning"
        echo ""
        delayWithDots $timeDelay
        ;;
    3)
        echo ""
        echo "Ignored warning and disabled future warnings"
        echo ""
        delayWithDots $timeDelay
        ignoreAllWarnings=true
        ;;
    *)
        echo ""
        echo "Incorrect selection."
        echo ""
        delayWithDots 3
        ;;
    esac

}

ignoreAllWarnings=false
getLimitFromArguments $# $1
timeDelay=5

# while true; do
#     while true; do
#         clear
#         showTitle
#         usagePercentage=$(getUsedSpacePercentage)
#         if [ "$ignoreAllWarnings" = false ] && [ $(echo "$usagePercentage > $limit" | bc) -ne 0 ]; then
#             break
#         fi
#         delayWithDots $timeDelay
#     done
#     limitReachedAction
# done

fileDeletion

exit 0
