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

# 可解釋性：為什麼這個推薦是對的？

**Unit 4** | Graph Analysis Workshop

---

# 複習：三堂課的進展

1. **Unit 1**：Graph 是什麼 → 結構即語義
2. **Unit 2**：怎樣查詢 → 用 Cypher 寫路徑
3. **Unit 3**：怎樣計算 → 演算法在 DB 裡跑

**現在的問題**：推薦結果出來了，但為什麼推薦「這個」？

---

# 問題：黑箱推薦

**GenAI 推薦**
```
User Input
    ↓
[Neural Network]
    ↓
Recommendation (But... why?)
```

**用戶的疑問**：
- 這是什麼電影？
- 為什麼推薦給我？
- 我能信任這個推薦嗎？

**答案**：一個機率，沒有解釋

---

# Graph 推薦：路徑透明

**推薦路徑**
```
You (User A)
  ↓ 都看過並喜歡
Movie 1, Movie 2, Movie 3 (你喜歡的電影)
  ↓ 還有人也看過
User B, User C, User D (品味相似的人)
  ↓ 他們都給 5 星
Movie X (推薦)

推薦理由：你和 User B、C、D 品味相似，
他們都喜歡 Movie X，所以推薦給你
```

**用戶能理解**：有具體的人、具體的電影、具體的理由

---

# 可解釋性來自結構：具體例子

**Graph 視角：路徑**

```cypher
MATCH (user:User {id: 'A'}) 
      -[:RATED {score: 5}]->(movie:Movie)
      <-[:RATED {score: 5}]-(similar:User)
      -[:RATED {score: 5}]->(reco:Movie)
RETURN user.name, movie.title, similar.name, reco.title
```

**結果**
```
Alice 給 《Inception》 打 5 星
Bob 也給 《Inception》 打 5 星  
Bob 還給 《Interstellar》 打 5 星
→ 推薦 《Interstellar》 給 Alice
```

**路徑 = 解釋** ← 人一看就明白

---

# 結構 → 語義 → 信任

**三個層次的信任**

```
層 1：結構（Graph）
User A 和 User B 都喜歡同樣的電影
  ↓
層 2：語義（模式）
品味相似 = 信號
  ↓
層 3：信任（應用）
基於相似品味的推薦 = 值得嘗試
```

**為什麼工作**：
- 結構是可驗證的（查詢可重現）
- 邏輯是直觀的（人能理解）
- 結果是可解釋的（可以講故事）

---

# 「機器跑得動、人看得懂」

**這是 program 的兩個 basic requirement**

```
✓ 機器跑得動
  └─ 演算法完整、結果正確

✓ 人看得懂
  └─ 推理邏輯清晰、可說明理由
```

**一個都不能少**

| 只有機器 | 只有人 | 兩者都有 |
|---------|--------|---------|
| 黑箱、無法信任 | 無法自動化 | ✓ 最佳 |

**Graph 推薦系統** = 兩者都有

---

# 可解釋性的實際價值

**場景 1：推薦系統**
- 用戶看到推薦理由 → 信任度 ↑
- A/B 測試更容易：路徑可重現

**場景 2：金融風控**
- 審批拒絕要有理由（法規要求）
- Graph：「因為你的行為模式類似這 5 個高風險用戶」
- 可解釋 = 可審計 = 可合規

**場景 3：知識圖譜**
- 信息來源可追溯：「從文獻 A 推導到結論 B」
- 可驗證 = 可被質疑 = 更科學

---

# 可解釋性 vs 精確度

**常見誤解**：可解釋性會牺牲精確度

**事實**：
- 簡單的可解釋模型 → 魯棒（不過度擬合）
- 複雜的黑箱模型 → 風險（對抗樣本、分布偏移）
- Graph 路徑 → 自然的過度擬合防護

**實際權衡**：
```
黑箱模型：精度 95%，沒人知道為什麼，出問題誰的責任？
Graph 模型：精度 90%，邏輯清晰，出問題好處理
```

→ **大多數場景，可解釋性更重要**

---

# 四堂課的貫穿主軸

回到一開始的兩個主張：

