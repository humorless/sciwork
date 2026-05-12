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

# 複習：Graph 的三個元素

```
(User) -[WATCHED {rating: 5}]-> (Movie)
  ↑         ↑                      ↑
 節點     關係（有屬性）          節點
```

**上堂課的成果**：
- ✅ 安裝了 Ladybug
- ✅ 載入了 MovieLens 數據
- ✅ 看到了第一個查詢結果

**今天的問題**：怎樣寫更複雜的查詢？

---

# Cypher：Graph 的查詢語言

**Cypher = 視覺即代碼**

你看到什麼，就寫什麼

```cypher
# 人看圖
(User A) -[WATCHED]-> (Movie)

# 人寫代碼（Cypher）
(u:User {id: 'A'}) -[r:WATCHED]-> (m:Movie)

# 完整查詢
MATCH (u:User {id: 'A'}) -[r:WATCHED]-> (m:Movie)
RETURN m.title, r.rating
```

---

# SQL vs Cypher：思維方式

**SQL 思維**：「我要哪些欄位？」
```sql
SELECT u2.id, COUNT(*) as cnt
FROM rating r1 JOIN rating r2 ON ...
WHERE r1.user_id = 'A'
```
→ 邏輯隱藏在 JOIN 和 WHERE 裡

**Cypher 思維**：「我要走哪條路？」
```cypher
MATCH (u:User {id: 'A'}) 
      -[r1:RATED]-> (m:Movie)
      <- [r2:RATED] - (u2:User)
RETURN u2.id
```
→ 邏輯就是路徑本身

---

# Cypher 基本語法 #1：節點表示

**模式**
```cypher
(variable:Label {property: value})
```

**範例**
```cypher
(u:User)              # User 類型的節點，別名 u
(m:Movie)             # Movie 類型的節點，別名 m
(u:User {id: 'A'})   # id 為 'A' 的 User
(m:Movie {year: 2010}) # 2010 年的電影
```

**簡化寫法**
```cypher
(u)                   # 任何節點，別名 u（不指定類型）
(m:Movie)             # 任何 Movie，但不起別名也行
```

---

# Cypher 基本語法 #2：關係表示

**模式**
```cypher
(n1) -[variable:TYPE {property: value}]-> (n2)
  ↑                                           ↑
 起點                                        終點
```

**方向性**
```cypher
(u) -[r:WATCHED]-> (m)    # u 看過 m（單向）
(u) <- [r:WATCHED] - (m)  # m 被 u 看過（反向）
(u) - [r:WATCHED] - (m)   # u 和 m 有 WATCHED 關係（雙向）
```

**無屬性簡化**
```cypher
(u) -[:WATCHED]-> (m)     # 省略關係別名
(u) --> (m)               # 省略關係類型
```

---

# Cypher 完整示例：一跳查詢

**問題**：User A 看過哪些電影？

```cypher
MATCH (u:User {id: 'A'}) -[r:WATCHED]-> (m:Movie)
RETURN m.title, r.rating
ORDER BY r.rating DESC
```

**執行步驟**：
1. 找到 id 為 'A' 的 User 節點
2. 沿著 WATCHED 邊走到 Movie 節點
3. 返回電影名稱和評分
4. 按評分降序排列

---

# Pattern #2：多跳查詢

**問題**：User A 的朋友看過哪些電影？

```cypher
MATCH (u:User {id: 'A'}) 
      -[:WATCHED]-> (m:Movie)
      <- [:WATCHED] - (u2:User)
RETURN DISTINCT u2.id, u2.name
LIMIT 5
```

**執行步驟**：
1. 找 User A
2. 找 A 看過的所有電影
3. 反向走，找看過同樣電影的其他用戶
4. 返回這些用戶

**直觀理由**：看過同樣電影的人 = 朋友（品味相似）

---

# Pattern #3：加上篩選條件

**問題**：User A 給 4 星以上評分的電影，還有誰也看過？

```cypher
MATCH (u:User {id: 'A'}) 
      -[r1:WATCHED {rating: 4}]-> (m:Movie)
      <- [r2:WATCHED] - (u2:User)
WHERE r1.rating >= 4 AND r2.rating >= 4
RETURN m.title, u2.id, u2.name
ORDER BY m.title
```

