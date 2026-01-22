# secretGenerator vs configMapGenerator 使用指南

## 核心原則

### ✅ 使用 `secretGenerator` 的情況

1. **values.yaml 包含 SOPS 加密的內容（ENC[...]）**
   - **關鍵限制**：`configMapGenerator` 引用的檔案內容不會被 Flux decryption 正確解密
   - **實際測試結果**：即使 Kustomization 有 `decryption` 設定，`configMapGenerator` 建立的 ConfigMap 中值仍然是加密格式
   - **解決方案**：改用 `secretGenerator`，可以正確處理解密後的內容
   - `secretGenerator` 配合 decryption 設定可以正確解密檔案內容
   - **技術原因**：Flux Kustomization 的 decryption 會解密檔案，但 `configMapGenerator` 在建立 ConfigMap 時可能是在解密之前就讀取了檔案，而 `secretGenerator` 可以正確處理解密後的內容

2. **values.yaml 包含敏感資料（即使未加密）**
   - 密碼、API keys、tokens 等敏感資訊
   - 使用 Secret 可以提供額外的安全層級（RBAC 控制、加密 at rest 等）

3. **Helm chart 支援從 Secret 讀取 values**
   - 大多數 Helm chart 都支援 `valuesFrom` 中的 `kind: Secret`
   - 與 `kind: ConfigMap` 的用法相同

### ✅ 使用 `configMapGenerator` 的情況

1. **values.yaml 不包含加密內容**
   - 只有非敏感的配置（如 replica count、resource limits 等）
   - ConfigMap 更適合非敏感資料

2. **values.yaml 不包含敏感資料**
   - 純配置資訊，沒有密碼或 keys

3. **需要更簡單的設定**
   - ConfigMap 的權限管理通常更寬鬆
   - 適合需要多個服務讀取的配置

## 實際範例

### 範例 1: Velero（應使用 secretGenerator）

```yaml
# values.yaml 包含加密的 credentials
credentials:
    secretContents:
        cloud: ENC[AES256_GCM,data:...]
```

**原因**：包含 SOPS 加密內容，必須使用 `secretGenerator` 才能正確解密。

### 範例 2: Observability（目前使用 configMapGenerator，但應考慮改用）

```yaml
# values-grafana.yaml 包含加密的 adminPassword
adminPassword: ENC[AES256_GCM,data:...]

# values-loki.yaml 包含加密的 access keys
s3:
    accessKeyId: ENC[AES256_GCM,data:...]
    secretAccessKey: ENC[AES256_GCM,data:...]
```

**建議**：雖然目前 Grafana 似乎能正常工作（可能是 Helm chart 的特殊處理），但為了一致性和可靠性，建議改用 `secretGenerator`。

### 範例 3: Traefik（可以使用 configMapGenerator）

```yaml
# values.yaml 只包含非敏感配置
replicas: 3
resources:
  requests:
    cpu: 100m
    memory: 128Mi
```

**原因**：不包含敏感資料，可以使用 `configMapGenerator`。

## 檢查清單

在決定使用哪個時，請檢查：

- [ ] values.yaml 中是否有 `ENC[AES256_GCM,data:...]` 格式的加密值？
  - ✅ 是 → 使用 `secretGenerator`
  - ❌ 否 → 繼續檢查

- [ ] values.yaml 中是否有敏感資料（密碼、keys、tokens）？
  - ✅ 是 → 建議使用 `secretGenerator`
  - ❌ 否 → 可以使用 `configMapGenerator`

- [ ] Helm chart 是否支援從 Secret 讀取 values？
  - ✅ 是 → 可以使用 `secretGenerator`
  - ❌ 否 → 只能使用 `configMapGenerator`（罕見情況）

## 遷移步驟

如果發現應該使用 `secretGenerator` 但目前使用 `configMapGenerator`：

