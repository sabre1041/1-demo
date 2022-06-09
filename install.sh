#!/bin/bash
set -eux -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
PLATFORM_OPS_DIR=${SCRIPT_DIR}/2-platform-ops

# Clone the platform-ops repository if it has not already been cloned
[ ! -d ${PLATFORM_OPS_DIR} ] && git clone git@github.com:ploigos-automated-governance/2-platform-ops.git ${PLATFORM_OPS_DIR}

# Run the platform-ops install script
${PLATFORM_OPS_DIR}/install-platform.sh

# Delete LimitRanges for created namespaces if they exist
oc delete limitrange --all -n devsecops
oc delete limitrange --all -n sigstore

