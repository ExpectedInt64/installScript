#!/bin/bash

echo "Welcome to package installer wizard!"

read -p "Which package do you wish to install? " VAR1

dpkg -s $VAR1 &> /dev/null
    
if ! [ $? -ne 0 ]  # kontrol om exit status for den sidste kørte kommando
    then #Not installed
        echo "$VAR1 is already installed! Aborting!"
        exit 2
fi

read -p "Install from source or with dpkg/rpm?  d:Dpkg or s:Source " INSTALL_TYPE

read -p "Link to file download: " FILE_LINK


PERMISSON=$(stat -c "%a" /usr/local/src)

if [ "$PERMISSON" -ne 777 ]; then

    chmod -R 777 /usr/local/src 2 > error2.log

fi

cd /usr/local/src

wget "$FILE_LINK"
FILE=$(ls -c | head -n1)

if [[ "$INSTALL_TYPE" == "d" ]]; then
    echo "dpkg selected"
    dpkg -i "$FILE" 2> error.log

    if [ $? -ne 0 ]; then
        cat error.log | egrep -o "'[a-z0-9.-]+'" | tr -d \' > dependencies
#Alternative recursive alle dependencies
# https://stackoverflow.com/questions/22008193/how-to-list-download-the-recursive-dependencies-of-a-debian-package
# apt-cache depends --recurse --no-recommends --no-suggests --no-conflicts --no-breaks --no-replaces --no-enhances <your-package-here> | grep "^\w" | sort -u > dependencies
#
        echo "Package needs these dependencies:"
        cat dependencies
        read -p "Please choose how to handle dependencies: a:APT-CACHE download or e:exit " VAR2

        if [[ "$VAR2" == "a" ]]; then

          while read line; do
              echo "Installing dependency: $line"
              apt download "$line"
              FILE_DEPENDENCY=$(ls -c | head -n1)
              echo $FILE_DEPENDENCY
              dpkg -i $FILE_DEPENDENCY
          done < dependencies

#             for line in $(cat dependencies | tr -d \'); do
#          echo "Installing dependency: $line"
#
#          apt download "$line"
#
#          FILE_DEPENDENCY=$(ls -c | head -n1)
#
#         dpkg -i $FILE_DEPENDENCY
#
#          done

          else
            echo "Dependencies missing"
            exit 2
        fi
    fi

    dpkg -i "$FILE"

    if [ $? -ne 0 ]; then
        echo "Installation failed"
        exit 2
        else
          echo "Installation success exiting"
          exit 0
    fi


#else
#    echo "Package $VAR1 it issss"

# TODO mangler kontrol for rpm / alien
# TODO mangler installation fra source


fi