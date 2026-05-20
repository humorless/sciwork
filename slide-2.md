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

**SQL 思維**：「我要哪些欄位？」

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

路徑寫出來，邏輯就在裡面。

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
(c:Component)                     -- Component 節點，別名 c
(c:Component {name: 'CPU'})       -- 指定屬性過濾
(c:Component {critical: true})    -- 只找 critical 的零件
(c)                               -- 任何節點（不限類型）
```

---

# Cypher 語法：關係

```cypher
(a)-[r:TYPE {property: value}]->(b)   -- 有向
(a)-[r:TYPE]-(b)                      -- 無向
(a)-[:TYPE]->(b)                      -- 省略別名
(a)-->(b)                             -- 省略類型
```

**Variable-length path**：

```cypher
(a)-[:DEPENDS_ON*1..3]->(b)   -- 1 到 3 跳
(a)-[:DEPENDS_ON*]->(b)       -- 任意跳數
(a)-[:DEPENDS_ON*3]->(b)      -- 恰好 3 跳
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

從 Supply chain 換到 **Amazon product co-purchase graph**

**問題類型一樣，語意不同**

```cypher
-- Supply chain：找上游零件
MATCH (x:Component)-[:DEPENDS_ON*]->(b:Component)

-- Amazon：找共同購買鏈
MATCH (x:Product)-[:CO_PURCHASED*1..2]->(b:Product)
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
RETURN DISTINCT b.name          -- 去重
RETURN b.name, COUNT(*) AS cnt  -- 聚合
RETURN b                        -- 整個節點
```

---

<!-- _class: lead -->

# 實作開始！

---

# 實作目標（30 min）

**逐步加深查詢能力：**

1. ✅ 一跳 → 多跳，加上 `*`
2. ✅ 加過濾條件，找 critical 路徑
3. ✅ 換 dataset，用 Amazon co-purchase 跑同樣的語法

**成功指標**：
- 能自己修改 path pattern ✓
- 理解 `*1..3` 的意思 ✓
- 不是只能 copy paste ✓

---

# Step 1（10 min）：多跳查詢

Supply chain dataset，繼續用：

```cypher
-- 找出 X 的所有上游依賴（不限層數）
MATCH (a:Component {name: 'X'})
      -[:DEPENDS_ON*]->(b:Component)
RETURN DISTINCT b.name
```

**試試看**：
- 把 `*` 改成 `*1..2`，結果有什麼不同？
- 換另一個起點零件

---

# Step 2（10 min）：加條件過濾

```cypher
-- 只看 critical 的依賴路徑
MATCH (a:Component {name: 'X'})
      -[:DEPENDS_ON*]->(b:Component)
WHERE b.critical = true
RETURN DISTINCT b.name
```

```cypher
-- 找上游供應商
MATCH (a:Component {name: 'X'})
      -[:DEPENDS_ON*]->(b:Component)
      <-[:SUPPLIES]-(s:Supplier)
RETURN DISTINCT s.name, b.name
ORDER BY s.name
```

**關鍵直覺**：多加一段 pattern，就是多走一跳。不需要 JOIN。

---

# Step 3（10 min）：換 Amazon Dataset

載入 Amazon co-purchase graph（講者提供），跑同樣結構的 query：

```cypher
-- 買了這個產品的人，還買了什麼？（一跳）
MATCH (p:Product {id: 'B000F83...'})-[:CO_PURCHASED]->(q:Product)
RETURN q.title, q.category
LIMIT 10
```

```cypher
-- 兩跳：買了 → 還買了 → 還買了什麼
MATCH (p:Product {id: 'B000F83...'})-[:CO_PURCHASED*1..2]->(q:Product)
RETURN DISTINCT q.title
LIMIT 20
```

**注意**：語法完全一樣，只是節點類型和關係名稱不同。

---

# 檢查點

你現在能做到：

- ✅ 讀懂一個 Cypher path pattern
- ✅ 用 `*` 控制跳數
- ✅ 加 `WHERE` 過濾中間節點的屬性
- ✅ 把學到的語法套到新的 dataset

下堂課：不手寫查詢，讓 DB 直接跑演算法
