#!/bin/bash

read -p "Which package do you wish to install? " VAR1

dpkg -s $VAR1 &> /dev/null
    
if ! [ $? -ne 0 ]
    then #Not installed
        echo "$VAR1 is already installed! Aborting!"
        exit        
fi

read -p "Install from source or with dpkg/rpm? " INSTALL_TYPE

read -p "Link to file download: " FILE_LINK

chmod -R 777 /usr/local/src

#wget "$FILE_LINK" -P /usr/local/src

if [[ "$INSTALL_TYPE" == "dpkg" ]]; then
    echo "dpkg selected"

    
    #dpkg -i /usr/local/src/$VAR1.deb
#else
#    echo "Package $VAR1 it issss"
fi