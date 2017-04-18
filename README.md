# k8s-custom-iptables
Example for manipulating iptables for a Kubernetes cluster

# Making the container

```sh
REGISTRY=gcr.io/my-registry make
```

# Install/uninstall

Install the daemonset that configures the cluster to NAT an IP range.
Note: this will write out `install.yaml` and `uninstall.yaml`.

```
REGISTRY=gcr.io/my-registry TARGET=1.2.3.4/24 ./install.sh
```

Uninstall the IP tables rules from the cluster.

```
./uninstall.sh
```
