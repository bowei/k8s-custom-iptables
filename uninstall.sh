#!/bin/bash

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

echo "Removing iptable rules"
sed 's/__NAT_RULES__//g' config.yaml.in | kubectl apply -f -
echo "Waiting for config update to be applied"

pods=$(kubectl get pods -l 'name=k8s-custom-iptables' -o jsonpath='{.items[*].metadata.name}')
count=0
for pod in ${pods}; do
  count=$((${count} + 1))
done

echo "Waiting for ${count} pods to update: ${pods}"

# Wait for all nodes to have no nat rules configured.
while true; do
  done=0
  for pod in ${pods}; do
    if kubectl logs --tail 1 ${pod} 1>/dev/null 2>/dev/null; then
      lastlog=$(kubectl logs --tail 1 ${pod})
      if echo ${lastlog} | grep -q 'No NAT rules configured'; then
        done=$((${done} + 1))
      fi
    else
      # We count errors getting logs as success (pod scheduled on master, died
      # some for some other reason).
      done=$((${done} + 1))
    fi
  done

  if [[ ${done} -eq ${count} ]]; then
    break
  fi

  echo "Waiting for $((${count} - ${done})) pods to update"
done

echo "Removing daemon"
kubectl delete -f daemon.yaml
