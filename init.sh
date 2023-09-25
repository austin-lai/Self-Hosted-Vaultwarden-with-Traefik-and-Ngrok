#!/bin/bash

display_help() {
  echo "Description:"
  echo "      This is a helper script for managing Docker containers."
  echo "      This script will START or STOP the container specified in the selected docker compose file"
  echo "Usage:"
  echo "      $0 [file] [command]"
  echo "Options:"
  echo "     file:  The Docker compose file to use (vaultwarden, ngrok)"
  echo "                *vaultwarden - Start Vaultwarden container using $vaultwarden_path"
  echo "                *ngrok - Start Ngrok container using $ngrok_path"
  echo "  command:  The command to execute (up, down)"
  echo "                *up - docker compose -f [file] up --timestamps --wait --detach"
  echo "                *down - docker compose -f [file] down"
  echo "       -h:  Display this help message (--help, /?)"
}

# Define docker compose files
vaultwarden="vaultwarden-docker-compose.yml"
ngrok="ngrok-docker-compose.yml"

# Get the current path of the script
script_path=$(dirname "$0")

# Append the current path to the docker compose files
vaultwarden_path="$script_path/$vaultwarden"
ngrok_path="$script_path/$ngrok"

# Set valid_arg1 to false as default arg1 or $1 is not exist
valid_arg1="no"

# Check for command line arguments
if [ -z "$1" ]; then
  arg1="-h"
else
  arg1="$1"
fi

# Display help message
if [ "$arg1" = "/?" ] || [ "$arg1" = "-h" ] || [ "$arg1" = "--help" ]; then
  display_help
  exit 0
fi

# Capture Ctrl+C and exit
trap "exit 1" INT

# Allow user to select which file to use
case "$arg1" in
  vaultwarden)
    selected_file="$vaultwarden_path"
    valid_arg1="yes"
    ;;
  ngrok)
    selected_file="$ngrok_path"
    valid_arg1="yes"
    ;;
  *)
    echo
    echo "Error: Invalid input. Please select a valid file."
    echo
    display_help
    exit 1
    ;;
esac

# Allow user to select which file to use
# Only proceed if there is a valid first argument!
if [ "$valid_arg1" = "yes" ]; then

  # Check if second argument exists, if not display error and help message
  if [ -z "$2" ]; then
    echo
    echo "Error: Missing second option/argument."
    echo
    display_help
    exit 1
  else
    case "$2" in
      up)
        if [ "$arg1" = "vaultwarden" ]; then
          container_id=$(docker ps -qf "name=^/$arg1$")
          if [ -n "$container_id" ]; then
            echo "The $arg1 container is already running!"
          else
            echo "The $arg1 container is not running."
            docker compose -f "$selected_file" up --timestamps --wait --detach 
          fi 
        elif [ "$arg1" = "ngrok" ]; then 
          container_id=$(docker ps -qf "name=^/$arg1$")
          if [ -n "$container_id" ]; then 
            echo "The $arg1 container is already running!"
          else 
            echo "The $arg1 container is not running."
            # If the first argument is "ngrok".
            # Check if vaultwarden container is runing.
            # Since ngrok need to attach to the same docker 
            # network as vaultwarden container.
            vaultwarden_container_id=$(docker ps -qf "name=vaultwarden")
            if [ -n "$vaultwarden_container_id" ]; then 
              echo "The vaultwarden container is running!"
              docker compose -f "$selected_file" up --timestamps --wait --detach 
            else 
              echo "The vaultwarden container is not running."
              echo "Will not proceed to start ngrok container."
              echo "Please ensure vaultwarden container is running first."
              echo "Since ngrok need to attach to the same docker network as vaultwarden container."
            fi 
          fi 
        fi 
        ;;
      down)
        if [ "$arg1" = "vaultwarden" ]; then 
          ngrok_container_id=$(docker ps -qf "name=ngrok")
          if [ -n "$ngrok_container_id" ]; then 
            echo "The ngrok container is running!"
            echo "Will not proceed to stop vaultwarden container."
            echo "Please ensure ngrok container is not running first."
            echo "Since ngrok is attach to the same docker network as vaultwarden container." 
          else 
            echo "The ngrok container is not running."
            docker compose -f "$selected_file" down 
          fi 
        elif [ "$arg1" = "ngrok" ]; then 
          docker compose -f "$selected_file" down 
        fi 
        ;;
      *)
        echo 
        echo "Error: Invalid option/argument. Please select a valid option/argument."
        echo 
        display_help
        exit 1
        ;;
    esac  
  fi  
fi
