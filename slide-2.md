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
    font-size: 22px;
  }
  section.lead h1 {
    border-bottom: none;
    font-size: 48px;
    color: #1a1a2e;
  }
---

<!-- _class: lead -->

# Cypher：用結構描述問題

**Unit 2** | Graph Analysis Workshop

---

# 複習：Unit 1 的成果

```cypher
MATCH (a:Component)-[:DEPENDS_ON]->(b:Component)
RETURN a.name, b.name
```

這是一跳查詢。

**今天的問題**：如果要找三跳、四跳，怎麼寫？

---

# Cypher 的核心思想

**SQL 思維**：「我要 join 哪些欄位？」

```sql
SELECT c2.name FROM component c1
JOIN depends_on d ON c1.id = d.from_id
JOIN component c2 ON d.to_id = c2.id
WHERE c1.name = 'X'
```

**Cypher 思維**：「我要走哪條路？」

```cypher
MATCH (a:Component {name: 'X'})-[:DEPENDS_ON]->(b)
RETURN b.name
```

路徑反映了邏輯。

---

# SQL 使用者的三個認知轉換

| 你熟悉的 SQL | Cypher | 差在哪？ |
|-------------|--------|---------|
| `JOIN ... ON foreign_key` | pattern 直接描述關係 | 不需要指定 ON 條件 |
| `WITH RECURSIVE` | `[:REL*]` | 多跳只要加 `*` |
| `GROUP BY col` | 不需要寫 | RETURN 有聚合函數就自動 group |

這三個是最容易踩的坑，也是 Cypher 最省力的地方。

---

# 最值得記住的：多跳查詢

**SQL**：
```sql
WITH RECURSIVE upstream(id) AS (
  SELECT to_id FROM depends_on WHERE from_id = 'X'
  UNION ALL
  SELECT d.to_id FROM depends_on d JOIN upstream u ON d.from_id = u.id
)
SELECT name FROM component WHERE id IN (SELECT id FROM upstream)
```

**Cypher**：
```cypher
MATCH (a:Component {name: 'X'})-[:DEPENDS_ON*]->(b)
RETURN DISTINCT b.name
```

同一個問題，Cypher 少寫 80%。

---

# Cypher 語法：節點

```cypher
(variable:Label {property: value})
```

```cypher
(c:Component)                     // Component 節點，別名 c
(c:Component {name: 'CPU'})       // 指定屬性過濾
(c:Component {critical: true})    // 只找 critical 的零件
(c)                               // 任何節點（不限類型）
```

---

# Cypher 語法：關係

```cypher
(a)-[r:TYPE {property: value}]->(b)   // 有向
(a)-[r:TYPE]-(b)                      // 無向
(a)-[:TYPE]->(b)                      // 省略別名
(a)-->(b)                             // 省略類型
```

**Variable-length path**：

```cypher
(a)-[:DEPENDS_ON*1..3]->(b)   // 1 到 3 跳
(a)-[:DEPENDS_ON*]->(b)       // 任意跳數
(a)-[:DEPENDS_ON*3]->(b)      // 恰好 3 跳
```

---

# 一跳 vs 多跳

**一跳**：直接依賴
```cypher
MATCH (a:Component {name: 'X'})-[:DEPENDS_ON]->(b)
RETURN b.name
```

**多跳**：所有上游依賴（不限層數）
```cypher
MATCH (a:Component {name: 'X'})-[:DEPENDS_ON*]->(b)
RETURN DISTINCT b.name
```

同一個語法，`*` 讓 DB 自己走到底。

---

# 加上過濾條件

只看 critical 的依賴路徑：

```cypher
MATCH (a:Component {name: 'X'})
      -[:DEPENDS_ON*]->(b:Component)
WHERE b.critical = true
RETURN DISTINCT b.name
```

找供應商：哪些供應商供應了 X 的上游零件？

```cypher
MATCH (a:Component {name: 'X'})
      -[:DEPENDS_ON*]->(b:Component)
      <-[:SUPPLIES]-(s:Supplier)
RETURN DISTINCT s.name, b.name
ORDER BY s.name
```

---

# 同一個語法，換個 Dataset

從 Supply chain 換到 **Social Network dataset**

**問題類型一樣，語意不同**

```cypher
// Supply chain：找上游零件
MATCH (x:Component)-[:DEPENDS_ON*]->(b:Component)

// Social network：找追蹤鏈
MATCH (u:User {username: 'alice'})-[:FOLLOWS*1..2]->(v:User)
```

學 Cypher 一次，兩個 domain 都會用。

---

# MATCH 完整結構

```cypher
MATCH  (pattern)
WHERE  (conditions)
RETURN (projections)
ORDER BY (expressions)
LIMIT  (number)
```

**常見的 RETURN 技巧**：

```cypher
RETURN DISTINCT b.name          // 去重
RETURN b.name, COUNT(*) AS cnt  // 聚合
RETURN b                        // 整個節點
```

---

<!-- _class: lead -->

# 實作開始！

---

# 實作目標（30 min）

**逐步加深查詢能力：**

