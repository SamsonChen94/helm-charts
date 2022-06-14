#!/bin/sh

## Check directory and helm.sh file
## To run helm.sh, you need to be in the helm-charts directory
if [ "${PWD##*/}" != "helm-charts" ] || \
   [ ! -f "helm.sh" ]; then
    echo "Error. Script file does not exist in $PWD directory"
    echo "Are you in the correct directory?"
    exit 1
fi

## Check arguments
if [ $# -ne 2 ]; then
  echo "Error. Invalid number of arguments"
  echo "Usage: ./helm.sh [lint|test|deploy] [PATH_TO_VALUE_FILE]"
  exit 1
fi

## Check command execution
if [ "$1" != "lint" ] && [ "$1" != "test" ] && [ "$1" != "deploy" ]; then
  echo "Error. $1 is not a supported command"
  echo "Usage: ./helm.sh [lint|test|deploy] [PATH_TO_VALUE_FILE]"
  exit 1
fi

## Check path to value file
if [ ! -f "$2" ]; then
  echo "Error. $2 file does not exist"
  exit 1
fi

## Check for helm being installed
if [ "$(command -v helm)" = "" ]; then
  echo "Error. helm command not found"
  echo "helm is an essential component for this script. Please install helm."
  exit 1
fi

## Check helm plugin installation
HELM_SECRETS=$(helm plugin list | awk '/secrets/ {print $1}')
HELM_UNITTEST=$(helm plugin list | awk '/unittest/ {print $1}')

## Install helm secrets plugin
## Ref: https://github.com/jkroepke/helm-secrets
if [ "$HELM_SECRETS" = "" ]; then
  helm plugin install https://github.com/jkroepke/helm-secrets
fi

## Install helm unittest plugin
## Ref: https://github.com/vbehar/helm3-unittest
if [ "$HELM_UNITTEST" = "" ]; then
  helm plugin install https://github.com/vbehar/helm3-unittest
fi

## Running lint tests only
## Ref: https://helm.sh/docs/helm/helm_lint/
if [ "$1" = "lint" ]; then
  helm lint -f $2 .
  exit 0
fi

## Run unit test
## Note: Running unit test includes the basic functionality of running lint so
##       one practically does not need to run lint test when running unit tests
helm unittest .

## Detect command to only run unit test. Exits with no error.
if [ "$1" = "test" ]; then
  exit 0
fi

## TODO: implement deployment
