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

# In-database 計算：讓 DB 跑演算法

**Unit 3** | Graph Analysis Workshop

---

# 複習：前兩堂課

**Unit 1**：Graph = 節點 + 關係 + 屬性
**Unit 2**：Cypher 可以寫複雜的多跳查詢

**但有個問題**：
- User A 看過 100 部電影
- 系統有 1000 個用戶
- 每部電影都有評分

手寫查詢找所有相似用戶？**計算量爆炸**

---

# 傳統做法的痛點

```
Database          Application         Database
   ↓                  ↓                   ↓
SELECT ...    →   拉 100 萬筆資料    →   計算推薦
              →   (NetworkX/Python)   →   寫回去
              
網路傳輸開銷高
應用層計算慢
資料往返 2 次
```

**實際成本**：
- 網路 I/O：可能是瓶頸
- 應用層計算：加載、轉換、演算法
- 內存占用：100 萬筆資料進內存

---

# 核心主張：In-database 計算

**資料不動，演算法進去**

```
         Database
              ↓
     (演算法直接跑在 DB)
              ↓
      返回計算結果
      (遠小於原始資料)
```

**優勢**
- ✅ 減少網路傳輸
- ✅ 利用 DB 的原生加速
- ✅ 計算結果已經聚合

---

# 為什麼 Graph DB 適合 in-database 計算？

**Graph 結構天生適合演算法**

```
演算法需要：
  ✓ 遍歷邊
  ✓ 跳轉節點
  ✓ 累積狀態

Graph DB 提供：
  ✓ 邊已經預存（不需要 JOIN）
  ✓ 跳轉很快（直接指針）
  ✓ 狀態累積容易（沿路走）
```

**常見演算法**
- **Shortest Path**：最短路徑（導航、推薦）
- **PageRank**：影響力排序（排名、重要性）
- **Collaborative Filtering**：協同過濾（推薦）

---

# Collaborative Filtering（協同過濾）

**思想**：品味相似的人傾向喜歡相同的東西

```
User A 給 {Movie 1, 2, 3} 打 5 星
User B 給 {Movie 1, 2, 3} 打 5 星
User B 還給 {Movie 4} 打 5 星

→ 推薦 Movie 4 給 User A
```

**在傳統系統的做法**
```python
# 拉資料出來
users_ratings = get_all_ratings()  # 100 萬筆

# 計算相似度
similarity = cosine_similarity(user_A, user_B)

# 過濾和推薦
recommendations = filter_movies(users_ratings)

# 寫回 DB
save_recommendations(recommendations)
```

**複雜、慢、容易出錯**

---

# Collaborative Filtering 在 Graph 上

**Graph 的視角**

```
User A    User B
  ↓         ↓
 ⭐ Movie 1 ⭐
 ⭐ Movie 2 ⭐
 ⭐ Movie 3 ⭐
           ⭐ Movie 4
```

**In-database 的查詢**
```cypher
MATCH (u:User {id: 'A'}) -[r1:RATED {score: 5}]-> (m:Movie)
      <- [r2:RATED {score: 5}] - (u2:User)
      -[r3:RATED {score: 5}]-> (m2:Movie)
WHERE m != m2
RETURN m2.title, COUNT(*) as vote_count
ORDER BY vote_count DESC
LIMIT 10
```

**一句話完成** ← 演算法直接跑在 DB 裡

---

# Collaborative Filtering 推薦流程

**步驟 1**：找品味相似的人
```cypher
MATCH (u1:User {id: 'A'}) -[:RATED]-> (m) <- [:RATED] - (u2:User)
RETURN u2.id, COUNT(*) as similarity
ORDER BY similarity DESC
LIMIT 5
```

**步驟 2**：找他們看過但你沒看過的電影
```cypher
MATCH (u1:User {id: 'A'})
MATCH (u2:User) WHERE u2 IN similar_users
MATCH (u2) -[r:RATED {score: 4}]-> (m:Movie)
WHERE NOT (u1) -[:RATED]-> (m)
RETURN m.title, COUNT(*) as recommendations
```

