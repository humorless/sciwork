# 突破關聯查詢的極限：用 Graph 思維處理複雜關聯與多跳推論

很多工程團隊都曾遇過這類問題：

- JOIN 越寫越長，query 幾乎無法維護
- 「找關聯」的需求開始出現多跳 traversal
- recommendation、權限繼承、dependency、fraud detection 等問題很難用 table 直觀表達
- application layer 出現了「查資料 → 組關係 → 再計算」的邏輯

這類問題的共同點是：

> 問題的核心其實是「關係」，但我們仍然被迫用表格或程式邏輯處理。

本 workshop 將透過 Graph Analysis 的方式，重新理解這類問題。

## 講者: Laurence Chen
IT 顧問，專注於協助企業導入 Modern Data Stack。

現職：
- [REPLWARE](https://replware.dev/) CEO
- [台灣 Clojure 社群](https://clojure.tw/) 線下活動主辦人
- [Taipei dbt Meetup 社群](https://www.meetup.com/taipei-dbt-meetup/) 線下活動主辦人

著作：
- [從試算表到資料平台：重構資料工程的技術與團隊](https://www.tenlong.com.tw/products/9786267757284)

## 學習目標
在 4 小時內，讓參與者建立一個可帶走的認知框架，而不是只學會語法：

- 理解 Graph 為何存在：它解決的是哪一類 SQL / application 層難以處理的問題，以及與 NetworkX 等工具的本質差異
- 建立 Graph 思維模型：將資料理解為「節點 + 關係 + 路徑」
- 能閱讀與撰寫基本 Cypher 查詢，並理解多跳查詢的語意
- 理解 in-database 計算的架構意義，以及它提供的六種 graph algorithm
- 能解釋 graph 查詢與計算結果背後的路徑推理邏輯

## 課程內容

課程以 Supply chain（BOM）與 Amazon product co-purchase 兩個 dataset 作為實作案例，但重點不在特定應用領域，而是：

- 如何用 Graph model 表達複雜關聯
- 如何進行多跳查詢
- 如何直接在 database 內執行 graph computation
- 如何讓推論結果具備可解釋性

Workshop 採漸進式設計，每個單元只引入一個新概念，讓第一次接觸 Graph 的工程師也能跟上。

## 事前準備

### 必要準備
- 安裝好 Ladybug DB CLI
- 攜帶可操作的筆電
- 能使用 terminal 執行基本指令

## 建議背景
建議有以下任一經驗更可以快速上手：

- 有 backend / data engineering / analytics 其中一種開發經驗
- 熟悉任一程式語言，能讀懂基本的資料結構操作
- 有演算法基礎（BFS / DFS 等）者尤佳，但非必要

## 不需要的背景

- 不需要 Graph theory 或演算法的正式學術背景
- 不需要使用過 graph database
- 不需要熟悉 SQL
