#!/bin/bash

sudo apt-get install jq

# Determine if all platforms should be built based on changes in projects, generic drivers, or CI workflow files
PROJECTS=$(echo "$CHANGED_FILES" | jq -r ".projects")
GENERIC=$(echo "$CHANGED_FILES" | jq -r ".generic_drivers")
CI_WORKFLOWS=$(echo "$CHANGED_FILES" | jq -r ".ci_workflows")
MAXIM=$(echo "$CHANGED_FILES" | jq -r ".platform_maxim")
PICO=$(echo "$CHANGED_FILES" | jq -r ".platform_pico")
MBED=$(echo "$CHANGED_FILES" | jq -r ".platform_mbed")
STM32=$(echo "$CHANGED_FILES" | jq -r ".platform_stm32")

BUILD_ALL="false"

if [[ "$PROJECTS" == "true" || "$GENERIC" == "true" || "$CI_WORKFLOWS" == "true" ]]; then
    BUILD_ALL="true"
fi

if [[ "BUILD_ALL" == "true" ]]; then
    PLATFORMS="maxim pico mbed stm32"
else
    PLATFORMS=""
    if [[ "MAXIM" == "true" ]]; then
        PLATFORMS=$(echo "$PLATFORMS, maxim")
    fi
    if [[ "PICO" == "true" ]]; then
        PLATFORMS=$(echo "$PLATFORMS, pico")
    fi
    if [[ "MBED" == "true" ]]; then
        PLATFORMS=$(echo "$PLATFORMS, mbed")
    fi
    if [[ "STM32" == "true" ]]; then
        PLATFORMS=$(echo "$PLATFORMS, stm32")
    fi
fi

# Export platforms to github output context
echo "PLATFORMS=$PLATFORMS" >> $GITHUB_OUTPUT
