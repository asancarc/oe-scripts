#!/bin/bash
# this script is only valid for European Comision projects

# function to show options
man() {
    echo "If you don't send any parameter, script show default menu."
    echo "Options you can use as parameter:"
    echo "install_clean -> composer install, build-dev, install-clean, drush uli"
}

# Declare functions
install_clean() {
    echo "Performing Install clean"
    composer install
    vendor/bin/run toolkit:build-dev
    vendor/bin/run toolkit:install-clean
    drush uli
}

# If no have any parameters show menu options.
if [ "$#" -eq 0 ]; then 
    
    current_folder=$(basename "$PWD")
    echo "##########################################################################"
    echo "Welcome to script-master execution script for project: $current_folder"
    echo "##########################################################################"
    echo
    echo "Select an option:"
    echo
    echo "install_clean. TOOLKIT - (composer install, build-dev, install-clean, drush uli)"

    # Get user input
    read -p "Enter the option number: " option

    # execute funcion
    $option

else
    #echo "Se han pasado parámetros al script."    
    case $1 in
        "man")
            man
            ;;
        "install_clean")
            install_clean
            ;;
        
    esac

    echo
fi


