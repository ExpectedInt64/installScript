#!/bin/bash
echo ""
echo "Welcome to package installer wizard!"
whiptail --msgbox "Welcome to package installer wizard!" 10 100

# read -p "Which package do you wish to install? " VAR1

VAR1=$(whiptail --inputbox "Which package do you wish to install?" 10 100 3>&1 1>&2 2>&3)
VAR2="b"
echo "name: $VAR1"
dpkg -s $VAR1 &> /dev/null
    
if ! [ $? -ne 0 ]  # kontrol om exit status for den sidste kørte kommando
    then #Not installed
        echo "$VAR1 is already installed! Aborting!"
        whiptail --msgbox "$VAR1 is already installed! Aborting!" 10 100
        exit 2
fi

# read -p "Install from source or with dpkg/rpm?  d:Dpkg or s:Source " INSTALL_TYPE

INSTALL_TYPE=$(whiptail --menu "Choose an option" 18 100 10 \
  "dpkg" "A description for the tiny option." \
  "rpm" "A description for the small option." \
  "source" "A description for the medium option." 3>&1 1>&2 2>&3)

if [ -z "$INSTALL_TYPE" ]; then
  echo "No option was chosen (user hit Cancel)"
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

wget "$FILE_LINK"
FILE=$(ls -c | head -n1)

if [[ "$INSTALL_TYPE" == "dpkg" ]]; then
    echo "dpkg selected"
    dpkg -i "$FILE" 2> error.log

    if [ $? -ne 0 ]; then
      echo "These dependencies missing:"
    cat error.log | egrep -o "'[a-z0-9.-]+'" | tr -d \'

      read -p "Download and install all dependencies (r)ecursivly, Download and install only (m)issing dependencies (Fails if there is recursive dependency missing) or (e)xit " dpkgtype
        if [ "$dpkgtype" = "m" ]; then
          cat error.log | egrep -o "'[a-z0-9.-]+'" | tr -d \' > dependencies
          for line in $(cat dependencies | tr -d \'); do
          echo "Installing dependency: $line"
          apt download "$line"
          FILE_DEPENDENCY=$(ls -c | head -n1)
          dpkg -i $FILE_DEPENDENCY
          done

     elif [ "$dpkgtype" = "r" ]; then
#Alternative recursive alle dependencies
# https://stackoverflow.com/questions/22008193/how-to-list-download-the-recursive-dependencies-of-a-debian-package
 apt-cache depends --recurse --no-recommends --no-suggests --no-conflicts --no-breaks --no-replaces --no-enhances "$VAR1" | grep "^\w" | grep -v 386 > dependencies
        echo "Package needs these dependencies:"
        whiptail --title "Package needs these dependencies (Scroll for more dependencies):" --textbox dependencies 30 100 --scrolltext
        cat dependencies

       cat dependencies | grep "^lib" | while read line; do
              echo "Installing dependency: $line"
              apt download "$line"
              FILE_DEPENDENCY=$(ls -c | head -n1)
              echo $FILE_DEPENDENCY
              dpkg -i $FILE_DEPENDENCY 2>> error.log
          done

        cat dependencies | grep -v "^lib" |  while read line; do
              echo "Installing dependency: $line"
              apt download "$line"
              FILE_DEPENDENCY=$(ls -c | head -n1)
              echo $FILE_DEPENDENCY
              dpkg -i $FILE_DEPENDENCY 2>> error.log
          done


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
          whiptail --msgbox "Installation success exiting!" 10 100
          exit 0
    fi


#else
#    echo "Package $VAR1 it issss"

# TODO mangler kontrol for rpm / alien
# TODO mangler installation fra source