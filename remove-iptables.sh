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

# Can be overridden via env vars.
DEST_SUBNET=${DEST_SUBNET:-10.123.0.0/16}
IPTABLES=${IPTABLES:-/sbin/iptables}
COMMENT="fix-iptables: MASQ"

${IPTABLES} \
  -t nat \
  -D POSTROUTING \
  -d "${DEST_SUBNET}" \
  -m comment --comment "${COMMENT}" \
  -m addrtype ! --dst-type LOCAL \
  -j MASQUERADE
