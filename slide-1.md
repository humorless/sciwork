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

# Graph 是什麼？為什麼不用 SQL 就好

**Unit 1** | Graph Analysis Workshop | 4 小時

---

# 今天要解決的問題

**情景：推薦相似用戶**

你有一個電影推薦系統

- 👤 用戶表：User
- 📽️ 電影表：Movie
- ⭐ 評分表：Rating

**關鍵問題**：給定 User A，找出跟他品味最相似的 5 個人

---

# 用 SQL 怎樣解？

```sql
SELECT u2.id, u2.name, COUNT(*) as common_high_rated
FROM rating r1
JOIN rating r2 ON r1.movie_id = r2.movie_id 
                  AND r1.rating >= 4 AND r2.rating >= 4
JOIN user u1 ON r1.user_id = u1.id
JOIN user u2 ON r2.user_id = u2.id
WHERE u1.id = 'User A' AND u2.id != u1.id
GROUP BY u2.id, u2.name
ORDER BY common_high_rated DESC
LIMIT 5
```

**感受**：JOIN 層層堆疊，邏輯難以理解

---

# SQL 的痛點

| 痛點 | 影響 |
|------|------|
| 隱式關係 | 關係被埋在 WHERE && JOIN 裡 |
| 運算開銷 | 多重的 JOIN ，效能差 |
| 不易修改 | 加一個新欄位，要 schema migration |

---

# Graph Model：換個角度看

**不是「我要哪些欄位」，而是「我看到了什麼結構」**

```
User A 👤
  ├─ 看過 → Movie 1 ⭐⭐⭐⭐⭐
  ├─ 看過 → Movie 2 ⭐⭐⭐⭐⭐
  └─ 看過 → Movie 3 ⭐⭐⭐⭐

User B 👤
  ├─ 看過 → Movie 1 ⭐⭐⭐⭐⭐
  ├─ 看過 → Movie 2 ⭐⭐⭐⭐⭐
  └─ 看過 → Movie 4 ⭐⭐⭐
```

A 和 B 都喜歡同樣的電影 → **他們可能品味相似**

---

# 三個元素 #1：節點 (Node)

**節點 = 實體物件**

```
(User {id: 'A', name: 'Alice', age: 30})
(Movie {id: '1', title: 'Inception', year: 2010})
```

什麼可以是節點？
- 用戶、電影、商品
- 地點、事件、組織
- **標準**：有獨立身份和屬性的東西

---

# 三個元素 #2：關係 (Relationship)

**關係 = 有向、有類型的連接**

```
(User A) -[WATCHED]-> (Movie 1)
(User A) -[RATED {score: 5}]-> (Movie 1)
(User A) -[SIMILAR_TO {score: 0.92}]-> (User B)
```

特點：
- 🔀 **有方向**：A → B 和 B ← A 含義不同
- 🏷️ **有類型**：WATCHED、RATED、SIMILAR_TO 等
- 📊 **可有屬性**：邊本身也能存數據（評分、時間、相似度）

---

# 三個元素 #3：屬性 (Property)

**屬性 = 節點或關係的詳細信息**

```
(User: {
  id: 'A',
  name: 'Alice',
  age: 30,
  country: 'Taiwan'
})
-[RATED {
  score: 5,
  timestamp: '2024-01-15',
  comment: 'Amazing!'
}]->
(Movie: {
  id: '1',
  title: 'Inception',
  year: 2010,
  director: 'Nolan'
})
```

---

# 核心主張 #1：關係是一等公民

**在 Graph DB，關係和節點同等重要**

| RDBMS | Graph 數據庫 |
|----------|----------|
| 關係 = 外鍵 | 關係 = 一等公民 |
| 關係是隱式的 | 關係是顯式的 |
| JOIN 是查詢時的成本 | 關係是預存的結構 |

**好處**：查詢不需要 JOIN，直接沿著邊走

---

# 核心主張 #2：結構即語義

**Graph 的形狀本身就在講故事**

看 Graph 的結構就能理解：
- 哪些節點之間有連接
- 連接的類型和強度
- 潛在的推理路徑

> **人能看懂的結構 = 機器能查詢的路徑**

---

# 為什麼這很重要？

這兩個特性奠定了接下來三堂課的基礎：

1. **Cypher 查詢**：直接沿著邊走，查詢像畫地圖
2. **In-database 計算**：演算法直接跑在 DB 裡，不搬資料
3. **可解釋性**：結構本身就是解釋，人能看懂推薦理由

---

# 工具與數據集

**Ladybug DB**
- 開源 Graph 數據庫
- 原生支持 Cypher 查詢
- 支持 in-database 計算
- 輕量易上手

**MovieLens 數據集**
- 6,000+ 用戶 | 5,000+ 電影 | 100,000+ 評分
- 大到足以展示複雜度，小到足以本地跑

---

# 小結

**三個要點**

1. 📍 **Graph = 節點 + 關係 + 屬性**
2. 🔀 **關係是一等公民** → 查詢快速直接
3. 👁️ **結構即語義** → 人能看懂推理過程

**下一步**：怎樣用代碼描述這些關係？

---

<!-- _class: lead -->

# 實作開始！

---

# 實作目標（40 mins）

**這一段你會完成：**

1. ✅ 安裝 Ladybug、建立連線
2. ✅ 載入 MovieLens 數據到 Graph
3. ✅ 跑第一個查詢：「找出 User A 看過的電影」
4. ✅ 理解節點、關係、屬性的概念

**成功指標**：
- 能連上 Ladybug ✓
- 數據載入完成 ✓
- Query 跑出結果 ✓

---

# 實作步驟

**Phase 1（5 min）**：環境設定
```bash
# 安裝並連接 Ladybug
ladybug connect localhost
```

**Phase 2（15 min）**：載入數據
```cypher
# 導入 Users、Movies、Ratings
LOAD CSV FROM 'movielens/users.csv' 
AS row CREATE (u:User {id: row.id, name: row.name})
```

**Phase 3（15 min）**：跑第一個 query
```cypher
MATCH (u:User {id: 'A'}) -[r:WATCHED]-> (m:Movie)
RETURN m.title, r.rating ORDER BY r.rating DESC
```

**Phase 4（5 min）**：自己嘗試修改

---

# 檢查點

跑出來的樣子會像這樣：

```
m.title           r.rating
────────────────  ────────
Inception         5
Interstellar      5
The Matrix        4
...
```

✅ 看到結果 → 成功！
❌ 出錯？ → 舉手，我來巡場

下堂課，我們學怎樣寫更複雜的 query！
