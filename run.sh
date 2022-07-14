#!/bin/sh

# Copyright 2017 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
set -e

IPTABLES=${IPTABLES:-/sbin/iptables}
SLEEP_INTERVAL=${SLEEP_INTERVAL:-10}
WAIT_INTERVAL=${WAIT_INTERVAL:-60}
CONFIG_DIR=${CONFIG_DIR:-/cfg}
if [[ -z ${UUID:-} ]]; then
  UUID=$(date "+%s")
fi

COMMENT_PREFIX="custom-iptables-${UUID}"

log() {
  local ts=$(date '+%m-%d %H:%M:%S')
  echo "${ts}]" "$@"
}

update_nat() {
  local mode=$1    # 'A' for add, 'D' for delete.
  local subnet=$2
  local comment=$3

  # Check if the rule already exists if adding.
  if [[ ${mode} = 'A' ]]; then
    if ${IPTABLES} -t nat -C POSTROUTING -d ${subnet} \
        -m comment --comment "${comment}" -j MASQUERADE -w ${WAIT_INTERVAL}\
        2>/dev/null; then
      return
    fi
  fi

  ${IPTABLES} \
    -t nat \
    -${mode} POSTROUTING \
    -d ${subnet} \
    -m comment --comment "${comment}" \
    -j MASQUERADE -w ${WAIT_INTERVAL}

  case ${mode} in
    'A') log "NAT rule ${comment} added";;
    'D') log "NAT rule ${comment} deleted";;
  esac
}

main() {
  log "Starting custom-iptables (${CONFIG_DIR})"

  local nat_rules=

  while true; do
    local old_nat_rules=${nat_rules}
    nat_rules=

    if [[ -r ${CONFIG_DIR}/nat.rules ]]; then
      nat_rules=$(cat ${CONFIG_DIR}/nat.rules | sed 's/[ \n\t]\+$/x/g')
    fi

    # Remove the old NAT rules if config file has changed.
    if [[ "${old_nat_rules}" != "${nat_rules}" ]]; then
      log "Configuration change detected"
      n=0
      until [ "$n" -ge 5 ]
      do
        (for subnet in ${old_nat_rules}; do
          update_nat D ${subnet} "${COMMENT_PREFIX}: ${subnet}"
        done) && break
        n=$((n+1))
        sleep 5
      done
    fi

    if [[ -z "${nat_rules}" ]]; then
      log "No NAT rules configured"
    else
      n=0
      until [ "$n" -ge 5 ]
      do
        (for subnet in ${old_nat_rules}; do
          update_nat A ${subnet} "${COMMENT_PREFIX}: ${subnet}"
        done) && break
        n=$((n+1))
        sleep 5
      done
    fi

    sleep "${SLEEP_INTERVAL}"
  done
}

main