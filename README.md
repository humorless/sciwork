# Graph Analysis Workshop

## 事前準備

### 必需軟體版本

- **Ladybug DB CLI**: 0.17.0
  ```bash
  brew install ladybug
  ```

- **Ladybug Explorer**: 0.17.0（Docker）
  ```bash
  docker pull ghcr.io/ladybugdb/explorer:0.17.0
  ```

### 驗證安裝

```bash
# 確認 lbug 版本
lbug --version
```

---

## 重要檔案

### 課程文件

| 檔案 | 說明 |
|------|------|
| `advertise.md` | 對外宣傳文案，包含課程簡介、學習目標、事前準備 |
| `workshop-design.md` | 課程設計文件，包含每個 Unit 的 Talk / 實作規劃與 dataset 策略 |
| `slide-1.md` | Unit 1 投影片：Graph 是什麼？為什麼不用 SQL / Python 就好 |
| `slide-2.md` | Unit 2 投影片：Cypher — 用結構描述問題 |
| `slide-3.md` | Unit 3 投影片：In-database Analytics — Algorithm Tour |
| `slide-4.md` | Unit 4 投影片：可解釋性 — 路徑就是解釋 |

投影片使用 [Marp](https://marp.app/) 格式撰寫，可轉出 PDF。

### 資料集文件

| 檔案 | 用途 | 來源 |
|------|------|------|
| `supply-chain.cypher` | Unit 1-2 的示例資料集（8 個節點、12 條邊） | 本項目提供 |
| `social-network.cypher` | Unit 2 的 Social Network dataset（10 個節點、18 條邊） | 本項目提供 |
| `schema.cypher` | Unit 3 的資料庫模式定義 | LadybugDB 官方 dataset |
| `amazon-nodes.csv`<br/>`amazon-edges.csv` | Unit 3-4 的 Amazon follow graph（~403k 節點、~3.4M 邊） | LadybugDB 官方 dataset |

**Amazon dataset 下載**：

```bash
# 從 LadybugDB 官方 dataset 倉庫下載
curl -O https://raw.githubusercontent.com/LadybugDB/dataset/main/snap/amazon0601/csv/schema.cypher
curl -O https://raw.githubusercontent.com/LadybugDB/dataset/main/snap/amazon0601/csv/amazon-nodes.csv
curl -O https://raw.githubusercontent.com/LadybugDB/dataset/main/snap/amazon0601/csv/amazon-edges.csv  # ~48 MB
```

---

## 產生 PDF

### 安裝 Marp CLI

```bash
npm install -g @marp-team/marp-cli
```

### 轉出單一檔案

```bash
marp $filename --allow-local-files --html --pdf
```

### 轉出全部投影片

```bash
for f in slide-*.md; do
  marp "$f" --allow-local-files --pdf
done
```
