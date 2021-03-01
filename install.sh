#!/bin/bash

echo "Welcome to package installer wizard!"

read -p "Which package do you wish to install? " VAR1

dpkg -s $VAR1 &> /dev/null
    
if ! [ $? -ne 0 ]  # kontrol om exit status for den sidste kørte kommando
    then #Not installed
        echo "$VAR1 is already installed! Aborting!"
        exit2
fi

read -p "Install from source or with dpkg/rpm?  d:Dpkg or s:Source " INSTALL_TYPE

read -p "Link to file download: " FILE_LINK


PERMISSON=$(stat -c "%a" /usr/local/src)

if [ "$PERMISSON" -ne 777 ]; then

    chmod -R 777 /usr/local/src 2> error2.log

fi

cd /usr/local/src

wget "$FILE_LINK"
FILE=$(ls -c | head -n1)

if [[ "$INSTALL_TYPE" == "d" ]]; then
    echo "dpkg selected"
    dpkg -i "$FILE" 2> error.log

    if [ $? -ne 0 ]; then
        cat error.log | egrep -o "'[a-z0-9-]+'" > dependencies

        echo "Package needs these dependencies:"
        cat dependencies | tr -d \'
        read -p "Please choose how to handle dependencies: a:APT-CACHE download or e:exit " VAR2

        if [[ "$VAR2" == "a" ]]; then
             for line in $(cat dependencies | tr -d \'); do
          echo "Installing dependency: $line"

          apt download $line

          FILE_DEPENDENCY=$(ls -c | head -n1)
          tar -xf $FILE_DEPENDENCY

          cd $FILE_DEPENDENCY

          for debfile in $(ls *.deb); do

            dpkg -i $debfile

            done

          done

          else
            exit2
        fi
    fi

    dpkg -i "$FILE"
#else
#    echo "Package $VAR1 it issss"

# TODO mangler kontrol for rpm / alien
# TODO mangler installation fra source


fi