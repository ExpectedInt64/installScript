#!/bin/bash

echo ""
# Greeting
whiptail --msgbox "Welcome to package installer wizard!" 10 100

VAR1=$(whiptail --inputbox "Which package do you wish to install?" 10 100 3>&1 1>&2 2>&3)
echo "name: $VAR1"

#################### FUNCTION ####################
# Handles necessary packages to install from different installation types
packageExist(){

     if  [ "$1" == "bzip2" ] || [ "$1" == "tar" ] || [ "$1" == "gzip" ] || [ "$1" == "alien" ]
      then
        dpkg -s $1 &> /dev/null
        if [ $? -ne 0 ]; then
            echo "$1 is not installed! Aborting!"
            whiptail --msgbox "$1 is not installed! Aborting!" 10 100
            exit 2
        fi
    fi

    if [ "$1" == "checkinstall" ]; then
        dpkg -s $1 &> /dev/null
        if [ $? -eq 0 ]; then
            return 0
        else
            return 1
        fi
    fi

    if [ "$1" == "package_Check" ]; then
    dpkg -s "$VAR1" &> /dev/null
      if ! [ $? -ne 0 ] ;   # kontrol om exit status for den sidste kørte kommando
      then #Not installed
        echo "$VAR1 is already installed! Aborting!"
        whiptail --msgbox "$VAR1 is already installed! Aborting!" 10 100
        exit 2
     fi
    fi

}
#################### End ####################

packageExist "package_Check"

# User can choose different installation types from the selection
INSTALL_TYPE=$(whiptail --menu "Choose an option" 18 100 10 \
  "dpkg" "Install using dpkg" \
  "rpm" "Install using rpm (Requires Alien)" \
  "source" "Install from source" 3>&1 1>&2 2>&3)

if [ -z "$INSTALL_TYPE" ]; then
  echo "No option was chosen (user hit Cancel)"
  exit 2
else
  echo "The user choose $INSTALL_TYPE"
fi

echo ""

# User can type whatever link to a file to be downloaded
FILE_LINK=$(whiptail --inputbox "Link to file download!" 10 100 3>&1 1>&2 2>&3)

# Checking permissons at /usr/local/src and changes them to all access
PERMISSON=$(stat -c "%a" /usr/local/src)

if [ "$PERMISSON" -ne 775 ]; then

    chmod -R 775 /usr/local/src 2> error2.log

fi

cd /usr/local/src
touch error.log

# Clone repo if it is a git link
echo "$FILE_LINK" | grep "git$"
if [ $? -eq 0 ]; then
    git clone $FILE_LINK 2>> /usr/local/src/error.log
    cd /usr/local/src/$(ls -c | head -n1)
    autoreconf -i
else
    wget "$FILE_LINK"
fi

#Last file modified in the directory
FILE=$(ls -c | head -n1)
chmod -R 775 /usr/local/src 2>> /usr/local/src/error.log

# Installation type Source
if [[ "$INSTALL_TYPE" == "source" ]]; then
    echo "$INSTALL_TYPE selected"
    packageExist "tar"

    if [[ "$FILE" == *.bz2 ]]; then
        packageExist "bzip2"
        bzip2 -cd /usr/local/src/$FILE | tar xvf -
        cd /usr/local/src/$(ls -c | head -n1)
    elif [[ "$FILE" == *.gz ]]; then
        packageExist "gzip"
        gzip -cd /usr/local/src/$FILE | tar xvf -
        cd /usr/local/src/$(ls -c | head -n1)
    fi
    ./configure
    make
    packageExist "checkinstall" && checkinstall || make install 2>> /usr/local/src/error.log
    whiptail --msgbox "Installation success exiting! Please look at error.log at /usr/local/src/error.log" 10 100
    echo "Installation success" >> /usr/local/src/error.log
    chmod -R 775 /usr/local/src
    exit 0
fi

# Installation type RPM
if [[ "$INSTALL_TYPE" == "rpm" ]]; then
  packageExist "alien"
  echo "Converting .rpm file"
  alien /usr/local/src/"$FILE"
  dpkg -i "$(ls -c | head -n1)" 2>> /usr/local/src/error.log
  if [ $? -ne 0 ]; then
        echo "Installation failed" >> /usr/local/src/error.log
        whiptail --msgbox "Installation failed!" 10 100
        chmod -R 775 /usr/local/src
        exit 2

        else
        echo "Installation success exiting" >> /usr/local/src/error.log
        whiptail --msgbox "Installation success exiting!" 10 100
        chmod -R 775 /usr/local/src
        exit 0
  fi
fi

# Installation type DPKG
if [[ "$INSTALL_TYPE" == "dpkg" ]]; then
    echo "$INSTALL_TYPE selected"
    dpkg -i "$FILE" 2> error.log

    if [ $? -ne 0 ]; then
      echo "These dependencies missing:"
    cat error.log | egrep -o "'[a-z0-9.-]+'" | tr -d \'

        dpkgtype=$(whiptail --menu "Choose an option" 18 120 10 \
        "missing" "Download and install only missing dependencies (Fails if there is recursive dependency missing)" \
        "all" "Download and install all dependencies recursivly" 3>&1 1>&2 2>&3)

        if [ "$dpkgtype" = "missing" ]; then
          cat error.log | egrep -o "'[a-z0-9.-]+'" | tr -d \' > dependencies
          whiptail --title "Package needs these dependencies (Scroll for more dependencies):" --textbox dependencies 30 100 --scrolltext
          apt download $(cat dependencies) 2>> /usr/local/src/error.log
          dpkg -i *.deb 2>> /usr/local/src/error.log

     elif [ "$dpkgtype" = "all" ]; then
# Recursive all dependencies
# https://stackoverflow.com/questions/22008193/how-to-list-download-the-recursive-dependencies-of-a-debian-package
 apt-cache depends --recurse --no-recommends --no-suggests --no-conflicts --no-breaks --no-replaces --no-enhances "$VAR1" | grep "^\w" | grep -v 386 > dependencies
        # echo "Package needs these dependencies:"
        whiptail --title "Package needs these dependencies (Scroll for more dependencies):" --textbox dependencies 30 100 --scrolltext
        # cat dependencies

        apt download $(cat dependencies) 2>> /usr/local/src/error.log
        dpkg -i *.deb 2>> /usr/local/src/error.log

          else
            echo "Dependencies missing" >> /usr/local/src/error.log
            exit 2
        fi
    fi

    dpkg -i "$FILE"
fi
    if [ $? -ne 0 ]; then
        echo "Installation failed" >> /usr/local/src/error.log
        folder=$(date -u +"%Y-%m-%dT%H_%M_%S")
        mkdir "$folder"
        mv *.deb "$folder/"
        whiptail --msgbox "Installation failed! Dependencies have been moved to /usr/local/src/$folder If there is any broken packages fix it with: (apt --fix-broken install). " 10 100
        chmod -R 775 /usr/local/src
        exit 2
        else
          echo "Installation success exiting" >> /usr/local/src/error.log
          folder=$(date -u +"%Y-%m-%dT%H_%M_%S")
          mkdir "$folder"
          mv *.deb "$folder/"
          echo "Installation success" >> /usr/local/src/error.log
          whiptail --msgbox "Installation success exiting! Please look at error.log at /usr/local/src/error.log If there is any broken packages fix it with: (apt --fix-broken install). All necessary packages can be found at /usr/local/src/$folder" 10 100
          chmod -R 775 /usr/local/src
          exit 0
    fi

    # https://devhints.io/bash
    # https://gijs-de-jong.nl/posts/pretty-dialog-boxes-for-your-shell-scripts-using-whiptail/