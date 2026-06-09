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
它是基於圖結構的。反向查詢：「有哪些高排名的帳戶關注了 45？」
答案就是推薦理由。

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

# 路徑就是解釋

**Query**：

```cypher
MATCH (p:account {ID: 45})
      -[:follows]->(mid:account)
      -[:follows]->(reco:account)
WHERE reco <> p
RETURN p.ID AS source,
       mid.ID AS via,
       reco.ID AS recommended
LIMIT 10
```

**輸出**：

```
source  via   recommended
────    ─────  ──────────
45      1036   1037
45      1036   50
```

推薦理由就在 `via` 這一欄——帳戶 45 關注了 1036，而 1036 也關注了 1037，所以推薦 45 去關注 1037。

---

# 可解釋性的實際價值

**推薦系統**：用戶看到「因為你關注 X，也關注 X 的人關注 Y」→ 信任度提升

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

1. ✅ 查詢推薦路徑，確認結果可解釋
2. ✅ 觀察表格結果，找出影響力節點
3. ✅ 自己修改 query，設計推薦邏輯
4. ✅ 開放討論：你的系統有沒有 Graph 的機會？

---

# Step 1（10 min）：路徑查詢

```cypher
-- 兩跳推薦路徑：45 → via → recommended
MATCH (p:account {ID: 45})
      -[:follows]->(mid:account)
      -[:follows]->(reco:account)
WHERE reco <> p
RETURN p.ID AS source,
       mid.ID AS via,
       reco.ID AS recommended
ORDER BY reco.ID
LIMIT 20
```

確認每一行都能說出推薦理由：「45 關注了 via，via 也關注了 recommended」

---

# Step 2（15 min）：觀察結果模式

在 Ladybug Explorer 執行 Step 1 的 query，看表格結果找規律：

**看表格找規律**：
- 有多少條推薦路徑？
- 哪個中間節點（via）出現最頻繁？ 
  （這意味著它最有影響力）
- 相同的 via 對應多少個不同的推薦目標？

**修改 query 來測試**：
- 改成其他起點帳戶：`{ID: 50}`、`{ID: 1036}`
  → 觀察不同用戶的推薦模式有什麼不同
- 擴展到三跳路徑看會有什麼變化

---

# Step 3（10 min）：設計你的推薦邏輯

不只是「A 關注的人關注 B」，你可以加上條件，篩選值得追蹤的帳戶：

```cypher
-- 只推薦被很多人關注的帳戶
MATCH (p:account {ID: 45})
      -[:follows]->(mid:account)
      -[:follows]->(reco:account)
WHERE reco <> p
WITH reco, COUNT(*) AS paths
WHERE paths >= 2  -- 至少有 2 條獨立推薦路徑
RETURN reco.ID, paths
ORDER BY paths DESC
LIMIT 10
```

**你在做的事**：設計邏輯（篩選條件），不是調參數

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