1. **修改 kustomization.yaml**
   ```yaml
   # 從
   configMapGenerator:
     - name: helm-values
       files:
         - values.yaml
   
   # 改為
   secretGenerator:
     - name: helm-values
       files:
         - values.yaml
   ```

2. **修改 HelmRelease**
   ```yaml
   # 從
   valuesFrom:
     - kind: ConfigMap
       name: helm-values
       valuesKey: values.yaml
   
   # 改為
   valuesFrom:
     - kind: Secret
       name: helm-values
       valuesKey: values.yaml
   ```

3. **Commit 並 push**
4. **等待 Flux 同步**
5. **驗證 Secret 中的值是否已正確解密**

## 目前專案中需要檢查的應用

根據搜尋結果，以下應用包含加密的 values.yaml，應考慮改用 `secretGenerator`：

### flux-cluster-infrastructure
- ✅ **velero** - 已改為 `secretGenerator`
- ⚠️ **observability** (grafana, loki, mimir, tempo) - 目前使用 `configMapGenerator`，但包含加密內容
- ⚠️ **kube-prometheus-stack** - 包含加密的 `adminPassword`

### flux-cluster-workloads
- ⚠️ **wiki** - 包含加密的 `postgresqlPassword`
- ⚠️ **keycloak** - 包含加密的 `adminPassword`
- ⚠️ **harbor** - 包含加密的 `harborAdminPassword`
- ⚠️ **minio** - 包含加密的 `rootPassword`
- ⚠️ **nextcloud** - 包含加密的密碼

## 技術細節

### Flux Decryption 的工作原理

1. **Flux Kustomization 的 decryption 會解密檔案內容**
   - 當 Kustomization 有 `decryption` 設定時，Flux 會使用 SOPS 解密檔案

2. **configMapGenerator 的限制**
   - `configMapGenerator` 在建立 ConfigMap 時，引用的檔案內容不會被正確解密
   - 即使 Kustomization 有 `decryption` 設定，`configMapGenerator` 讀取的內容可能仍然是加密格式
   - **實際測試**：在 velero 應用中，使用 `configMapGenerator` 時，ConfigMap 中的加密值無法被解密；改用 `secretGenerator` 後，Secret 中的值正確解密
   - 這可能是 Flux 處理 `configMapGenerator` 和 `secretGenerator` 的方式不同導致的

3. **secretGenerator 的優勢**
   - `secretGenerator` 可以正確處理解密後的檔案內容
   - 或者 Secret 資源本身會被 Flux 正確解密

### 為什麼不是「只有 Secret 支援 SOPS decryption」？

- Flux 的 decryption 功能本身會解密檔案（無論是 Secret 還是 ConfigMap 資源）
- 問題在於 `configMapGenerator` 在處理引用的檔案時有已知限制
- `secretGenerator` 沒有這個限制，可以正確處理解密後的內容

## 注意事項

1. **Grafana 的特殊情況**
   - 目前 Grafana 使用 `configMapGenerator` 但似乎能正常工作
   - 這可能是因為：
     - Helm chart 在處理時有特殊邏輯
     - Helm Controller 會自動處理頂層的 `ENC[...]` 值
     - 但嵌套結構（如 `credentials.secretContents.cloud`）無法被處理
   - 為了一致性和可靠性，建議改用 `secretGenerator`

2. **Flux 版本**
   - 這個限制在 Flux v2.3.0 和 kustomize-controller v1.3.0 中存在
   - 未來版本可能會修復，但目前建議使用 `secretGenerator`

3. **性能考量**
   - Secret 和 ConfigMap 的性能差異很小
   - 選擇主要基於安全性和功能需求

## 參考資料

- [Flux SOPS 解密文件](https://fluxcd.io/flux/components/kustomize/kustomization/#decryption)
- **實際測試結果**：基於 velero 和 observability 應用的實際測試，確認 `configMapGenerator` 無法正確解密，而 `secretGenerator` 可以

