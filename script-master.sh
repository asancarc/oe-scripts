#!/bin/bash
# this script is only valid for European Comision projects

show_menu() {
    current_folder=$(basename "$PWD")
    echo "##########################################################################"
    echo "Welcome to script-master execution script for project: $current_folder"
    echo "##########################################################################"
    echo
    echo "Select an option:"
    echo
    echo "1. TOOLKIT - Install clean (composer install, build-dev, install-clean, drush uli)"
    echo "2. BEHAT - Execute all tests (composer install, build-dev, install-clean, behat --profile=clean --strict)"
    echo "3. BEHAT - List all steps available (include result in new file called behat-steps.txt)."
    echo "4. BEHAT - Execute one feature alone (behat tests/features/<feature-name.feature> --profile=clean, without install-clean)"
    echo "5. BEHAT - Execute only one scenario (select feature file, inclue line of scenario, without install-clean)"
    echo "6. Clear SOLR core information (outside from docker web bash)"
    echo "7. TOOLKIT - Execute LOCAL DRONE"
    echo "8. Load dump (sql-drop -y, load dump, composer install, drush cim -y, drush updb, drush uli)"
    echo "9. DRUPAL CONTRIB MODULES - Check updates available."
    echo "10. DRUPAL CONTRIB MODULES - Update drupal core, core-composer-scaffold and core-dev automatically."
    echo "11. COMPOSER - Update composer.lock file."
    echo "12. COMPOSER - Validate composer.lock file."
    echo "13. GIT - Show information (It depends from your configuration)."
    echo "14. TOOLKIT - Update toolkit."
    echo "15. DRUSH GENERATE - generate new custom module."
    echo "16. MSQL - Open terminal."
    echo "17. Restore vendor folder (remove vendor folder, composer install)"
    echo "18. Exit"
    echo
    echo "(In all executions from drush and toolkit, this script at finally disable monolog module, because if the site doesn't have any home page, uli doesn't work properly)"
    echo
}

action1() {
    echo "Performing Install clean"
    composer install
    vendor/bin/run toolkit:build-dev
    vendor/bin/run toolkit:install-clean
    drush pmu monolog
    drush uli
}

