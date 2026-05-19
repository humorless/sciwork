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
Product: "USB Hub XR-200"  score: 0.0043
```

**這個數字說明了什麼？沒人知道。**

你能告訴用戶「為什麼推薦這個」嗎？

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
你買了 A → 也買了 A 的人還買了 B → B 的人還買了 C
```

→ 路徑本身就是推薦理由

---

# 路徑就是解釋

**Query**：

```cypher
MATCH (p:Product {id: 'B0001'})
      -[:CO_PURCHASED]->(mid:Product)
      -[:CO_PURCHASED]->(reco:Product)
WHERE reco <> p
RETURN p.title, mid.title, reco.title
LIMIT 10
```

**輸出**：

```
p.title       mid.title       reco.title
──────────    ─────────────   ──────────────
USB Hub       HDMI Cable      Monitor Stand
USB Hub       HDMI Cable      Laptop Cooler
```

推薦理由就在 `mid.title` 這一欄——人一眼就明白。

---

# 可解釋性的實際價值

**推薦系統**：用戶看到「因為你買了 X，也買了 X 的人還買了 Y」→ 信任度提升

**Supply chain 風控**：「S2 斷供會影響哪些產品線？」→ 路徑可追溯，可審計

**金融風控**：法規要求拒絕必須附理由 → Graph 路徑天然滿足

**知識圖譜**：「從文獻 A 推導到結論 B」→ 推理鏈可驗證

---

# 機器跑得動、人看得懂

**這是 program 的兩個 basic requirement**

```
✓ 機器跑得動
  └─ 演算法跑在 DB 裡，結果正確

✓ 人看得懂
  └─ 路徑顯式，邏輯可追溯
```

| 只有機器 | 只有人 | 兩者都有 |
|---------|--------|---------|
| 黑箱、難信任 | 無法自動化 | ✓ 目標 |

Graph 系統天然滿足兩者。

---

# 視覺化工具：G.V()

文字輸出有時不夠直觀，用 **G.V()** 把路徑畫出來

連線方式：

```bash
# 在 Ladybug Explorer 設定中加入 G.V() 連線
```

接著在 G.V() 執行同一個 Cypher query → 自動渲染成圖形

**視覺化特別有用的場景**：Unit 2 的多跳依賴鏈、Unit 4 的推薦路徑

---

# 四個 Unit 的貫穿主軸

| Unit | 核心 | 收穫 |
|------|------|------|
| 1 | 為什麼用 Graph + 建模 | 關係是一等公民 |
| 2 | Cypher 多跳查詢 | 路徑就是邏輯 |
| 3 | In-database 演算法 | 資料不動，演算法進去 |
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
2. ✅ 用 G.V() 視覺化路徑
3. ✅ 自己修改 query，設計推薦邏輯
4. ✅ 開放討論：你的系統有沒有 Graph 的機會？

---

# Step 1（10 min）：路徑查詢

```cypher
-- 兩跳推薦路徑，顯示中間節點
MATCH (p:Product {id: 'B0001'})
      -[:CO_PURCHASED]->(mid:Product)
      -[:CO_PURCHASED]->(reco:Product)
WHERE reco <> p
RETURN p.title AS source,
       mid.title AS via,
       reco.title AS recommended
ORDER BY reco.title
LIMIT 20
```

確認每一行都能說出推薦理由

---

# Step 2（15 min）：G.V() 視覺化

在 G.V() 執行同一個 query，觀察：
- 路徑的形狀
- 哪些節點是樞紐（連接很多路徑）
- 哪些推薦路徑特別長

**嘗試修改**：
- 把 `*1..2` 改成 `*1..3`，路徑圖會變得更複雜嗎？
- 限制只看某個 category 的商品

---

# Step 3（10 min）：設計你的推薦邏輯

不只是「買了 A 的人也買了 B」，你可以加上條件：

```cypher
-- 只推薦評分高的商品
MATCH (p:Product {id: 'B0001'})
      -[:CO_PURCHASED]->(mid)
      -[:CO_PURCHASED]->(reco:Product)
WHERE reco.avg_rating >= 4.0
  AND reco <> p
RETURN reco.title, reco.avg_rating
ORDER BY reco.avg_rating DESC
LIMIT 10
```

**你在做的事**：設計邏輯，不是調參數

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
- ✅ **計算工具**：六個 in-database algorithm 的選型直覺
- ✅ **可解釋性**：路徑就是推理過程

謝謝參與！
