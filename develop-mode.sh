#!/bin/bash
# this script is only valid for Drupal 10

man() {
    echo "enable: debug: true, auto_reload: true, cache: false, composer require webpfrofiler, drush en webprofiller, agregation CSS/JS FALSE, drush cr"
    echo "disable: debug: false, auto_reload: null, cache: true, drush cr, drush pmu webprofiler, composer remove drupal/webprofiler, agregation CSS/JJS TRUE, drush cr"
}

enable() {
    settings_file_path="web/sites/default/settings.php"
    if [[ ! -e "$settings_file_path" ]]; then
        vendor/bin/run toolkit:build-dev
    fi

    echo "##################"
    echo "Enable twig debug"
    echo "##################"
    drush state:set twig_debug 1 --input-format=integer && \
    drush state:set twig_cache_disable 1 --input-format=integer && \
    drush state:set disable_rendered_output_cache_bins 1 --input-format=integer && \
    drush cr     

    echo "#############"
    echo "Webpfrofiler"
    echo "#############"
    composer require 'drupal/webprofiler:^10.1'
    drush en webprofiler -y
    chown www-data:www-data web/sites/default/files/profiler

    echo "##########################"
    echo "Disable CSS/JS agregation"
    echo "##########################"
    drush -y config:set system.performance css.preprocess 0
    drush -y config:set system.performance js.preprocess 0

    drush cr
}

disable() {
    echo "###################"
    echo "Disable twig debug"
    echo "###################"
    drush state:set twig_debug 0 --input-format=integer && \
    drush state:set twig_cache_disable 0 --input-format=integer && \
    drush state:set disable_rendered_output_cache_bins 0 --input-format=integer && \
    drush cr
    
    echo "################################"
    echo "Disable and remove Webpfrofiler"
    echo "################################"
    drush pmu webprofiler -y
    composer remove drupal/webprofiler

    drush cr

    echo "##########################"
    echo "Enable CSS/JS agregation"
    echo "##########################"
    drush -y config:set system.performance css.preprocess 1
    drush -y config:set system.performance js.preprocess 1
    
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
    echo "enable: debug: true, auto_reload: true, cache: false, composer require webpfrofiler, drush en webprofiller, agregation CSS/JS FALSE, drush cr"
    echo "disable: debug: false, auto_reload: null, cache: true, drush cr, drush pmu webprofiler, composer remove drupal/webprofiler, agregation CSS/JJS TRUE, drush cr"

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