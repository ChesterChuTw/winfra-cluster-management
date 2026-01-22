# Grafana Dashboard 使用指南

## 📊 已配置的數據源

您的 Grafana 實例已經配置了三個數據源：

1. **Mimir** (Metrics/Prometheus)
   - URL: `http://mimir-nginx.observability.svc.cluster.local/pormetheus`
   - 用途：存儲和查詢指標數據（metrics）
   - 類型：Prometheus 兼容

2. **Loki** (Logs)
   - URL: `http://loki-gateway.observability.svc.cluster.local`
   - 用途：存儲和查詢日誌數據（logs）
   - 類型：Loki

3. **Tempo** (Traces)
   - URL: `http://tempo-gateway.observability.svc.cluster.local`
   - 用途：存儲和查詢分散式追踪數據（traces）
   - 類型：Tempo

## 🎯 Dashboard 類型與用途

### 1. Metrics Dashboard (使用 Mimir 數據源)

#### 用途
- **監控系統資源**：CPU、記憶體、磁盤、網路使用率
- **應用程式性能**：請求速率、響應時間、錯誤率
- **業務指標**：用戶數量、交易量、API 調用次數
- **趨勢分析**：長期趨勢、容量規劃

#### 如何使用
1. **查看實時指標**：
   - 使用 Time Series 圖表查看指標隨時間的變化
   - 使用 Stat 面板顯示當前數值
   - 使用 Gauge 面板顯示百分比或範圍值

2. **常用查詢範例**：
   ```
   # CPU 使用率
   rate(container_cpu_usage_seconds_total[5m])
   
   # 記憶體使用
   container_memory_usage_bytes
   
   # HTTP 請求速率
   rate(http_requests_total[5m])
   ```

3. **告警設定**：
   - 在 Alerting 頁面設定基於 metrics 的告警規則
   - 當指標超過閾值時自動通知

#### 推薦的 Dashboard ID（從 grafana.com 導入）
- **1860** - Node Exporter Full：完整的節點監控
- **6417** - Kubernetes Cluster Monitoring：Kubernetes 集群監控
- **13332** - Kubernetes Deployment Statefulset Daemonset metrics：K8s 工作負載監控
- **315** - Kubernetes / Compute Resources / Cluster：集群資源監控
- **8588** - Kubernetes / Compute Resources / Pod：Pod 資源監控

---

### 2. Logs Dashboard (使用 Loki 數據源)

#### 用途
- **日誌查詢和過濾**：搜尋特定時間範圍內的日誌
- **錯誤追蹤**：快速找到錯誤和異常日誌
- **日誌聚合分析**：統計日誌級別分布、來源分布
- **問題排查**：通過日誌追蹤問題的根本原因

#### 如何使用
1. **基本查詢**：
   ```
   # 查詢包含特定關鍵字的日誌
   {namespace="default"} |= "error"
   
   # 查詢特定應用的日誌
   {app="myapp"}
   
   # 查詢錯誤級別的日誌
   {level="error"}
   ```

2. **日誌聚合**：
   ```
   # 統計每個應用的日誌數量
   sum(count_over_time({}[1h])) by (app)
   
   # 按日誌級別分組
   sum(count_over_time({}[1h])) by (level)
   ```

3. **與 Metrics 關聯**：
   - 在 Explore 頁面可以同時查看 Logs 和 Metrics
   - 從日誌中找到問題後，切換到 Metrics 查看相關指標

#### 推薦的 Dashboard ID
- **13639** - Loki & Promtail：Loki 自身監控
- **14019** - Kubernetes Logs：Kubernetes 日誌視圖

---

### 3. Traces Dashboard (使用 Tempo 數據源)

#### 用途
- **分散式追踪**：追蹤請求在多個服務間的完整路徑
- **性能分析**：識別慢請求、瓶頸服務
- **依賴關係**：了解服務間的調用關係
- **錯誤定位**：找到導致錯誤的具體服務和方法

#### 如何使用
1. **搜索 Trace**：
   - 使用 Trace ID 直接搜索
   - 使用標籤過濾：`service.name="my-service"`
   - 使用時間範圍和持續時間過濾

2. **查看 Trace 詳情**：
   - 時間軸視圖：查看每個 span 的執行時間
   - 服務地圖：視覺化服務間的調用關係
   - 詳細信息：查看每個 span 的標籤、日誌、指標

