#!/bin/bash

# CMS Docker Management Script Wrapper
# This script delegates to the docker/docker-scripts.sh file for better organization

# Change to docker directory and run the actual script
cd "$(dirname "$0")/docker" && ./docker-scripts.sh "$@"