**新概念**：
- `WHERE` 子句：額外的篩選邏輯
- `ORDER BY`：排序結果
- `DISTINCT`：去重

---

# 為什麼 Cypher 更直觀？

**視覺對應**

| 圖示 | 代碼 | 直觀性 |
|------|------|--------|
| `(A) -[WATCHED]-> (B)` | `MATCH (a) -[:WATCHED]-> (b)` | ⭐⭐⭐⭐⭐ |
| 多層 JOIN | `... JOIN ... ON ... JOIN ...` | ⭐ |

**好處**
- 查詢即路徑，路徑即查詢
- 多跳查詢不需要額外 JOIN
- 結構關係一目瞭然

---

# Cypher MATCH 完整結構

```cypher
MATCH (pattern)
WHERE (conditions)
RETURN (projections)
ORDER BY (expressions)
LIMIT (number)
```

**各部分的作用**
- `MATCH`：找符合模式的子圖
- `WHERE`：進一步篩選結果
- `RETURN`：選擇要返回的列
- `ORDER BY`：排序
- `LIMIT`：限制返回數量

---

# 實作先睹為快

今天實作的流程：

1. **簡單查詢**：找出 User A 的直接鄰居
2. **多跳查詢**：找出鄰居的鄰居
3. **加條件**：只看評分 4 星以上的

每一步你都會自己改代碼，不是只 copy paste。

---

# 小結

**Cypher 的核心思想**

- 🔍 **視覺即代碼**：查詢就像畫路線
- 🎯 **多跳不需 JOIN**：直接沿邊走
- 📊 **結構清晰**：邏輯關係一目瞭然

**下一步**：在實作中體驗多跳查詢的威力

---

<!-- _class: lead -->

# 實作開始！

---

# 實作目標（40 mins）

**逐步加深 query 能力：**

1. ✅ 一跳查詢：找直接鄰居
2. ✅ 多跳查詢：找鄰居的鄰居
3. ✅ 加條件查詢：篩選評分

**成功指標**：
- 能自己修改 WHERE 條件 ✓
- 理解多跳查詢的邏輯 ✓
- 不是只能 copy paste ✓

---

# 實作流程

**Step 1（10 min）**：一跳 - 直接鄰居
```cypher
# User A 看過的電影
MATCH (u:User {id: 'A'}) -[r:WATCHED]-> (m:Movie)
RETURN m.title, r.rating

# 改成：找看過同樣電影的其他用戶
MATCH (u:User {id: 'A'}) 
      -[:WATCHED]-> (m:Movie)
      <- [:WATCHED] - (u2:User)
WHERE u2.id != 'A'
RETURN DISTINCT u2.id, u2.name
```

**Step 2（15 min）**：多跳 - 鄰居的鄰居
```cypher
# 找鄰居看過但 A 沒看過的電影
MATCH (u:User {id: 'A'})
      -[:WATCHED]-> (m1:Movie)
      <- [:WATCHED] - (u2:User)
      -[:WATCHED]-> (m2:Movie)
WHERE NOT (u) -[:WATCHED]-> (m2)
RETURN m2.title, COUNT(*) as recommendations
```

**Step 3（10 min）**：加條件 - 評分篩選
```cypher
# 只看評分 4 星以上的推薦
MATCH (u:User {id: 'A'})
      -[r1:WATCHED {rating: 4}]-> (m1:Movie)
      <- [r2:WATCHED {rating: 4}] - (u2:User)
      -[r3:WATCHED]-> (m2:Movie)
WHERE r3.rating >= 4
RETURN m2.title, COUNT(*) as count
ORDER BY count DESC
LIMIT 10
```

**Step 4（5 min）**：自己嘗試
- 改成找其他用戶（例如 User B）
- 改成更高的評分門檻
- 加上時間條件（optional）

---

# 檢查點

**你現在能做到**：
- ✅ 讀懂一個 Cypher query
- ✅ 改數字和條件
- ✅ 理解多跳的含義

下堂課，我們讓 DB 自己算推薦，而不是手寫 query！
