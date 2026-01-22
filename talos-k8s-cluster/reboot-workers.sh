#!/usr/bin/env bash
set -euo pipefail

TALOS_DIR=~/chesterchu/winlab/talos-infra/talos-k8s-cluster/winfra-prod
cd "$TALOS_DIR"
export TALOSCONFIG="./clusterconfig/talosconfig"

WORKERS=(
  #"kworker1:192.168.101.74"
  "kworker2:192.168.101.75"
  #"kworker3:192.168.101.76"
)

wait_node_ready() {
  local node_name="$1"
  echo "  [*] 等待節點 ${node_name} 回到 Ready 狀態..."
  kubectl wait node "${node_name}" --for=condition=Ready --timeout=900s
}

# -----------------------------
# PDB 寫死：放寬 & 還原
# -----------------------------

pdb_relax() {
  echo "  [PDB] drain 前：放寬（maxUnavailable=100%）..."

  for ns_name in \
    "auth/keycloak-postgresql" \
    "calico-system/calico-typha" \
    "gitlab/gitlab-kas" \
    "gitlab/gitlab-webservice-default" \
    "gitlab/gitlab-gitlab-shell" \
    "observability/mimir-ingester" \
    "observability/mimir-store-gateway" 
  do
    ns="${ns_name%/*}"
    name="${ns_name#*/}"

    # 設 maxUnavailable=100%
    kubectl patch pdb -n "$ns" "$name" --type='merge' -p '{"spec":{"maxUnavailable":"100%"}}' >/dev/null 2>&1 || true
    # 保持跟你原本一樣：確保不會同時存在 minAvailable
    kubectl patch pdb -n "$ns" "$name" --type='json'  -p='[{"op":"remove","path":"/spec/minAvailable"}]' >/dev/null 2>&1 || true

    echo "    - $ns_name  maxUnavailable -> 100%"
  done
}


pdb_restore() {
  echo "  [PDB] uncordon 後：還原（maxUnavailable=1）..."

  for ns_name in \
    "auth/keycloak-postgresql" \
    "calico-system/calico-typha" \
    "gitlab/gitlab-kas" \
    "gitlab/gitlab-webservice-default" \
    "gitlab/gitlab-gitlab-shell" \
    "observability/mimir-ingester" \
    "observability/mimir-store-gateway" 
  do
    ns="${ns_name%/*}"
    name="${ns_name#*/}"

    kubectl patch pdb -n "$ns" "$name" --type='merge' -p '{"spec":{"maxUnavailable":1}}' >/dev/null 2>&1 || true
    kubectl patch pdb -n "$ns" "$name" --type='json'  -p='[{"op":"remove","path":"/spec/minAvailable"}]' >/dev/null 2>&1 || true

    echo "    - $ns_name  maxUnavailable -> 1 (restore)"
  done
}

# -----------------------------
# 主流程
# -----------------------------
for item in "${WORKERS[@]}"; do
  IFS=':' read -r NODE_NAME NODE_IP <<< "${item}"

  echo "=================================================="
  echo "👉 處理節點：${NODE_NAME} (${NODE_IP})"
  echo "=================================================="

  echo "[1/5] cordon..."
  kubectl cordon "${NODE_NAME}"

  echo "[2/5] drain 前放寬 PDB..."
  pdb_relax

  echo "[3/5] drain..."
  kubectl drain "${NODE_NAME}" \
    --ignore-daemonsets \
    --delete-emptydir-data \
    --grace-period=60 \
    --timeout=5m || \
  echo "⚠️ drain timeout / failed，直接進行 reboot（已 cordon）"

  echo "[4/5] talosctl reboot..."
  talosctl --nodes "${NODE_IP}" reboot

  echo "    等 10 秒..."
  sleep 10

  echo "[5/5] 等 Ready..."
  wait_node_ready "${NODE_NAME}"

  echo "    uncordon..."
  kubectl uncordon "${NODE_NAME}"

  echo "    還原 PDB..."
  pdb_restore

  echo "✅ 節點 ${NODE_NAME} 完成"
  echo
done

echo "🎉 所有 worker 節點已依序重啟完成！"