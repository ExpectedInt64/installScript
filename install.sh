#!/bin/bash

echo ""
echo "Welcome to package installer wizard!"
whiptail --msgbox "Welcome to package installer wizard!" 10 100

# read -p "Which package do you wish to install? " VAR1

VAR1=$(whiptail --inputbox "Which package do you wish to install?" 10 100 3>&1 1>&2 2>&3)
echo "name: $VAR1"

#################### FUNCTIONS ####################
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

# read -p "Install from source or with dpkg/rpm?  d:Dpkg or s:Source " INSTALL_TYPE

INSTALL_TYPE=$(whiptail --menu "Choose an option" 18 100 10 \
  "dpkg" "Install using dpkg" \
  "rpm" "Install using rpm (Requires Alien)" \
  "source" "Install from source" 3>&1 1>&2 2>&3)

if [ -z "$INSTALL_TYPE" ]; then
  echo "No option was chosen (user hit Cancel)"
  exit 2
else
  echo "The user chose $INSTALL_TYPE"
fi

echo ""

# read -p "Link to file download: " FILE_LINK
FILE_LINK=$(whiptail --inputbox "Link to file download!" 10 100 3>&1 1>&2 2>&3)

PERMISSON=$(stat -c "%a" /usr/local/src)

if [ "$PERMISSON" -ne 777 ]; then

    chmod -R 777 /usr/local/src 2 > error2.log

fi

cd /usr/local/src

echo "$FILE_LINK" | grep "git$"

if [ $? -eq 0 ]; then
    git clone $FILE_LINK
    cd /usr/local/src/$(ls -c | head -n1)
    autoreconf -i
else
    wget "$FILE_LINK"
#    chmod -R 777 /usr/local/src 2 > error2.log
fi

FILE=$(ls -c | head -n1)

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

   packageExist "checkinstall" && checkinstall || make install

fi

# rpm
if [[ "$INSTALL_TYPE" == "rpm" ]]; then
  packageExist "alien"
  echo "Converting .rpm file"
  alien /usr/local/src/"$FILE"
  dpkg -i "$(ls -c | head -n1)"
  if [ $? -ne 0 ]; then
        echo "Installation failed"
        whiptail --msgbox "Installation failed!" 10 100

        exit 2
        else
        echo "Installation success exiting"
        whiptail --msgbox "Installation success exiting!" 10 100
        exit 0
  fi
fi

# dpkg
if [[ "$INSTALL_TYPE" == "dpkg" ]]; then
    echo "$INSTALL_TYPE selected"
    dpkg -i "$FILE" 2> error.log

    if [ $? -ne 0 ]; then
      echo "These dependencies missing:"
    cat error.log | egrep -o "'[a-z0-9.-]+'" | tr -d \'

        dpkgtype=$(whiptail --menu "Choose an option" 18 120 10 \
        "missing" "Download and install only missing dependencies (Fails if there is recursive dependency missing)" \
        "all" "Download and install all dependencies recursivly" 3>&1 1>&2 2>&3)

        # read -p "Download and install all dependencies (r)ecursivly, Download and install only (m)issing dependencies (Fails if there is recursive dependency missing) or (e)xit " dpkgtype
        if [ "$dpkgtype" = "missing" ]; then
          cat error.log | egrep -o "'[a-z0-9.-]+'" | tr -d \' > dependencies

          apt download $(cat dependencies) 2>> error.log
          dpkg -i *.deb 2>> error.log

     elif [ "$dpkgtype" = "all" ]; then
#Alternative recursive alle dependencies
# https://stackoverflow.com/questions/22008193/how-to-list-download-the-recursive-dependencies-of-a-debian-package
 apt-cache depends --recurse --no-recommends --no-suggests --no-conflicts --no-breaks --no-replaces --no-enhances "$VAR1" | grep "^\w" | grep -v 386 > dependencies
        # echo "Package needs these dependencies:"
        whiptail --title "Package needs these dependencies (Scroll for more dependencies):" --textbox dependencies 30 100 --scrolltext
        # cat dependencies

        apt download $(cat dependencies) 2>> error.log
        dpkg -i *.deb 2>> error.log

          else
            echo "Dependencies missing"
            exit 2
        fi
    fi

    dpkg -i "$FILE"
fi
    if [ $? -ne 0 ]; then
        echo "Installation failed"
        whiptail --msgbox "Installation failed!" 10 100

        exit 2
        else
          echo "Installation success exiting"
          folder=$(date -u +"%Y-%m-%dT%H_%M_%S")
          mkdir "$folder"
          mv *.deb "$folder/"
          echo "Installation success" >> error.log


          whiptail --msgbox "Installation success exiting! Please look at error.log at /usr/local/src/error.log If there is any broken packages fix it with: (apt --fix-broken install). All necessary packages can be found at /usr/local/src/$folder" 10 100
          exit 0
    fi

    # https://devhints.io/bash
    # whiptail link here