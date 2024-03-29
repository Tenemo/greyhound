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
    echo ""
    showPartitionInformation
    echo "Selected disk space % threshold:   $limit%"
    echo ""
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
    numberRegex='^[0-9]+$'
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

updateFilesToDelete() {
    local suggestedFilesByteSize=0
    filesToDelete=()
    while IFS= read -r line; do
        if ! [[ $(awk '{print $1}' <<<$line) -eq 0 ]]; then
            local fileSize=$(awk -F' ' '{print $3}' <<<$line)
            suggestedFilesByteSize=$(($suggestedFilesByteSize + $fileSize))
            IFS=$'\r\n'
            filesToDelete+=("$line")
            IFS=
            if [ $suggestedFilesByteSize -gt $bytesToDelete ]; then
                break
            fi
        fi
    done </tmp/hdguard-file-list
    if [ $bytesToDelete -gt $suggestedFilesByteSize ]; then
        echo ""
        echo "Not enough deletable files found to reduce disk space usage to $limit%"
        exit 1
    fi
    echo ""
    echo "Files currently selected for deletion:"
    echo ""
    for fileLine in ${filesToDelete[@]}; do
        echo $(cut --complement -d' ' -f1 <<<$fileLine | awk '{$2=($2/1024) " KB"; print}')
    done
    echo ""
    echo "Selected for deletion in total:    $(echo "($suggestedFilesByteSize / 1024) + 1" | bc) KB"
    echo ""
}

fileDeletionPrompt() {
    echo "Type [FILE_INDEX] and press ENTER to deselect the file from deletion."
    echo "The list will be then populated with next files."
    echo '"delete" + ENTER to start deleting selected files'
    echo '"abort" + ENTER to start abort the deletion process'
    echo ""
}

fileDeletion() {

    rm -f /tmp/hdguard-file-list
    find /home/$USER -perm /u+w,g+w -user $USER -not -path '*/.*' -type f -ls | tr -s ' ' | sort -rn -k7 | cut --complement -d' ' -f1,2,3,4,5,6,7,9,10,11 | awk '{print 1 " " NR " " $0}' >/tmp/hdguard-file-list

    if ! [ -s /tmp/hdguard-file-list ]; then
        echo ""
        echo "No deletable files found"
        exit 1
    fi

    local totalSpace="$(df /home/$USER --output=size | tail -1)"
    local usedSpacePercentage=$(getUsedSpacePercentage)
    local percentageToDelete=$(echo "$usedSpacePercentage - $limit" | bc)
    local KBToDelete=$(echo "($percentageToDelete * $totalSpace / 100) + 1" | bc)
    bytesToDelete=$(echo "$KBToDelete * 1024" | bc)

    declare -a filesToDelete
    while true; do
        clear
        showTitle
        echo "File deletion:"
        echo ""
        echo "Total space % to delete:           $percentageToDelete%"
        echo "Space to free up:                  $KBToDelete KB"
        updateFilesToDelete
        fileDeletionPrompt
        read -r selection
        case $selection in
        delete)
            dateTime=$(date +'%Y-%m-%d_%H:%M')
            declare -a deletedPaths
            for fileLine in ${filesToDelete[@]}; do
                local deletionPath=$(cut --complement -d' ' -f1,2,3 <<<$fileLine | sed 's,\s*\\\s*, ,g')
                echo ""
                echo "Are you sure you want to delete '$deletionPath'?"
                echo "Press 'y' to confirm, any other key press will abort."
                echo ""
                read -rsn1 deletionConfirmation
                case $deletionConfirmation in
                y)
                    rm -f $deletionPath
                    IFS=$'\r\n'
                    deletedPaths+=("$deletionPath")
                    IFS=
                    echo "Deleted '$deletionPath'"
                    ;;
                *)
                    echo "Deletion of '$deletionPath' aborted."
                    ;;
                esac
            done
            echo "Deleted all selected files that didn't have their deletion aborted."
            printf "%s\n" "${deletedPaths[@]}" >/home/"$USER"/hdguard_"$dateTime".deleted
            echo "Saved the list of deleted files in /home/"$USER"/hdguard_"$dateTime".deleted"
            delayWithDots 5
            break
            ;;
        abort)
            echo "File deletion aborted."
            break
            ;;
        *)
            if [[ "$selection" =~ $numberRegex ]]; then
                local isIndexPresent=false
                for fileLine in ${filesToDelete[@]}; do
                    if [ $(cut -d' ' -f2 <<<$fileLine) -eq "$selection" ]; then
                        isIndexPresent=true
                    fi
                done
                if [ "$isIndexPresent" == true ]; then
                    for fileLine in ${filesToDelete[@]}; do
                        if [ $(cut -d' ' -f2 <<<$fileLine) -eq "$selection" ]; then
                            selectedFile=$fileLine
                        fi
                    done
                    awk -v selection="$selection" '{ $1 = ($2 == selection ? 0 : $1) } 1' /tmp/hdguard-file-list >/tmp/hdguard-file-list.temp
                    rm -f /tmp/hdguard-file-list
                    cat /tmp/hdguard-file-list.temp >/tmp/hdguard-file-list
                    rm -f /tmp/hdguard-file-list.temp
                    echo "Removed '$(cut --complement -d' ' -f1,2,3 <<<$fileLine)' from selection."
                    delayWithDots 4
                else
                    echo "Selected nonexisting file index. Please select an existing file index."
                    delayWithDots 4
                fi
            else
                echo "Incorrect selection. Please select a valid file index by typing its index and pressing ENTER."
                delayWithDots 4
            fi
            ;;
        esac
    done

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
timeDelay=60

while true; do
    while true; do
        usagePercentage=$(getUsedSpacePercentage)
        clear
        showTitle
        if [ "$ignoreAllWarnings" = false ] && [ $(echo "$usagePercentage > $limit" | bc) -ne 0 ]; then
            break
        fi
        delayWithDots $timeDelay
    done
    limitReachedAction
done

exit 0