action2() {
    echo "Execute BEHAT tests"
    red=`tput setaf 1`
    reset=`tput sgr0`

    read -p "Be carefull, if you press enter button, start this process, but ${red}First of all execute install-clean command${reset}" var
    if [ ${#var} -eq 0 ]; then
    composer install
    vendor/bin/run toolkit:build-dev
    vendor/bin/run toolkit:install-clean
    vendor/bin/behat --profile=clean --strict
    fi
}

action3() {
    vendor/bin/behat -dl | tee behat-steps.txt
}

action4() {
    folder="tests/features"
    find "$folder" -type f -name "*.feature"
    echo "Input the path of file to show all available BEHAT scenarios, please, copy/paste all path"
    read alonetest
    echo "#################################"
    echo "Executing tests: $alonetest"
    echo "#################################"
    vendor/bin/behat $alonetest --profile=clean
}

action5() {
    folder="tests/features"
    find "$folder" -type f -name "*.feature"
    echo "Input the path of file to show all available BEHAT scenarios, please, copy/paste all path"
    read file

    matches=$(grep -n "^[[:space:]]*\(Scenario\|Scenario Outline\):" "$file")

    if [ -n "$matches" ]; then
        echo "Lines beginning with 'Scenario:' found in the file $file"

        echo "$matches"
    else
        echo "No lines starting with 'Scenario:' found in the file $file"
    fi

    echo "What Scenario you like to execute? Please insert the correct number"
    read scenario

    line_content=$(sed -n "${scenario}p" "$file")

    echo "#################################"
    echo "Executing BEAHT feature from: $file"
    echo $line_content
    echo "#################################"
    vendor/bin/behat $file:$scenario --profile=clean
}

action6() {
    echo "Performing Clear SOLR core information"
    red=`tput setaf 1`
    reset=`tput sgr0`

    echo "Please enter the name of the  ${red}core you want to clean${reset} from data"
    read core

    curl http://localhost:8983/solr/$core/update?commit=true -H "Content-Type: application/xml" --data-binary '<delete><query>*:*</query></delete>'
}

action7() {
    red=`tput setaf 1`
    reset=`tput sgr0`

    echo -e "\n"
    echo "###############################################"
    echo "This proccess only simulate DRONE of OpenEuropa"
    echo "###############################################"
    echo "Adri warns: please, set QA_API_AUTH_TOKEN variable with your QA User Authentication Token for work correctly"
    echo "[press any button please]"
    echo -e "\n"
    read -n 1 -s

    qa_api_auth_token_env=$(printenv QA_API_AUTH_TOKEN)
    echo "Your QA_API_AUTH_TOKEN from system is:  $qa_api_auth_token_env"

    qa_api_auth_token_env_fileproject=$(grep "QA_API_AUTH_TOKEN=" .env | awk -F "=" '{print $2}' | tr -d '"')
    echo "Your QA_API_AUTH_TOKEN from .env file is:  $qa_api_auth_token_env_fileproject"

    if [ "$qa_api_auth_token_env" = "$qa_api_auth_token_env_fileproject" ]; then
        echo "The variables are equal."
    else
        echo "The variables are not equal."
        echo "To get token, go to https://webgate.ec.europa.eu/fpfis/qa/user/ and create token"
        echo "After this, create next variable in .env file QA_API_AUTH_TOKEN={include here token}, restart docker."
        echo "Be carefull to not include in the repo this variable"
        echo "Please do this steps and restart script-master bash script to do this process."
        exit
    fi

    vendor/bin/run toolkit:build-dev

    composer install

    echo "###  -- Check if ${red}'composer.lock'${reset} exists on the project root folder. -- ###"
    vendor/bin/run toolkit:complock-check
    echo -e "\n"

    echo "### -- Check the ${red}Toolkit version${reset} -- ###"
    vendor/bin/run toolkit:check-version
    echo -e "\n"

    echo "### -- Check ${red}Toolkit requirements${reset} -- ###"
    vendor/bin/run toolkit:requirements --endpoint=https://digit-dqa.fpfis.tech.ec.europa.eu
    echo -e "\n"

    echo "### -- Start with ${red}toolkit:component-check${reset} process -- ###"
    vendor/bin/run toolkit:component-check
    echo -e "\n"
    echo "Everything went well? shall we continue?"
    read -n 1 -s

    echo "### -- Check ${red}'Vendor'${reset} packages being monitored. -- ###"
    vendor/bin/run toolkit:vendor-list
    echo -e "\n"

    echo "#############################"
    echo "Execute all the testing tools"
    echo "#############################"

    echo "### -- Testing ${red}phpcs${reset} -- ###"
    vendor/bin/run toolkit:test-phpcs || errors=$((errors+$?))
    echo "Everything went well? shall we continue?"
    read -n 1 -s

    echo "### -- Testing ${red}phpmd${reset} -- ###"
    vendor/bin/run toolkit:test-phpmd || errors=$((errors+$?))
    echo "Everything went well? shall we continue?"
    read -n 1 -s

    echo "### -- Testing ${red}opts-review${reset} -- ###"
    vendor/bin/run toolkit:opts-review

    echo "### -- Testing ${red}lint-php${reset} -- ###"
    vendor/bin/run toolkit:lint-php

    echo "### -- Testing ${red}lint-yaml${reset} -- ###"
    vendor/bin/run toolkit:lint-yaml

    # this step fail in 9.9.4
    echo "${red}phpstan${reset}"
    vendor/bin/run toolkit:test-phpstan

    echo "##############################"
    echo "FINISHED all the testing tools"
    echo "##############################"
    echo -e "\n"

    # Experimental Run script to fix permissions (experimental)
    # vendor/bin/run toolkit:fix-permissions drupal_path drupal_user httpd_group

    echo "Everything went well? shall we continue?"
    read -n 1 -s

    blink_text() {
    local text="$1"
    local delay="$2"
    local end_time=$((SECONDS + 5))

    while [ $SECONDS -lt $end_time ]; do
        printf "\e[5m%s\e[0m" "$text"
        sleep "$delay"
        clear
        sleep "$delay"
    done
    }
    blink_text "${red}BE CAREFULL FROM HERE PLEASE${reset}" 0.5


    echo "###############################"
    echo "Start with behat tests proccess"
    echo "###############################"
    read -p "BE CAREFULL, if you press enter button, start this process, but ${red}First of all execute install-clean command${reset}" var
    if [ ${#var} -eq 0 ]; then
        composer install &&
        vendor/bin/run toolkit:build-dev &&
        vendor/bin/run toolkit:install-clean &&
        vendor/bin/behat --profile=clean --strict
    fi
}

action8() {
    actual_directory="$(dirname "$0")"
    ls -p "$actual_directory" | grep -E ".*\.sql$"
    echo "Enter the name of the file:"
    read dbdump
    drush sql-drop -y
    drush sqlc < $dbdump
    composer install
    drush cim -y
    drush updb -y
    drush pmu monolog autologout
    drush uli
}

action9() {
    composer outdated "drupal/*"
}

action10() {
    composer outdated "drupal/*" &&
    composer update drupal/core drupal/core-composer-scaffold drupal/core-dev  --with-all-dependencies &&
    drush updb &&
    drush cr
}

action11() {
    composer update --lock
}

action12() {
    composer validate
}

action13() {
    git config user.name
    git config user.email
    git remote -v
    git branch --show-current
}

action14() {
    composer update ec-europa/toolkit --with-all-dependencies
}

action15() {
    drush generate module
}

action16() {
    drush sql:cli
}

action17() {
    rm -rf vendor
    composer install
}

# Main script loop
while true; do
    show_menu

    # Get user input
    read -p "Enter the option number: " option
    echo

    # Evaluate the selected option
    case $option in
        1)
            action1
            ;;
        2)
            action2
            ;;
        3)
            action3
            ;;
        4)
            action4
            ;;
        5)
            action5
            ;;
        6)
            action6
            ;;
        7)
            action7
            ;;
        8)
            action8
            ;;
        9)
            action9
            ;;
        10)
            action10
            ;;
        11)
            action11
            ;;
        12)
            action12
            ;;
        13)
            action13
            ;;
        14)
            action14
            ;;
        15)
            action15
            ;;
        16)
            action16
            ;;
        17)
            action17
            ;;
        18)
            echo "Exiting the program"
            break
            ;;

        *)
            echo "Invalid option"
            ;;
    esac

    echo
done