**步驟 3**：排序推薦
```cypher
ORDER BY recommendations DESC, m.popularity DESC
LIMIT 10
```

---

# Demo Project：這就是你會做的

**今天的實作項目**：

在 MovieLens 上跑 Collaborative Filtering

```cypher
MATCH (user:User {id: 'A'})
      -[:RATED {score: 4}]->(movie)
      <-[:RATED {score: 4}]-(similar:User)
      -[r:RATED]->(reco:Movie)
WHERE r.score > 3 AND NOT (user)-[:RATED]->(reco)
RETURN reco.title, COUNT(*) as vote, AVG(r.score) as avg_rating
ORDER BY vote DESC, avg_rating DESC
LIMIT 10
```

**這個查詢做了什麼**：
1. 找 User A
2. 找他評分 4+ 的電影
3. 找看過同樣電影的其他用戶
4. 找他們看過但 A 沒看過的高分電影
5. 按投票數和平均評分排序

**結果**：User A 的推薦清單

---

# In-database 計算的優勢總結

| 傳統做法 | In-database |
|---------|-----------|
| 拉資料到應用層 | 資料留在 DB |
| Python/Java 計算 | DB 原生演算法 |
| 計算結果多 | 計算結果少（已聚合） |
| 網路往返多 | 網路往返少 |
| 難以維護 | 查詢即邏輯 |

**性能差異**（實際數據）：
- 傳統：3-5 秒（含網路和轉換）
- In-database：50-200 毫秒（只算演算法）

---

# 小結

**三個要點**

1. 📊 **資料不動，演算法進去** → 減少傳輸
2. 🔄 **Graph 天生適合演算法** → 利用原生加速
3. 🎯 **一句 query = 完整推薦邏輯** → 簡潔且快速

**下堂課**：推薦出來了，但為什麼推薦這個？（可解釋性）

---

<!-- _class: lead -->

# 實作開始！

---

# 實作目標（40 mins）

**跑完整的協同過濾推薦：**

1. ✅ 跑 CF 推薦 query
2. ✅ 看到結果（前 10 部推薦電影）
3. ✅ 對比：Python 做法會多複雜？

**成功指標**：
- 看到推薦清單 ✓
- 理解 query 邏輯 ✓
- 感受 in-database 的簡潔性 ✓

---

# 實作步驟

**Step 1（5 min）**：基礎 CF 查詢
```cypher
# 找品味相似的人
MATCH (u:User {id: 'A'})
      -[:RATED {score: 4}]-> (m)
      <- [:RATED {score: 4}] - (similar:User)
RETURN similar.id, similar.name, COUNT(*) as similarity
ORDER BY similarity DESC
LIMIT 5
```

**Step 2（15 min）**：推薦查詢
```cypher
# 協同過濾推薦
MATCH (user:User {id: 'A'})
      -[:RATED {score: 4}]->(movie)
      <-[:RATED {score: 4}]-(similar:User)
      -[r:RATED]->(reco:Movie)
WHERE r.score > 3 AND NOT (user)-[:RATED]->(reco)
RETURN reco.title, COUNT(*) as votes, AVG(r.score) as avg_score
ORDER BY votes DESC, avg_score DESC
LIMIT 10
```

**Step 3（15 min）**：理解與對比
- 修改用戶 ID（試試其他用戶）
- 修改評分閾值（4 星 → 5 星 → 3 星）
- 想像：用 Python 做這個需要多少行代碼？

**Step 4（5 min）**：自由探索
- 試試不同的相似度定義
- 試試加上年份篩選（只推薦新電影）
- 試試限制相似用戶數量

---

# 檢查點

預期的結果樣貌：

```
reco.title          votes   avg_score
─────────────────   ─────   ─────────
The Dark Knight     5       4.8
Forrest Gump        4       4.6
Interstellar        3       4.7
...
```

✅ 看到推薦清單 → 成功！
❌ 沒有結果？ → 舉手，我來幫忙

下堂課，我們解釋這些推薦為什麼是對的！
