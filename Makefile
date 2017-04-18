#!/usr/bin/make -f

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

NAME := k8s-custom-iptables
SRCS := run.sh

TAG ?= 1.0
REGISTRY=gcr.io/google_containers
IMAGE := $(REGISTRY)/$(NAME):$(TAG)

ifeq ($(REGISTRY),)
$(error Must specify REGISTRY variable)
endif

all: push

push: image
	gcloud docker -- push $(IMAGE)

image: Dockerfile $(SRCS)
	docker build -f Dockerfile -t $(IMAGE) .

.PHONY: image push
