#!/bin/bash

echo "Welcome to package installer wizard!"

read -p "Which package do you wish to install? " VAR1

dpkg -s $VAR1 &> /dev/null
    
if ! [ $? -ne 0 ]  # kontrol om exit status for den sidste kørte kommando
    then #Not installed
        echo "$VAR1 is already installed! Aborting!"
        exit        
fi

read -p "Install from source or with dpkg/rpm?  d:Dpkg or s:Source " INSTALL_TYPE

read -p "Link to file download: " FILE_LINK


PERMISSON=$(stat -c "%a" /usr/local/src)

if [ "$PERMISSON" -ne 777 ]; then

    chmod -R 777 /usr/local/src

fi

cd /usr/local/src

wget "$FILE_LINK"
FILE=$(ls -c | head -n1)

if [[ "$INSTALL_TYPE" == "d" ]]; then
    echo "dpkg selected"
    dpkg -i "$FILE" 2> error.log

    if [ $? -ne 0 ]; then
        cat error.log | egrep -o "'[a-z0-9-]+'" > dependencies
         for line in $(cat dependencies); do
          echo "Dependencies missing please install: $line"

          read FILE_LINK_DEPENDENCY

          wget "$FILE_LINK_DEPENDENCY"
          FILE_DEPENDENCY=$(ls -c | head -n1)
          dpkg -i "$FILE_DEPENDENCY"
          done
    fi

    dpkg -i "$FILE"
#else
#    echo "Package $VAR1 it issss"
fi