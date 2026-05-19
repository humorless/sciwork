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

# In-database 計算：Algorithm Tour

**Unit 3** | Graph Analysis Workshop

---

# 傳統做法的問題

```
DB ──► 拉資料到 Application ──► Python / NetworkX 計算 ──► 寫回 DB
         (幾百萬筆)                  (慢、記憶體吃緊)
```

**痛點**：
- 網路 I/O 是瓶頸
- 資料在記憶體裡要轉換格式
- 資料量一大，流程就崩

---

# In-database 計算

```
DB ──► 演算法直接在 DB 裡跑 ──► 回傳結果（已聚合）
```

**核心邏輯：資料不動，演算法進去**

好處：
- 減少網路傳輸
- 利用 DB 的原生加速（columnar + vectorized）
- 計算結果遠小於原始資料

---

# Ladybug 的六個 Graph Algorithms

| Algorithm | 解決的問題 |
|-----------|-----------|
| Shortest Paths | A 到 B 最短走幾步？ |
| PageRank | 誰是網絡裡最重要的節點？ |
| Louvain | 圖裡自然地形成了哪些群組？ |
| Weakly Connected Components | 整個圖有幾個獨立的連通塊？ |
| Strongly Connected Components | 哪些節點互相可以到達對方？ |
| K-Core Decomposition | 最密集連接的核心子圖是哪些？ |

---

# 今天的實作方式

**Dataset**：Amazon product co-purchase graph

每個 algorithm 花 **5–7 分鐘**：
1. 看一句話說明：這個 algorithm 在解什麼問題
2. 跑一個指令
3. 看結果，理解輸出的意義

目標是**建立選型直覺**，不是深入原理

---

# Algorithm 1：Shortest Paths

**問的問題**：商品 A 到商品 B，最短的共同購買路徑是什麼？

```cypher
CALL algo.shortestPath(
  {startNode: 'B0001', endNode: 'B0099'}
) YIELD path, cost
RETURN [n IN nodes(path) | n.title] AS path, cost
```

**結果解讀**：路徑上的商品 = 購買鏈中的中間站

**類比**：Supply chain 版本是「X 到 Y 最少幾個中間零件」

---

# Algorithm 2：PageRank

**問的問題**：哪些商品是整個網絡的樞紐？（被最多人帶動購買）

```cypher
CALL algo.pageRank()
YIELD nodeId, score
MATCH (p:Product) WHERE id(p) = nodeId
RETURN p.title, score
ORDER BY score DESC
LIMIT 10
```

**結果解讀**：score 越高 = 越多其他商品「指向」它（co-purchase）

**類比**：Supply chain 版本是「哪個零件最多人依賴」

---

# Algorithm 3：Louvain（Community Detection）

**問的問題**：這個 co-purchase 網絡裡，自然地形成了哪些「品味群」？

```cypher
CALL algo.louvain()
YIELD nodeId, community
MATCH (p:Product) WHERE id(p) = nodeId
RETURN community, COLLECT(p.title)[..5] AS sample_products, COUNT(*) AS size
ORDER BY size DESC
LIMIT 10
```

**結果解讀**：同一個 community 的商品，傾向被同一批人購買

---

# Algorithm 4：Weakly Connected Components

**問的問題**：整個圖裡有幾個獨立的購買圈？（彼此完全沒有交集）

```cypher
CALL algo.wcc()
YIELD nodeId, componentId
RETURN componentId, COUNT(*) AS size
ORDER BY size DESC
LIMIT 10
```

**結果解讀**：最大的 component 通常佔絕大多數；小的 component 是孤立產品群

---

# Algorithm 5：Strongly Connected Components

**問的問題**：哪些商品互相帶動購買（A→B 且 B→A）？

```cypher
CALL algo.scc()
YIELD nodeId, componentId
MATCH (p:Product) WHERE id(p) = nodeId
RETURN componentId, COLLECT(p.title)[..5] AS products, COUNT(*) AS size
ORDER BY size DESC
LIMIT 5
```

**結果解讀**：SCC 內的商品形成「買了就會互相推薦的循環」

---

# Algorithm 6：K-Core Decomposition

**問的問題**：最核心的高度互連商品群是哪些？

```cypher
CALL algo.kCore()
YIELD nodeId, coreValue
MATCH (p:Product) WHERE id(p) = nodeId
RETURN p.title, coreValue
ORDER BY coreValue DESC
LIMIT 10
```

**結果解讀**：coreValue 越高 = 與越多其他商品互相連接

---

# 對比：Python 的做法

**Ladybug in-database**：
```cypher
CALL algo.pageRank() YIELD nodeId, score ...
```
→ 一行呼叫，DB 直接算

**Python + NetworkX**：
```python
import networkx as nx
G = fetch_all_edges_from_db()   # 拉資料（可能幾百萬筆）
G_nx = nx.DiGraph(G)            # 建圖（記憶體）
scores = nx.pagerank(G_nx)      # 計算
save_back_to_db(scores)         # 寫回
```
→ 四步，資料搬兩次，記憶體壓力大

---

# 小結

**六個 algorithm，六種問法**

| 問題類型 | Algorithm |
|---------|-----------|
| 最短路徑 | Shortest Paths |
| 重要性排名 | PageRank |
| 自然群組 | Louvain |
| 連通性（弱） | WCC |
| 連通性（強） | SCC |
| 核心密度 | K-Core |

**in-database = 一行呼叫，資料不動**

---

<!-- _class: lead -->

# 實作開始！

---

# 實作目標（40 min）

**把六個 algorithm 都跑一遍：**

1. ✅ Shortest Paths → 找路徑
2. ✅ PageRank → 找重要商品
3. ✅ Louvain → 找品味群
4. ✅ WCC / SCC → 找連通塊
5. ✅ K-Core → 找核心商品

每個 algorithm 看結果、理解輸出、5–7 分鐘

---

# 實作提示

載入 Amazon co-purchase graph（講者提供）：

```bash
ladybug load amazon-co-purchase.parquet
```

確認節點數量：

```cypher
MATCH (p:Product) RETURN COUNT(p)
MATCH ()-[r:CO_PURCHASED]->() RETURN COUNT(r)
```

接著按順序跑六個 algorithm（投影片上的 query 直接複製）

遇到問題 → 舉手

---

# 你現在能做到

- ✅ 知道 Ladybug 有哪六個內建 algorithm
- ✅ 理解每個 algorithm 在解什麼問題
- ✅ 親手跑過一次，看到結果
- ✅ 知道什麼情況應該選哪個

下堂課：結果出來了，怎麼讓人看得懂它的推理過程？
