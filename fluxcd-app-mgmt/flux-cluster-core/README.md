# Flux System

## Initial Bootstrap with Flux Operator (flux-cluster-core)

0. Make sure your Kubernetes nodes have become `Ready`.
   - If you have not reached the condition, please follow the steps in [talos-infra](https://gitlab.com/nctuwinlab/infra/talos-infra).

1. Install Flux Operator
   - ref: [Bootstrap with Flux Operator](https://fluxcd.io/flux/installation/)
   - The steps may be changed over time, please refer to the official documentation for the latest information.
   - Install Flux Operator in the `flux-system` namespace
     ```bash
     helm install flux-operator oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator \
       --namespace flux-system \
       --create-namespace
     ```
   - You can verify the installation by checking the pods in the `flux-system` namespace
     ```bash
     kubectl -n flux-system get pods
     ```


2. Configure (If needed) and Apply `FluxInstance` Resource
   ```bash
   cd flux-cluster-core/clusters/<your-cluster-name>
   kubectl apply -f fluxinstance.yaml
   ```
   - The `FluxInstance` resource:
     - Install Flux controllers based on `distribution` and `components` fields
     - Adjust controller Deployments based on the `kustomize.patches` field (if specified)
     - Creates Source (e.g., `GitRepository`, `OCIRepository`) and `Kustomization` resources to reconcile the cluster state with the desired state defined in a remote repository (if sync is configured, we didn't do this part)
   - You can verify the installation by checking the pods in the `flux-system` namespace
     ```bash
     kubectl -n flux-system get pods
     ```

3. Create deploy token in Gitlab
   - ref: [Create deploy token](https://docs.gitlab.com/user/project/deploy_tokens/)
   - Location: `[Group] > Settings > Repository > Deploy tokens`
   - Create deploy token with the following information:
     - scope: `read_repository`, `read_registry`, `read_package_registry`
     - username: `flux`
   - Copy the deploy token and save it in a safe place, we will use it (as `<deploy-token>`) in the next step.

4. Create the secret used to access git repo

   ```bash
    kubectl -n flux-system create secret generic flux \
    --from-literal=username=flux \
    --from-literal=password=<deploy-token>
    ```

5. Create and apply Flux CRs to subscribe the `flux-cluster-core` repo, for example:

    ```yaml
    ---
    apiVersion: source.toolkit.fluxcd.io/v1
    kind: GitRepository
    metadata:
    name: flux-core
    namespace: flux-system
    spec:
    url: https://gitlab.com/nctuwinlab/infra/flux-cluster-core.git
    ref:
        branch: main
    interval: 1m0s
    timeout: 60s
    secretRef:
        name: <secret-name> # the name of the secret created in step 4
    ---
    apiVersion: kustomize.toolkit.fluxcd.io/v1
    kind: Kustomization
    metadata:
    name: flux-core
    namespace: flux-system
    spec:
    sourceRef:
        kind: GitRepository
        name: flux-core
    path: ./clusters/<cluster-name>
    force: false
    prune: true
    interval: 10m0s

   ```
   - You can also see the example in `flux-cluster-core/clusters/<existing-cluster>/*.yaml`
   - Apply the CRs to your cluster
     ```bash
     cd flux-cluster-core/clusters/<your-cluster-name>
     kubectl apply -f flux-cluster-core.yaml
     ```
   - Because of the path in `flux-cluster-core.yaml` is set up to `./clusters/<cluster-name>`, so Flux will automatically sync the `flux-cluster-infrastructure.yaml` and `flux-cluster-workloads.yaml` in the folder to the cluster.


7. Check if the `Kustomization` and `GitRepository` resources are ready

    ```bash
        kubectl -n flux-system get gitrepositories
        kubectl -n flux-system get kustomizations

        flux get all -A 
        flux get kustomization flux-core -n flux-system
        flux logs -f --level=error
    ```

    - You can also try modifying the `FluxInstance` manifest and push it again, then verify if the resource (and related resources) are updated accordingly.

    - Some apps, such as the nextcloud, may need the time more than default setup to be ready, so you can try to suspend and resume the helmrelease to trigger the reconciliation after the related pods are ready.
    
    ```bash
    HR=nextcloud
    NS=nextcloud
    
    flux suspend helmrelease $HR -n $NS
    flux resume helmrelease $HR -n $NS
    flux reconcile helmrelease $HR -n $NS --with-source
    ```