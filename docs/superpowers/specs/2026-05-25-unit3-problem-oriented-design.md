---
title: Unit 3 Slide 改進：問題導向的 Graph Algorithms 架構
date: 2026-05-25
author: Brainstorming Session
status: Design
---

# Unit 3 Slide 3 改進設計

## 目標

強化 workshop 的「問題意識」。在介紹 6 個 graph algorithms 前，先建立「看圖時可以問什麼」的心理模型，再將每個 algorithm 映射到對應的問題類型。

## 背景

**現狀問題**：
- slide-3 目前直接列出 6 個 algorithms，沒有問題框架
- 學生可能會問「什麼時候用哪個算法？」，但缺乏統一的思考模式
- Unit 1 建立了「三問先問清楚」的教學風格，Unit 3 應該延續

**改進方向**：
- 新增一個「看圖時，我們問什麼？」slide
- 改動現有表格，加入「問題類型」欄，呼應三個基本問題
- 重新排序 algorithms，使同類的 algorithms 並列

## 設計方案（選定：方案 A）

### 1. 新增 Slide：「三個問題」（獨立呈現）

**位置**：插在「今天的實作方式」(slide 3) 之後、「六個 Graph Algorithms」表格 (原 slide 5) 之前

**slide 標題**：「看圖時，我們問什麼？」

**內容結構**：
```
三個常見的圖論問題：

❓ 哪些點最重要、最核心？
   [小圖示：節點大小差異，最大的節點突出]
   → PageRank、K-Core Decomposition

❓ 哪些點可以算是同一群的？
   [小圖示：用顏色分組，呈現社群結構]
   → Louvain、Weakly Connected Components、
     Strongly Connected Components

❓ 從 A 點到 B 點怎麼走？
   [小圖示：節點 A 到 B 的最短路徑箭頭]
   → Shortest Paths
```

**設計特性**：
- 延續 Unit 1「三問先問清楚」的教學節奏
- 每個問題配一個 5 秒內能理解的圖示（圖論概念的視覺化）
- 列出對應的 algorithm 名字作為預告，詳細說明交給後續的表格

### 2. 改動「六個 Graph Algorithms」表格

**改動內容**：
- 加入新欄位「問題類型」，對應三個基本問題
- 重新排序 algorithms，使同類型的並列：
  1. PageRank（最重要節點）
  2. K-Core Decomposition（最重要節點）← **移上來，緊接 PageRank**
  3. Louvain（同群偵測）
  4. Weakly Connected Components（同群偵測）
  5. Strongly Connected Components（同群偵測）
  6. Shortest Paths（路徑查詢）← **移到最後**

**新表格結構**：

| Algorithm | 解決的問題 | 實現方式 | 問題類型 |
|-----------|-----------|---------|---------|
| PageRank | 誰是網絡裡最重要的節點？ | ALGO extension | 最重要節點 |
| K-Core Decomposition | 最密集連接的核心子圖是哪些？ | ALGO extension | 最重要節點 |
| Louvain | 圖裡自然地形成了哪些群組？ | ALGO extension | 同群偵測 |
| Weakly Connected Components | 整個圖有幾個獨立的連通塊？ | ALGO extension | 同群偵測 |
| Strongly Connected Components | 哪些節點互相可以到達對方？ | ALGO extension | 同群偵測 |
| Shortest Paths | A 到 B 最短走幾跳？ | Cypher 查詢 | 路徑查詢 |

**排序的邏輯**：
- PageRank + K-Core：都在問「最重要的節點是誰」，只是從不同角度（全局排名 vs. 本地密度）
- 三個連通分量：都在問「哪些節點可以歸為一類」，變化在有向/無向、強/弱
- Shortest Paths：路徑查詢，與前面的分組問題不同，放最後

### 3. 各 Algorithm 詳細 Slide 順序調整

**重新排列的 slide 順序**（目前 Algorithm 1–6 改為）：

| 原順序 | 新順序 | Algorithm | 備註 |
|--------|--------|-----------|------|
| 1 | 1 | Shortest Paths | → 移到位置 6 |
| 2 | 1 | PageRank | 不動 |
| 3 | 2 | Louvain | → 移下一位 |
| 4 | 3 | WCC | → 不動 |
| 5 | 4 | SCC | → 不動 |
| 6 | 5 | K-Core | → 移到位置 2 |

**新順序詳細**：
1. Algorithm 1：**PageRank**
2. Algorithm 2：**K-Core Decomposition** ← 移上來，強調「最重要節點」的兩個不同視角
3. Algorithm 3：**Louvain**
4. Algorithm 4：**Weakly Connected Components**
5. Algorithm 5：**Strongly Connected Components**
6. Algorithm 6：**Shortest Paths** ← 移到最後，對應第三個問題

**各 slide 的內容本身保持不變**——只是順序重新組織，加上在表格中標記「問題類型」。

## 影響範圍

**修改的 slide**：
- slide-3.md（原「六個 Graph Algorithms」slide 之前，新增「三個問題」slide）
- 原有的 Algorithm 1–6 slides 重新排序和標記

**不修改的內容**：
- Unit 1、2、4 的內容保持不變
- 各 algorithm slide 的詳細內容（Cypher 代碼、結果解讀、類比等）保持不變
- 「小結」和「實作目標」slide 的核心邏輯不變，但可能需要微調 algorithm 編號對應

## 成功指標

- ✅ 學生看完「三個問題」slide，能理解「看圖有三種基本問題」
- ✅ 掃一眼「六個 Algorithms」表格，能快速看出每個 algorithm 屬於哪個問題類型
- ✅ 理解為什麼 PageRank 和 K-Core 並列、為什麼三個連通分量相鄰
- ✅ 最後的實作步驟對應新的 algorithm 順序，邏輯清晰

## 實施步驟

1. 設計並呈現三個問題的圖示（使用 Marp 的圖片或 ASCII art）
2. 新增一個 slide（在原 slide 4 和 5 之間）
3. 改動原有的「六個 Algorithms」表格，加欄位、重新排序
4. 調整後續 algorithm slides 的編號和順序
5. 更新「小結」和「實作目標」中的 algorithm 編號對應
