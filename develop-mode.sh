#!/bin/bash
# this script is only valid for Drupal 10

man() {
    echo "enable: create services.yml, debug: true, auto_reload: true, cache: false, composer require devel, drush devel, composer require webpfrofiler, drush en webprofiller, drush cr."
    echo "disable: rm -rf services.yml, drush pmu webprofiler, composer remove drupal/webprofiler, composer remove drupal/devel, drush cr"
}

enable() {
    settings_file_path="web/sites/default/settings.php"
    if [[ ! -e "$settings_file_path" ]]; then
        vendor/bin/run toolkit:build-dev
    fi

    file_path="web/sites/default/services.yml"
    if [[ ! -e "$file_path"  ]]; then
        cp web/sites/default/default.services.yml web/sites/default/services.yml &&
        file="web/sites/default/services.yml"
        line_number=82
        new_line="    debug: true"   
        sed -i "${line_number}s/.*/${new_line}/" "$file"
        line_number=91
        new_line="    auto_reload: true"
        sed -i "${line_number}s/.*/${new_line}/" "$file"
        line_number=102
        new_line="    cache: false"
        sed -i "${line_number}s/.*/${new_line}/" "$file"
    fi
    
    echo "#######"
    echo "Devel"
    echo "#######"
    composer require 'drupal/devel:^5.0' &&

    echo "#############"
    echo "Webpfrofiler"
    echo "#############"
    composer require 'drupal/webprofiler:^10.1' &&
    drush en webprofiler
    chown www-data:www-data web/sites/default/files/profiler

    drush cr
}

disable() {
    echo "####################"
    echo "Delete services.yml"
    echo "####################"
    rm -rf web/sites/default/services.yml
    
    echo "################################"
    echo "Disable and remove Webpfrofiler"
    echo "################################"
    drush pmu webprofiler
    composer remove drupal/webprofiler

    echo "#######"
    echo "Devel"
    echo "#######"
    composer remove drupal/devel
    drush cr
}

# If no have any parameters show menu options.
if [ "$#" -eq 0 ]; then 
    
    current_folder=$(basename "$PWD")
    echo "##########################################################################"
    echo "Welcome to develop mode script for project: $current_folder"
    echo "##########################################################################"
    echo
    echo "Select an option:"
    echo
    echo "enable: twig_debug, twig_cache_disable, disable_rendered_output_cache_bins, drush en webprofiler, drush en devel"
    echo "disable: twig_debug, twig_cache_disable, disable_rendered_output_cache_bins, drush en webprofiler, drush en devel"

    # Get user input
    read -p "Enter the option number: " option

    # execute funcion
    $option

else
    #echo "We have any parameter"    
    case $1 in        
        enable)
            enable
            ;;
        disable)
            disable
            ;;
        man)
            man
            ;;
        *)
            man
            ;;
        
    esac
fi