3. **與 Logs 和 Metrics 關聯**：
   - 從 Trace 中點擊 span 可以直接跳轉到相關日誌
   - 可以查看相關的 metrics（通過 exemplars）

#### 推薦的 Dashboard ID
- **15999** - Tempo：Tempo 服務監控
- **15141** - Tempo / Service Graph：服務依賴圖
- **16107** - Tempo / Search：Trace 搜索界面

---

## 🚀 快速開始

### 方法 1：導入預設 Dashboard（推薦）

1. **登入 Grafana**：
   - 訪問：`https://grafana.winfra.cs.nycu.edu.tw`
   - 使用您的帳號登入

2. **導入 Dashboard**：
   - 點擊左側菜單 **Dashboards** → **Import**
   - 在 "Grafana.com dashboard URL or ID" 輸入框輸入 Dashboard ID（例如：`1860`）
   - 點擊 **Load** 按鈕
   - 選擇對應的數據源（Mimir、Loki 或 Tempo）
   - 點擊 **Import** 完成導入

3. **配置數據源映射**：
   - 導入時系統會提示您選擇數據源
   - Metrics dashboard 選擇 **Mimir**
   - Logs dashboard 選擇 **Loki**
   - Traces dashboard 選擇 **Tempo**

### 方法 2：使用 Explore 功能快速查詢

1. **訪問 Explore**：
   - 點擊左側菜單 **Explore**
   - 選擇數據源（Mimir/Loki/Tempo）

2. **輸入查詢**：
   - 對於 Metrics：使用 PromQL 查詢語法
   - 對於 Logs：使用 LogQL 查詢語法
   - 對於 Traces：使用標籤過濾器

3. **保存為 Dashboard**：
   - 查詢結果滿意後，點擊右上角 **Save**
   - 選擇 "Save to dashboard"
   - 選擇現有 dashboard 或創建新的

### 方法 3：從數據源頁面創建

1. **訪問數據源**：
   - 點擊左側菜單 **Connections** → **Data sources**
   - 點擊數據源名稱（Mimir/Loki/Tempo）

2. **創建 Dashboard**：
   - 點擊 **Build a dashboard** 按鈕
   - 開始添加視覺化面板（visualization panels）

---

## 📈 建立自定義 Dashboard

### 步驟 1：創建新的 Dashboard

1. 點擊左側菜單 **Dashboards** → **New** → **New dashboard**
2. 點擊 **Add visualization** 按鈕
3. 選擇數據源（Mimir/Loki/Tempo）

### 步驟 2：添加 Panels

#### Metrics Panel（使用 Mimir）
1. **選擇視覺化類型**：
   - Time series：時間序列圖表（最常用）
   - Stat：統計數值
   - Gauge：儀表盤
   - Table：表格

2. **編寫查詢**：
   ```promql
   # 範例：CPU 使用率
   rate(container_cpu_usage_seconds_total{namespace="observability"}[5m]) * 100
   ```

3. **配置面板**：
   - 設置標題和描述
   - 調整圖表樣式和顏色
   - 設置單位（如百分比、字節等）

#### Logs Panel（使用 Loki）
1. **選擇視覺化類型**：
   - Logs：日誌列表視圖（最常用）
   - Table：表格視圖

2. **編寫查詢**：
   ```logql
   # 範例：查詢特定命名空間的錯誤日誌
   {namespace="observability", level="error"}
   ```

3. **配置面板**：
   - 設置顯示的行數
   - 配置日誌字段的顯示

#### Traces Panel（使用 Tempo）
1. **選擇視覺化類型**：
   - Traces：追踪視圖（最常用）
   - Service Map：服務地圖

2. **編寫查詢**：
   ```
   # 範例：按服務名稱過濾
   {service.name="my-service"}
   ```

3. **配置面板**：
   - 設置時間範圍
   - 配置顯示的 span 詳情

### 步驟 3：保存 Dashboard

1. 點擊右上角 **Save dashboard** 按鈕
2. 輸入 Dashboard 名稱
3. 選擇保存的文件夾
4. 點擊 **Save**

---

## 🔗 整合使用：Correlation（關聯查詢）

Grafana 支持在 Logs、Traces 和 Metrics 之間進行關聯查詢：

