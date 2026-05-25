---
marp: true
theme: default
paginate: true
style: |
  h1 {
    border-bottom: 2px solid #4a90d9;
    padding-bottom: 6px;
    color: #1a1a2e;
  }
  blockquote {
    border-left: 4px solid #4a90d9;
    padding-left: 16px;
    color: #444;
    background: none;
  }
  table {
    font-size: 20px;
  }
  section.lead h1 {
    border-bottom: none;
    font-size: 48px;
    color: #1a1a2e;
  }
---

<!-- _class: lead -->

# In-database Analytics：Algorithm Tour

**Unit 3** | Graph Analysis Workshop

---

# 對比：傳統 vs. In-database

**❌ 傳統做法**
```
DB ──► 拉資料到 App ──► Python 計算 ──► 寫回 DB
       (幾百萬筆)      (慢、記憶體吃緊)
```
痛點：網路 I/O、格式轉換、記憶體壓力

**✅ In-database Analytics**
```
DB ──► 演算法直接在 DB 裡跑 ──► 回傳結果（已聚合）
```
優勢：資料不動、原生加速、結果遠小於原始資料

---

# 今天的實作方式

**Dataset**：Amazon follow graph（來自 SNAP）

每個 algorithm 花 **5–7 分鐘**：
1. 看一句話說明：這個 algorithm 在解什麼問題
2. 跑一個指令
3. 看結果，理解輸出的意義

目標是**建立選型直覺**，不是深入原理

---

# 看圖時，我們問什麼？

## ❓ 哪些點最重要、最核心？

```
   ●───○
  ╱ ╲
 ●   ◎ ← 最大的節點最重要
  ╲ ╱
   ◯
```

PageRank（全局排名）、K-Core Decomposition（本地密度）

---

## ❓ 哪些點可以算是同一群的？

```
 🔴─🔴─🔴
 │   │
 🔴─🔴

 🔵  🟠
 │   │
 🔵  🟠
```

Louvain、Weakly Connected Components、Strongly Connected Components

---

## ❓ 從 A 點到 B 點怎麼走？

```
  A
  │
  ↓
  ◎─┐
  │ │
  ↓ ↓
  B ◎
  
最短路徑 = 最少的跳躍
```

Shortest Paths

---

# 六個 Graph Algorithms

| Algorithm | 解決的問題 | 實現方式 | 問題類型 |
|-----------|-----------|---------|---------|
| PageRank | 誰是網絡裡最重要的節點？ | ALGO extension | **最重要節點** |
| K-Core Decomposition | 最密集連接的核心子圖是哪些？ | ALGO extension | **最重要節點** |
| Louvain | 圖裡自然地形成了哪些群組？ | ALGO extension | **同群偵測** |
| Weakly Connected Components | 整個圖有幾個獨立的連通塊？ | ALGO extension | **同群偵測** |
| Strongly Connected Components | 哪些節點互相可以到達對方？ | ALGO extension | **同群偵測** |
| Shortest Paths | A 到 B 最短走幾跳？ | **Cypher 查詢** | **路徑查詢** |

---

# Algorithm 1：PageRank

**問的問題**：誰是網絡裡最重要的節點？

```cypher
CALL project_graph('Graph', ['account'], ['follows']);
CALL page_rank('Graph')
RETURN node.ID, rank
ORDER BY rank DESC
LIMIT 10
```

**結果解讀**：rank 越高 = 被越多人 follow

**類比**：Supply chain 版本是「哪個零件最多人依賴」

---

# Algorithm 2：K-Core Decomposition

**問的問題**：最密集連接的核心子圖是哪些？

```cypher
CALL project_graph('Graph', ['account'], ['follows']);
CALL k_core_decomposition('Graph')
RETURN k_degree, COUNT(*) AS num_nodes
ORDER BY k_degree DESC
LIMIT 10
```

**結果解讀**：k_degree 越高 = 節點與越多其他節點互相連接

---

# Algorithm 3：Louvain（Community Detection）

**問的問題**：網絡裡自然地形成了哪些群組？

```cypher
CALL project_graph('Graph', ['account'], ['follows']);
CALL louvain('Graph')
RETURN louvain_id, COUNT(*) AS community_size
ORDER BY community_size DESC
LIMIT 10
```

**結果解讀**：louvain_id 相同 = 屬於同一個社群，社群內部連接更密集

---

# Algorithm 4：Weakly Connected Components

**問的問題**：整個圖裡有幾個獨立的連通塊？

```cypher
CALL project_graph('Graph', ['account'], ['follows']);
CALL weakly_connected_components('Graph')
RETURN group_id, COUNT(*) AS component_size
ORDER BY component_size DESC
LIMIT 10
```

**結果解讀**：group_id 相同 = 屬於同一個連通分量；最大的通常佔絕大多數

---

# Algorithm 5：Strongly Connected Components

**問的問題**：哪些節點互相可以到達對方？

```cypher
CALL project_graph('Graph', ['account'], ['follows']);
CALL strongly_connected_components('Graph')
RETURN group_id, COUNT(*) AS scc_size
ORDER BY scc_size DESC
LIMIT 10
```

