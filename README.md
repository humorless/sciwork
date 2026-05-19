# Graph Analysis Workshop

## 重要檔案

| 檔案 | 說明 |
|------|------|
| `advertise.md` | 對外宣傳文案，包含課程簡介、學習目標、事前準備 |
| `workshop-design.md` | 課程設計文件，包含每個 Unit 的 Talk / 實作規劃與 dataset 策略 |
| `slide-1.md` | Unit 1 投影片：Graph 是什麼？為什麼不用 SQL / Python 就好 |
| `slide-2.md` | Unit 2 投影片：Cypher — 用結構描述問題 |
| `slide-3.md` | Unit 3 投影片：In-database 計算 — Algorithm Tour |
| `slide-4.md` | Unit 4 投影片：可解釋性 — 路徑就是解釋 |

投影片使用 [Marp](https://marp.app/) 格式撰寫，可轉出 PDF。

---

## 產生 PDF

### 安裝 Marp CLI

```bash
npm install -g @marp-team/marp-cli
```

### 轉出單一檔案

```bash
marp $filename --allow-local-files --pdf
```

### 轉出全部投影片

```bash
for f in slide-*.md; do
  marp "$f" --allow-local-files --pdf
done
```
