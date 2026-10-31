# Falco kernel-module offline bundle (Kubernetes v1.25.6 target)

This repository is intended to be uploaded to a GitHub repository. Run Actions > **Build Falco kmod offline bundle** > Run workflow; download the Artifact. GitHub Actions requires outbound Internet; **the cluster does not**.

Default: **Falco chart 4.8.1 / Falco 0.38.2** (documented pairing). This is a deliberately pinned, older baseline, **not a certification that it is compatible with every v1.25.6 configuration or today's security requirements**. Review releases, CVEs and chart API versions before production. To use another chart version, inspect values/image keys and verify template.

The workflow downloads a real Helm chart, renders it with our offline kmod profile, extracts **every container image actually referenced** (including init containers), pulls the images, and saves them as an offline Docker archive. Embedded Falco rules are used; no falcoctl artifact pull is configured. The exported image tar is generally large and is **not included in this source repo**.

## What the bundle does NOT contain

A universal `falco.ko` driver **does not exist**. It depends on **each node's running kernel version, distribution, architecture, driver version, kernel configuration and possibly Secure Boot signing**. The driver-loader image does NOT guarantee successful offline startup; if neither a compatible `.ko` nor kernel headers/build dependencies exist, loader may fail. Fetch/build matching `.ko` packages in a connected clone of the EXACT host kernel environment or host a private driver repository; validate signatures as required. Refer to https://falco.org/docs/setup/tarball/ and https://falco.org/docs/setup/container/ .

## Before deployment

On EVERY target node, run `scripts/check-nodes.sh`, collect kernel/arch and presence of headers. Nodes with mismatched kernels require corresponding drivers. Verify correct image architecture. Do NOT run this alongside an existing Falco DaemonSet for the same nodes: duplicate drivers/monitoring may conflict. Test in a separate cluster or isolated node pool and preserve existing configuration.

## Import images

On a Docker host with network access to the private registry:

```bash
cd extracted-bundle
./scripts/load-and-retag.sh 192.168.72.60:32083
```

This preserves Docker Hub repository names in the private registry, e.g. `192.168.72.60:32083/falcosecurity/falco:0.38.2`. Allow private registry TLS/CA configuration separately. Registry authentication requires `docker login` before pushing. If only containerd exists, use `ctr -n k8s.io images import images/falco-images.tar` and tag/push with your registry's tooling instead.

## Preview without touching the cluster

```bash
./scripts/render-local.sh 192.168.72.60:32083 charts/falco-4.8.1.tgz
kubectl apply --dry-run=client -f rendered-local.yaml
```

**Inspect rendered-local.yaml carefully**. This is a source-rewrite approach with a pinned chart; for production, validate exact image refs and CA trust. If the private registry repository syntax differs, adjust image repository values to match instead.

## Controlled deployment: ONLY once a matching kernel driver is available

If Helm release NOT already installed, and manifests aren't being managed through kubectl:

```bash
kubectl create namespace falco --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install falco charts/falco-4.8.1.tgz -n falco -f offline-values.yaml \
  --set image.registry=192.168.72.60:32083 \
  --set driver.loader.initContainer.image.registry=192.168.72.60:32083
kubectl get pods -n falco -o wide
kubectl logs -n falco -l app.kubernetes.io/name=falco --all-containers --tail=100
```

Important: an *offline kernel module supply path* must be prepared first; do not assume the above will start without access to driver sources. Keep `falcoctl.artifact.*=false`, or image init-container could try to access external registries. Review Pod Security Admission exemptions and privileged access through a formal security approval. The driver module changes the Linux host kernel; no changes to Calico eBPF dataplane are necessary.