**結果解讀**：group_id 相同 = 屬於同一個強連通分量，內部有循環路徑

---

# Algorithm 6：Shortest Paths

**問的問題**：節點 A 到節點 B 最短走幾跳？

```cypher
MATCH path = (a:account {ID: 45})
            -[:follows*1..3]->(b:account)
WHERE b.ID = 1036
RETURN a.ID AS source,
       b.ID AS target,
       length(path) AS hops
LIMIT 5
```

**結果解讀**：hops = 關注鏈的長度；越短 = 越相近

**類比**：Supply chain 版本是「X 到 Y 最少幾個零件中間商」

---

# 對比：Python 的做法

**Ladybug in-database**：
```cypher
CALL project_graph('Graph', ['account'], ['follows']);
CALL page_rank('Graph') RETURN node.ID, rank;
```
→ 兩行呼叫，資料不動

**Python + NetworkX**：
```python
import networkx as nx
edges = fetch_all_follows()      # 拉資料（幾百萬筆）
G = nx.DiGraph(edges)            # 建圖（記憶體吃緊）
scores = nx.pagerank(G)          # 計算
save_results_to_db(scores)       # 寫回
```
→ 四步，資料搬兩次，記憶體壓力大，耗時 5-10 分鐘

---

# 選型決策：從問題出發

**你想回答什麼問題？** → **選用哪個 Algorithm**

| 你的問題 | 選用方法 | 典型應用 |
|---------|--------|--------|
| A 到 B 的最短路徑？ | **Cypher 多跳查詢** | 推薦路徑、依賴關係 |
| 誰是最重要的節點？ | **PageRank** | 重要性排名、影響力 |
| 圖自然形成哪些群組？ | **Louvain** | 社群偵測、市場分群 |
| 圖有幾個獨立部分？ | **WCC** | 連通性分析、孤立檢測 |
| 哪些節點互相可達？ | **SCC** | 反饋迴路、強關聯性 |
| 最核心的高連結節點？ | **K-Core** | 樞紐節點、核心圈層 |

**思考方式**：先定義問題 → 看表格找算法 → 跑一行 query

---

# 小結

**六個 algorithm，對應三個問題**

| 問題類型 | Algorithm | 實現 |
|---------|-----------|------|
| 最重要節點 | PageRank | ALGO |
| 最重要節點 | K-Core | ALGO |
| 自然群組 | Louvain | ALGO |
| 連通性（弱） | WCC | ALGO |
| 連通性（強） | SCC | ALGO |
| 路徑查詢 | Shortest Paths | Cypher |

**in-database 有兩種實現方式**：
- Cypher 查詢：靈活，適合自訂邏輯
- ALGO extension：內建演算法，秒級執行

---

<!-- _class: lead -->

# 實作開始！

---

# 實作目標（40 min）

**把六個 algorithm 都跑一遍：**

1. ✅ PageRank → 找重要節點（ALGO）
2. ✅ K-Core → 找核心節點（ALGO）
3. ✅ Louvain → 找社群（ALGO）
4. ✅ WCC → 找弱連通分量（ALGO）
5. ✅ SCC → 找強連通分量（ALGO）
6. ✅ Shortest Paths → 查最短路徑（Cypher）

每個 algorithm 看結果、理解輸出、5–7 分鐘

---

# 實作提示 Part 1：載入資料

**準備**：schema.cypher、amazon-nodes.csv、amazon-edges.csv

**執行**：
```bash
# 建立表結構
lbug unit-3.lbug < schema.cypher

# 載入資料
lbug unit-3.lbug << EOF
COPY account(ID) FROM "amazon-nodes.csv";
COPY follows FROM "amazon-edges.csv";
EOF
```

**預期**：約 40 萬節點、340 萬邊（耗時 1-2 分鐘）

---

# 實作提示 Part 2：驗證 & 執行

**驗證資料已正確載入**：

```cypher
MATCH (a:account) RETURN COUNT(a) AS account_count
MATCH ()-[f:follows]->() RETURN COUNT(f) AS follows_count
```

預期：約 40 萬個 account，約 340 萬條 follows 關係

**載入 ALGO 擴展**：

```cypher
LOAD EXTENSION algo;
```

**按順序跑五個 algorithm**

每個算法的 query 在投影片上，直接複製貼上執行

遇到問題 → 舉手

---

# 你現在能做到

- ✅ 知道有六個圖論問題的常用解法
- ✅ 理解每個 algorithm 在解什麼問題
- ✅ 親手跑過一次，看到結果（40 萬節點的圖，秒級出結果）
- ✅ **知道選型依據**：什麼問題選什麼算法、什麼場景選 Cypher、什麼場景選 ALGO
- ✅ **明白 in-database 的價值**：資料不動，演算法進去 → 快速、省記憶體

**對比：如果用 Python + NetworkX**
- 拉 340 萬筆邊到應用層：網路 I/O + 轉換
- 建圖到記憶體：GC 壓力大
- 執行演算法：幾分鐘
→ 總耗時：可能 5-10 分鐘

**用 Ladybug in-database**：2-3 秒

下堂課：結果出來了，怎麼讓人看得懂它的推理過程？
