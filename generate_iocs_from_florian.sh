#!/bin/bash 

# Download IOCs from Florian Roth github pages

# Constants
HASH_FILE="hash-iocs.txt"
HASH_URL="https://raw.githubusercontent.com/Neo23x0/signature-base/master/iocs/$HASH_FILE" 
FILENAME_FILE="filename-iocs.txt"
FILENAME_URL="https://raw.githubusercontent.com/Neo23x0/signature-base/master/iocs/$FILENAME_FILE"

DIRECTORY_OUTPUT="output/"
HASH_OUTPUT="${DIRECTORY_OUTPUT}hash_iocs.txt"
FILENAME_OUTPUT="${DIRECTORY_OUTPUT}filename_iocs.txt"
QUERY_OUTPUT="${DIRECTORY_OUTPUT}filename_kql.txt"

WORKING_DIR=$(pwd)

SCRIPT_NAME=${0}
README_FILE="README.md"

TARGET_GITHUB=$1

REGEX_PART_NAME="Regex_Part"

# Functions

#
# Remove files and folders from previous execution
#
function clean () {
    echo "=> Delete previously downloaded files"
    rm -rf $HASH_FILE $FILENAME_FILE
    echo "=> Delete output folder"
    rm -rf $DIRECTORY_OUTPUT
    echo "==> Project cleaning succesful"
}

#
# Create output folder
#
function prepare_output () {
    echo "=> Create output folder"
    mkdir $DIRECTORY_OUTPUT
    echo "==> Output folder creation succesful"
}

#
# Download file from $1
#
function download_from_url () {
    echo "=> Download Hash URL from $1"
    if wget -q $1; 
    then
        echo "==> Download successful"
    else
        echo "!!! Issue when downloading $1"
        exit 1
    fi
}

#
# Parse key;value file
# Remove empty lines
# Remove comments
# $1 : input file
# $2 : output file
#
function parse_file () {
    echo "=> Parse IOCs from $1 file"
    while IFS=';' read -r KEY VALUE
    do
        if [[ ! -z "$KEY" ]]  && [[ ! $KEY =~ ^\#.* ]]; then
            echo "$KEY" >> $2
        fi
    done < $1
    echo "==> Parsing Succesful"
}

#
# Create KQL file queries for filename regexes
#
function generate_kql_for_file_iocs () {
    echo "=> Generate KQL queries for File regexes"
    split -l 1000 -d $FILENAME_OUTPUT "Regex_Part"
    local CPT_FILE=0
    local ENTRY=""
    for FILE in $REGEX_PART_NAME*;
    do
        echo "=> Generate KQL queries for part $FILE"
        echo -ne "DeviceFileEvents\n| where ActionType == \"FileCreated\"\n| where " >> $QUERY_OUTPUT.$CPT_FILE
        local CPT=0
        while IFS=';' read -r KEY VALUE
        do
            local UPDATED_KEY=$(echo $KEY | sed 's/\\/\\\\\\\\/g')
            if [[ $CPT == 0 ]]; then
                ENTRY="FolderPath matches regex" 
                let "CPT+=1"
            else
                ENTRY="\tor FolderPath matches regex"
            fi
            printf "$ENTRY \"$UPDATED_KEY\"\n" >> $QUERY_OUTPUT.$CPT_FILE
        done < $FILE
        let "CPT_FILE+=1"
        rm $FILE
    done
    echo "==> Generation succesful" 
}

# Execution

clean

download_from_url $HASH_URL
download_from_url $FILENAME_URL

prepare_output

parse_file $HASH_FILE $HASH_OUTPUT
parse_file $FILENAME_FILE $FILENAME_OUTPUT

generate_kql_for_file_iocs

# Copy current script and readme to output folde prior Github push
cp $SCRIPT_NAME $DIRECTORY_OUTPUT
cp $README_FILE $DIRECTORY_OUTPUT

# push to git 
cd $DIRECTORY_OUTPUT
git init
git remote add origin $TARGET_GITHUB
git add -A
git commit -m "Script launched on $(date)"
git push origin master -f