## 主張 1：可解釋性
```
Graph 結構 → 顯式關係 → 人能理解
≠ GenAI 的機率黑箱
```

## 主張 2：In-database 計算
```
結構預存 → 直接跑演算法 → 快速高效
≠ 傳統拉資料到應用層
```

**結合**：既快又透明 = 最佳系統特性

---

# 小結：四堂課要點

| Unit | 核心 | 收穫 |
|------|------|------|
| 1 | Graph 基礎 | 結構即語義 |
| 2 | Cypher 查詢 | 多跳很簡單 |
| 3 | 演算法計算 | in-database 很快 |
| 4 | 可解釋性 | 人能信任結果 |

**這就是為什麼 Graph 特別適合某些問題**

---

# 延伸：哪些場景適合 Graph？

**高關係密度**
- 推薦、社交網絡、知識圖譜
- 多跳查詢常見、JOIN 層數多

**需要可解釋性**
- 金融風控、醫療診斷、法律合規
- 必須能說明理由

**動態結構**
- 組織架構變化、項目依賴關係
- 關係本身經常改動

**你的系統有這些特徵嗎？**

---

# 下一步

你現在已經會：
- ✓ 用 Graph 建模
- ✓ 用 Cypher 查詢
- ✓ 跑 in-database 推薦
- ✓ 理解可解釋性的價值

**回到工作中**：
- 有沒有什麼問題可以用 Graph 思考？
- 什麼 SQL JOIN 地獄可以變成 Cypher 路徑？
- 什麼推薦系統需要更多透明度？

---

<!-- _class: lead -->

# 實作開始！

---

# 實作目標（40 mins）

**把推薦結果變得「可解釋」：**

1. ✅ 視覺化推薦路徑
2. ✅ 修改 query，設計合理的推薦邏輯
3. ✅ 開放討論：你的系統適合 Graph 嗎？

**成功指標**：
- 看到推薦路徑 ✓
- 能說明「為什麼推薦這個」✓
- 思考過自己的問題 ✓

---

# 實作步驟

**Step 1（10 min）**：查詢推薦路徑
```cypher
# 顯示推薦路徑：你 → 相似人 → 推薦
MATCH path = (user:User {id: 'A'})
             -[:RATED {score: 5}]->(m1:Movie)
             <-[:RATED {score: 5}]-(sim:User)
             -[:RATED {score: 5}]->(reco:Movie)
WHERE NOT (user) -[:RATED]-> (reco)
RETURN user.name, m1.title, sim.name, reco.title
ORDER BY reco.title
LIMIT 20
```

**這個查詢回答**：推薦 Movie X 給 User A，是因為哪個相似用戶、通過哪部相同電影？

**Step 2（15 min）**：修改推薦邏輯
```cypher
# 變種 1：只看 5 星評分（更嚴格）
WHERE r1.score = 5 AND r2.score = 5 AND r3.score = 5

# 變種 2：只看最近評分（時效性）
AND r3.timestamp > '2024-01-01'

# 變種 3：限制相似用戶數（效率）
WHERE sim IN (相似用戶前 10)
```

你現在在**設計推薦邏輯**，而不是調參數！

**Step 3（10 min）**：視覺化思考
```
繪製你的推薦邏輯：

Your Taste (5⭐)
    ↓ (通過這些電影)
Similar Person A, B, C
    ↓ (他們喜歡)
Recommendations

問：這個邏輯合理嗎？有沒有改進空間？
```

**Step 4（5 min）**：開放討論
- 你的系統有推薦功能嗎？
- 現在是黑箱嗎？可以改成可解釋的嗎？
- 除了推薦，還有其他「多跳查詢」的問題嗎？

---

# 檢查點

你現在能做到：

✅ 看到推薦的完整路徑（誰推薦、因為什麼）
✅ 說明推薦邏輯（不是「機器說推薦就推薦」）
✅ 自己設計推薦規則（不是照搬算法）
✅ 思考適用場景（不是盲目用 Graph）

**結束語**：
- 可解釋性 = 信任的基礎
- Graph = 讓邏輯透明的工具
- 接下來看你怎樣在自己的系統裡用

下次見！
