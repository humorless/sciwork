# 圖學資料庫與其應用

> 適合受眾：Graph 概念全新、四個核心概念（graph modeling、Cypher、in-database analytics、可解釋性）都是第一次接觸的工程師；具備基本演算法直覺（BFS/DFS），不一定熟悉 SQL。

**設計原則**：每單元只引入一個新概念，實作目標明確且可完成。

**Dataset 策略**
- 基礎練習：手建 Supply chain（BOM）小型 dataset（8 個節點、12 條邊），講者提供，不需下載
- Unit 1-2 練習：Supply chain dataset + Social network dataset
- Unit 3-4 主線實作：Amazon follow graph（SNAP amazon0601）——社交網絡，account/follows 關係

---

### Unit 1｜Graph 是什麼？為什麼不用 SQL / Python 就好

**Talk（30 min）**

從三個問題建立問題意識：

- **為什麼要用 Graph 建模？** 不從「SQL 很痛」切入，而從「關係本身就是資料」出發。Supply chain 的 BOM：零件 A 依賴 B，B 依賴 C、D——這個「依賴」是事實，不是外鍵的副產品。演算法橋接：「找所有上游依賴」就是 BFS，你以前用程式算，現在讓 DB 算。
- **有哪些選擇？** Application layer（NetworkX）、RDBMS + recursive CTE、Graph DB——三個選項的 trade-off，說「什麼情況選哪個」，不說哪個一定對。
- **為什麼選 Cypher + Ladybug？** `(a)-[r]->(b)` 不是語法糖，是語意。Ladybug：embedded、columnar、MIT license，terminal 裡跑，不需起 server。

說明 Graph model 的三個元素（節點、關係、屬性），用 Supply chain 示範 schema：`(Component)-[:DEPENDS_ON]->(Component)`、`(Supplier)-[:SUPPLIES]->(Component)`。

**實作（30 min）**
- 環境確認、Ladybug Explorer 連線，載入講者提供的 Supply chain dataset
- 練習基礎 query，目標是每個人跑出結果，建立信心：
  1. `MATCH (c:Component) RETURN c` — 列出所有零件
  2. `MATCH (s:Supplier)-[:SUPPLIES]->(c:Component) RETURN s.name, c.name` — 誰供應什麼
  3. `MATCH (a:Component)-[:DEPENDS_ON]->(b:Component) RETURN a.name, b.name` — 第一跳依賴

**本單元引入的新概念**：Graph 建模的問題意識 + Graph model 思維方式

---

### Unit 2｜Cypher：用結構描述問題

**Talk（20 min）**
- Cypher 的語法邏輯：`(node)-[relation]->(node)` 就是你看到的樣子
- 對比 SQL 的思維差異：SQL 是「我要哪些欄位」，Cypher 是「我要走哪條路」
- 示範幾個 pattern：一跳、兩跳、variable-length path（`*1..3`）、過濾條件

**實作（40 min）**
- 繼續用 Supply chain dataset，逐步加深 query：
  1. `MATCH (a)-[:DEPENDS_ON*1..3]->(b) WHERE a.name = 'X' RETURN b` — 找出 X 的所有上游依賴（multi-hop）
  2. 加上過濾：只看 critical = true 的依賴路徑
  3. 換用 Social network dataset：「A 關注的人也關注誰？」——同一個 Cypher 語法，不同語意，展示 query 的通用性
- 目標：學員能自己修改 query，不是只能 copy paste

**本單元引入的新概念**：Cypher 語法與多跳查詢

---

### Unit 3｜In-database Analytics：Algorithm Tour

**Talk（20 min）**
- 痛點：傳統做法是把資料拉出來，用 Python / NetworkX 算，再寫回去——資料量一大，這個流程就崩了
- In-database 的邏輯：資料不動，演算法進去
- 今天要解的六個圖論問題，每個用一句話說清楚它在解什麼問題
- 實現方式：Shortest Paths 用 Cypher 查詢，其他五個用 ALGO extension

**實作（40 min）**

在 Amazon follow graph（SNAP amazon0601，account/follows 關係）上依序解決六個演算法問題，每個只花 5-7 分鐘，目標是「看到結果、知道它在算什麼」，不是深入原理：

| Algorithm | 問的問題 | 實現方式 |
|---|---|---|
| **Shortest Paths** | A 到 B 最短走幾跳？關注鏈最短是什麼？ | Cypher 查詢 |
| **PageRank** | 誰是網絡裡最重要的節點（被最多人關注）？ | ALGO extension |
| **Louvain** | 網絡裡自然地形成了哪些社群？ | ALGO extension |
| **Weakly Connected Components（WCC）** | 整個圖裡有幾個獨立的連通分量？ | ALGO extension |
| **Strongly Connected Components（SCC）** | 哪些節點互相可以到達對方？ | ALGO extension |
| **K-Core Decomposition** | 最核心的高度互連節點是哪些？ | ALGO extension |

- 對比：如果用 Python 自己實作 PageRank，需要幾行？Ladybug 是幾行？
- 目標：親身感受 in-database analytics 的簡潔性，以及每個 algorithm 能回答什麼類型的問題

**本單元引入的新概念**：in-database graph analytics + Algorithm 選型直覺

---

### Unit 4｜可解釋性：路徑就是解釋

**Talk（20 min）**
- GenAI 推薦 vs Graph 推薦的根本差異：一個是機率，一個是路徑
- 可解釋性來自結構：「因為你關注了 A，A 也關注了 B，B 關注的人多，所以推薦你關注 B」——路徑就是推薦理由
- 收尾：**機器跑得動、人看得懂**——這是 program 的兩個 basic requirement，貫穿全天
- 延伸：哪些場景 Graph 的可解釋性特別有價值（金融風控、供應鏈風險、推薦系統、知識圖譜）

**實作（40 min）**
- 在 Ladybug Explorer 中執行推薦路徑 query，從表格結果觀察規律：不只是「推薦 ID 45」，而是「為什麼推薦 ID 45」
  - 看有多少條推薦路徑
  - 找出影響力最大的中間節點（出現最頻繁的）
  - 比較不同起點帳戶的推薦模式
- 學員嘗試修改 query，設計自己覺得合理的推薦邏輯（加上過濾條件，如「至少有 2 條獨立路徑」）
- 最後 5 分鐘：開放討論——你的系統裡有沒有哪個問題適合用 Graph 思考？

**本單元引入的新概念**：可解釋性與路徑推理
