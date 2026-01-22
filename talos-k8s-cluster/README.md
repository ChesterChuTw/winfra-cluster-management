# Generate Talos cluster configuration files

## Generate new cluster configuration files

```bash
  # Change the path to your age key file
  export SOPS_AGE_KEY_FILE=~/your-age-key-file.txt
```

1. Create a talconfig.yaml according to your needs
2. Create a talsecret.sops.yaml file with your future cluster secrets
    ```bash
    talhelper gensecret > talsecret.sops.yaml
    ```
3. Encrypt the secret with sops
    ```bash
    sops -e -i talsecret.sops.yaml
    ```
4. Run `talhelper genconfig` and the output files will be in `./clusterconfig` by default
5. Using the generated files to install Talos cluster with `talsoctl`
6. Commit your talconfig.yaml and talsecret.yaml in your git repository.


## Generate Talos cluster configuration files (from an existing cluster config from Git, with sops encryption)

```bash
# Change the path to your age key file
export SOPS_AGE_KEY_FILE=~/your-age-key-file.txt
# export SOPS_AGE_KEY_FILE=$HOME/Library/Application\ Support/sops/age/keys.txt

cd <cluster-name>
# cd winfra-test

# Generate the configuration files
talhelper genconfig
```

# Set up cluster using the generated files

```bash
# Set up the environment variables
export TALOSCONFIG="$(PWD)/clusterconfig/talosconfig"
export TALOS_ENDPOINT="192.168.101.71"

# Set nodes to `control-plane` type
talosctl apply-config --insecure -n <kmaster1-ip> -f <kmaster1-yaml>
talosctl apply-config --insecure -n <kmaster2-ip> -f <kmaster2-yaml>
talosctl apply-config --insecure -n <kmaster3-ip> -f <kmaster3-yaml>

# Bootstrap the cluster (Other master nodes will be joined automatically by the control plane endpoint set up in clusterconfig)
talosctl bootstrap -n <kmaster1-ip> --endpoints <kmaster1-ip>

# Check the health of the cluster
talosctl -n <kmaster1-ip> health
## make sure your master HAProxy config is updated, or it will return `waiting for all k8s nodes to report: Get "https://192.168.101.201:6443/api/v1/nodes": dial tcp 192.168.101.201:6443: connect: connection refused`
## if every things go well, you should see it stuck at `waiting for all k8s nodes to report ready: some nodes are not ready: [kmaster1 kmaster2 kmaster3]`, because our cni is set up to `none`.

# Get kubeconfig of the cluster (it will migrate into your `~/.kube/config`, and set this cluster as the default cluster)
talosctl kubeconfig -n <kmaster1-ip> --force

# Now, you can use `kubectl` to check the cluster
kubectl get nodes -o wide

# Set nodes to `worker` type, it will automatically join the cluster (By the control plane endpoint set up in clusterconfig)
talosctl apply-config --insecure -n <kworker1-ip> -f <kworker1-yaml>
talosctl apply-config --insecure -n <kworker2-ip> -f <kworker2-yaml>
talosctl apply-config --insecure -n <kworker3-ip> -f <kworker3-yaml>
```
- If everything goes well, the `kubectl get nodes -o wide` result will be like the following:
  ```
  NAME       STATUS     ROLES           AGE     VERSION   INTERNAL-IP      EXTERNAL-IP   OS-IMAGE          KERNEL-VERSION   CONTAINER-RUNTIME
  kmaster1   NotReady   control-plane   28m     v1.33.6   192.168.101.71   <none>        Talos (v1.11.4)   6.12.57-talos    containerd://2.1.4
  kmaster2   NotReady   control-plane   28m     v1.33.6   192.168.101.72   <none>        Talos (v1.11.4)   6.12.57-talos    containerd://2.1.4
  kmaster3   NotReady   control-plane   28m     v1.33.6   192.168.101.73   <none>        Talos (v1.11.4)   6.12.57-talos    containerd://2.1.4
  kworker1   NotReady   <none>          6m21s   v1.33.6   192.168.101.74   <none>        Talos (v1.11.4)   6.12.57-talos    containerd://2.1.4
  kworker2   NotReady   <none>          4m40s   v1.33.6   192.168.101.75   <none>        Talos (v1.11.4)   6.12.57-talos    containerd://2.1.4
  kworker3   NotReady   <none>          2m49s   v1.33.6   192.168.101.76   <none>        Talos (v1.11.4)   6.12.57-talos    containerd://2.1.4
  ```
- In the next step, we will set up Calico CNI for the cluster

# Set up Calico CNI for the cluster

## Preface
- Our apps will be managed by FluxCD
- But before that... we need to set up CNI for the cluster, or we will have no way to sync our apps in GitRepo to the cluster!!
- We will use Calico CNI for the cluster

## Steps
- Create a namespace for the operator
    ``` bash
    kubectl create namespace tigera-operator
    kubectl label ns tigera-operator \
      pod-security.kubernetes.io/enforce=privileged \
      --overwrite
    ```
- Deploy the operator using Helm with the values file
    ``` bash
    CALICO_VERSION=3.30.3
    helm repo add calico https://docs.tigera.io/calico/charts
    helm repo update

    cd ./talos-k8s-cluster

    helm install calico calico/tigera-operator \
      --namespace tigera-operator \
      --version $CALICO_VERSION \
      -f ./cni/calico/values.yaml \
      --wait --timeout 10m
    ```
    
- Verify the installation
    ``` bash
    kubectl -n tigera-operator get pods
    kubectl -n calico-system get pods
    kubectl -n kube-system get pods
    kubectl get nodes -o wide
    ```

- If everything goes well, you should see the nodes in the cluster are in `Ready` state
- After that, you can refer to the [flux-cluster-core](https://gitlab.com/nctuwinlab/infra/flux-cluster-core) to bootstrap FluxCD