### 從 Logs 跳轉到 Traces
1. 在 Loki Explore 中查看日誌
2. 如果日誌中包含 Trace ID，點擊 Trace ID
3. 自動跳轉到 Tempo 查看完整的 Trace

### 從 Traces 跳轉到 Logs
1. 在 Tempo Explore 中查看 Trace
2. 點擊某個 Span
3. 在詳情面板中可以查看相關的日誌

### 從 Metrics 查看相關日誌
1. 在 Metrics 圖表中發現異常點
2. 點擊圖表上的 exemplar 點（如果配置了 exemplars）
3. 可以跳轉到相關的 Trace 或 Logs

---

## 📝 常用查詢範例

### Metrics (PromQL)

```promql
# CPU 使用率
100 - (avg(irate(container_cpu_usage_seconds_total{name!=""}[5m])) * 100)

# 記憶體使用率
container_memory_usage_bytes{name!=""} / container_spec_memory_limit_bytes{name!=""} * 100

# HTTP 請求速率（按狀態碼）
sum(rate(http_requests_total[5m])) by (status_code)

# Pod 重啟次數
increase(kube_pod_container_status_restarts_total[1h])
```

### Logs (LogQL)

```logql
# 錯誤日誌統計
sum(count_over_time({level="error"}[1h])) by (namespace, app)

# 特定應用的日誌
{app="myapp", namespace="default"}

# 包含特定關鍵字的日誌
{namespace="observability"} |= "error" | json

# 日誌級別分布
sum(count_over_time({}[1h])) by (level)
```

### Traces

```
# 搜索特定服務的 Trace
{service.name="my-service"}

# 搜索慢請求（持續時間 > 1s）
{service.name="my-service"} | duration > 1s

# 搜索包含錯誤的 Trace
{service.name="my-service", status="error"}
```

---

## 🎨 Dashboard 最佳實踐

1. **組織結構**：
   - 使用文件夾組織相關的 dashboard
   - 使用標籤（tags）方便搜索
   - 為 dashboard 添加清晰的描述

2. **面板布局**：
   - 將相關的指標放在同一行
   - 使用 Row 來組織相關面板
   - 保持 dashboard 簡潔，避免過多面板

3. **時間範圍**：
   - 設置合理的默認時間範圍
   - 考慮設置 auto-refresh 以自動更新

4. **告警**：
   - 在 dashboard 中標註重要的閾值
   - 使用 Alerting 功能設定自動告警

5. **變量（Variables）**：
   - 使用變量讓 dashboard 更靈活
   - 例如：namespace、pod、service 等變量

---

## 🆘 疑難排解

### 沒有數據顯示
1. 檢查數據源連接狀態
2. 檢查時間範圍是否正確
3. 檢查查詢語法是否正確
4. 使用 Explore 功能測試查詢

### Dashboard 載入慢
1. 減少查詢的時間範圍
2. 減少面板數量
3. 使用適當的查詢間隔（如 `[5m]` 而不是 `[1m]`）

### 數據源連接失敗
1. 檢查數據源的 URL 是否正確
2. 使用 kubectl 檢查服務是否運行：
   ```bash
   kubectl get svc -n observability | grep gateway
   ```

---

## 📚 更多資源

- **Grafana 官方文檔**：https://grafana.com/docs/grafana/latest/
- **Prometheus 查詢語法**：https://prometheus.io/docs/prometheus/latest/querying/basics/
- **LogQL 查詢語法**：https://grafana.com/docs/loki/latest/logql/
- **Tempo 查詢語法**：https://grafana.com/docs/tempo/latest/
- **Grafana Dashboard 庫**：https://grafana.com/grafana/dashboards/

---

## 🎯 下一步建議

1. **導入基礎監控 Dashboard**：
   - 從 grafana.com 導入 Node Exporter 和 Kubernetes 監控 dashboard

2. **配置告警規則**：
   - 為關鍵指標設定告警規則
   - 配置通知渠道（如 Slack、Email）

3. **整合應用日誌**：
   - 確保應用程式發送日誌到 Loki
   - 配置日誌標籤以便於查詢

4. **設置分散式追踪**：
   - 在應用程式中集成 OpenTelemetry
   - 發送 trace 數據到 Tempo

5. **創建自定義 Dashboard**：
   - 根據您的具體需求創建專用的 dashboard
   - 整合 Metrics、Logs 和 Traces 在一個 dashboard 中