1. ✅ 一跳 → 多跳，加上 `*`
2. ✅ 加過濾條件，找 critical 路徑
3. ✅ 換 dataset，用 Social Network 跑同樣的語法

**成功指標**：
- 能自己修改 path pattern ✓
- 理解 `*1..3` 的意思 ✓
- 不是只能 copy paste ✓

---

# Step 1a：無限制多跳

Supply chain dataset，繼續用：

```cypher
// 找出 X 的所有上游依賴（不限層數）
MATCH (a:Component {name: 'X'})
      -[:DEPENDS_ON*]->(b:Component)
RETURN DISTINCT b.name
```

**預期結果**：
```
A, B, C, D, E
```
（5 個零件）

---

# Step 1b：控制跳數

**試試看**：
- 把 `*` 改成 `*1..1`（只看 1 跳）
  ```cypher
  MATCH (a:Component {name: 'X'})
        -[:DEPENDS_ON*1..1]->(b:Component)
  RETURN DISTINCT b.name
  ```
  預期結果：A, B, E（3 個）

- 把 `*` 改成 `*1..2`（只看 1-2 跳）
  ```cypher
  MATCH (a:Component {name: 'X'})
        -[:DEPENDS_ON*1..2]->(b:Component)
  RETURN DISTINCT b.name
  ```
  預期結果：A, B, C, D, E（5 個）

---

# Step 2（10 min）：加條件過濾

```cypher
// 只看 critical 的依賴路徑
MATCH (a:Component {name: 'X'})
      -[:DEPENDS_ON*]->(b:Component)
WHERE b.critical = true
RETURN DISTINCT b.name
```

```cypher
// 找上游供應商
MATCH (a:Component {name: 'X'})
      -[:DEPENDS_ON*]->(b:Component)
      <-[:SUPPLIES]-(s:Supplier)
RETURN DISTINCT s.name, b.name
ORDER BY s.name
```

**關鍵直覺**：多加一段 pattern，就是多走一跳。不需要 JOIN。

---

# Social Network Dataset 說明

**10 個 User**：alice, bob, carol, dave, eve, frank, grace, henry, iris, jack

**追蹤關係（18 條 FOLLOWS 邊）**：

```
alice    → bob, carol, dave
bob      → eve, frank
carol    → frank, grace
dave     → eve, iris
eve      → grace, henry
frank    → henry, jack
grace    → iris
henry    → jack, alice
iris     → bob
jack     → carol
```

---

# Step 3a（5 min）：一跳追蹤

載入 Workshop 提供的 Social Network dataset：

```bash
lbug unit-2.lbug < social-network.cypher
```

```cypher
// 一跳：alice 追蹤了誰？
MATCH (u:User {username: 'alice'})-[:FOLLOWS]->(v:User)
RETURN v.username
```

**預期結果**：
```
bob
carol
dave
```

---

# Step 3b（5 min）：兩跳追蹤鏈

```cypher
// 兩跳：追蹤鏈延伸
MATCH (u:User {username: 'alice'})-[:FOLLOWS*1..2]->(v:User)
WHERE v <> u
RETURN DISTINCT v.username
LIMIT 20
```

**預期結果**：
```
bob
carol
dave
eve
frank
grace
iris
```

---

# 檢查點

你現在能做到：

- ✅ 讀懂一個 Cypher path pattern，看出「我要走哪條路」
- ✅ 用 `*` 控制跳數（`*1..1` 一跳、`*1..2` 兩跳、`*` 無限制）
- ✅ 加 `WHERE` 過濾中間節點的屬性（比如 `critical = true`）
- ✅ 把學到的語法套到新的 dataset，同一個邏輯兩個領域都用

**核心直覺**：Cypher 語法反映了你要找的路，不需要 JOIN、不需要 recursive CTE。

下堂課：不手寫查詢，讓 DB 直接跑演算法

---

# 延伸：Ladybug 官方 Dataset

有興趣的學員可以自行下載來玩（課後）：

**① tinysnb（小型社交網路，含 Person / Knows）**
適合快速試玩 Unit 2 的 multi-hop 查詢，全部 CSV 加起來 < 20 KB，下載後 1 秒就能跑

```bash
# schema + data 各自下載
curl -O https://raw.githubusercontent.com/LadybugDB/dataset/main/tinysnb/schema.cypher
curl -O https://raw.githubusercontent.com/LadybugDB/dataset/main/tinysnb/vPerson.csv
curl -O https://raw.githubusercontent.com/LadybugDB/dataset/main/tinysnb/eKnows.csv
```

**② Amazon co-purchase graph（SNAP amazon0601）**
真實電商資料，約 40 萬節點、340 萬條邊，schema 為 `Product / CO_PURCHASED`
→ **Unit 3 會用這個 dataset 跑 in-database 演算法**，所以提前了解規模

```bash
curl -O https://raw.githubusercontent.com/LadybugDB/dataset/main/snap/amazon0601/csv/schema.cypher
curl -O https://raw.githubusercontent.com/LadybugDB/dataset/main/snap/amazon0601/csv/amazon-nodes.csv
curl -O https://raw.githubusercontent.com/LadybugDB/dataset/main/snap/amazon0601/csv/amazon-edges.csv  # ~48 MB
```
