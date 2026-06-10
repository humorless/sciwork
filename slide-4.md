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

# 可解釋性：路徑就是解釋

**Unit 4** | Graph Analysis Workshop

---

# 問題：結果出來了，然後呢？

Unit 3 跑了 PageRank，輸出：

```
node.ID: 45  rank: 0.001586
```

數字本身說不出理由，但 PageRank 不同於黑箱模型——
它是基於圖結構的。要解釋「為什麼 45 的排名這麼高」：反向查詢「有哪些高排名的帳戶關注了 45？」
這個路徑就是排名的成因。

---

# 兩種推薦的本質差異

**GenAI / 黑箱模型**：

```
輸入 → [Neural Network] → 輸出
         ↑
     機率，不是路徑
```

→ 精度可能高，但沒有解釋

**Graph 路徑推理**：

```
你關注了 A → A 也關注了 B → B 關注的人多
```

→ 路徑本身就是推薦理由

---

# 路徑就是解釋：為什麼 45 的排名高？

**Query**（反向路徑）：

```cypher
// 一跳反向：誰關注了 45？
MATCH (in1:account)-[:follows]->(p:account {ID: 45})
MATCH (pr:account_pagerank {account_id: in1.ID})
RETURN in1.ID AS follower, pr.rank
ORDER BY pr.rank DESC
LIMIT 10
```

（`account_pagerank` 是預先算好的 PageRank 結果表，建法見實作段）

**結論**：45 的排名高，因為有這些高排名的帳戶指向它（直接或間接）。路徑本身解釋了結果。

---

# 推薦系統：路徑的另一個應用

**正向路徑**用於推薦：

```cypher
// 45 關注的人，也都關注了誰？
MATCH (p:account {ID: 45})
      -[:follows]->(mid:account)
      -[:follows]->(reco:account)
WHERE reco <> p
RETURN mid.ID AS via, reco.ID AS recommended
```

推薦理由：「你關注了 mid，而 mid 也關注了 recommended，所以推薦 recommended」

---

# 可解釋性的實際價值

**推薦系統**：使用者看到「因為你關注 X，也關注 X 的人關注 Y」→ 信任度提升

**Supply chain 風控**：「供應商 S 斷供影響哪些下游？」→ 依賴鏈路徑可審計

**金融風控**：「為什麼拒絕這筆交易？」→ 風險路徑可解釋，符合法規要求

**知識圖譜**：「從事實 A 推導到結論 B」→ 推理鏈可驗證

---

# 機器跑得動、人看得懂

**這是 program 的兩個 basic requirement**

```
✓ 機器跑得動
  └─ 圖學演算法在 DB 裡跑，節省了大量的 IO 時間

✓ 人看得懂
  └─ 路徑顯式，邏輯可追溯
```

適合用圖來建模的複雜問題，用 graph database 來處理，恰好滿足 2 個條件。

---


# 四個 Unit 的貫穿主軸

| Unit | 核心 | 收穫 |
|------|------|------|
| 1 | 為什麼用 Graph + 建模 | 關係是一等公民 |
| 2 | Cypher 多跳查詢 | 路徑就是邏輯 |
| 3 | In-database Analytics | 資料不動，演算法進去 |
| 4 | 可解釋性 | 路徑就是解釋 |

**機器跑得動、人看得懂**——貫穿全天

---

# 哪些場景特別適合 Graph？

**多跳查詢是常態**：supply chain、組織架構、dependency graph

**需要可解釋性**：金融風控、醫療、法規合規

**關係本身要存屬性**：評分、時間、權重

**你的系統有這些特徵嗎？**

---

<!-- _class: lead -->

# 實作開始！

---

# 實作目標（40 min）

1. ✅ 準備 PageRank 資料（匯入資料庫）
2. ✅ Step 1：一跳反向 + 排名
3. ✅ Step 2：統計直接 Follower
4. ✅ Step 3：找出最重要的「中介」

---

# 準備階段：建立資料表

**思路**：PageRank 結果 → 獨立表 → JOIN 查詢

```cypher
CREATE NODE TABLE account_pagerank
  (account_id INT64 PRIMARY KEY, rank DOUBLE);
```

---

# 準備階段：計算 + 匯入

**計算 PageRank 並且存到檔案**
```cypher
CALL project_graph('Graph', ['account'], ['follows']);
COPY (CALL page_rank('Graph') RETURN node.ID AS account_id, rank) TO 'pagerank.csv' (header=true);
```
**匯入 CSV**
```cypher
COPY account_pagerank FROM 'pagerank.csv'
  (HEADER=TRUE, DELIMITER=',');
```

✅ 現在可以 JOIN 查詢

---

# Step 1：一跳反向 + 排名

```cypher
MATCH (in1)-[:follows]->(p:account {ID: 45})
MATCH (pr:account_pagerank {account_id: in1.ID})
RETURN in1.ID, pr.rank
ORDER BY pr.rank DESC LIMIT 20
```

**結果**：`1036 (0.001380)` ← 最高排名的 follower

高排名帳戶指向 45 ⟹ 45 排名高

---

# Step 2：統計直接 Follower

```cypher
MATCH (in1)-[:follows]->(p:account {ID: 45})
MATCH (pr:account_pagerank {account_id: in1.ID})
RETURN COUNT(*) AS followers,
       SUM(pr.rank) AS total_rank,
       AVG(pr.rank) AS avg_rank
```

**結果**：
```
followers │ total_rank │ avg_rank
──────────┼────────────┼──────────
2487      │ 0.017803   │ 0.000007
```

**理解**：
- 2,487 個帳戶直接關注 45
- 他們的平均排名是 0.000007（都是高排名帳戶，相對全網平均 0.000002）

---

# Step 3：最重要的「中介」

```cypher
MATCH (in2)-[:follows]->(in1)-[:follows]->(p:account {ID: 45})
MATCH (pr:account_pagerank {account_id: in1.ID})
RETURN in1.ID, COUNT(DISTINCT in2) AS upstream
ORDER BY upstream DESC LIMIT 10
```

**結果**：
```
in1.ID │ upstream
───────┼──────────
1041   │ 2751 ← 關鍵樞紐！
1036   │ 564
1039   │ 529
```

**理解**：
- `in1.ID = 1041` 是最重要的「連接者」
- 有 **2,751 個帳戶**透過 1041 間接指向 45
- 這說明 1041 在網路中的影響力有多大

---

# Step 4（5 min）：開放討論

思考一個你自己的問題：

- 你的系統裡，有沒有「關係比資料本身更重要」的場景？
- 有沒有什麼 JOIN 越寫越長、卻又必須維護的 query？
- 有沒有「推薦結果出來，但說不清楚為什麼」的情況？

**這些都可能是 Graph 適合介入的地方。**

---

# 你今天帶走的東西

- ✅ **問題意識**：什麼問題適合用 Graph 思考
- ✅ **建模能力**：節點、關係、屬性的設計方式
- ✅ **查詢能力**：Cypher 多跳查詢
- ✅ **Analytics 工具**：六個圖論問題的解法（Cypher + ALGO）
- ✅ **可解釋性**：路徑就是推理過程

**機器跑得動、人看得懂** ——建立信任的基礎

謝謝參與！
