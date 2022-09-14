#!/bin/bash

set -e
set -o pipefail

# cron runs jobs from a non-interactive, non-login shell, so it doesn't load env...
printenv > /etc/environment

# run crond as main process of container
cron -f