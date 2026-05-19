-- ============================================================
-- Supply Chain BOM Dataset
-- 8 nodes, 12 edges
-- For Graph Analysis Workshop - Unit 1 & 2
-- ============================================================

-- Node: Supplier
CREATE (s1:Supplier {name: 'S1', country: 'TW'});
CREATE (s2:Supplier {name: 'S2', country: 'JP'});

-- Node: Component
CREATE (x:Component  {name: 'X', critical: true});
CREATE (a:Component  {name: 'A', critical: true});
CREATE (b:Component  {name: 'B', critical: true});
CREATE (c:Component  {name: 'C', critical: false});
CREATE (d:Component  {name: 'D', critical: false});
CREATE (e:Component  {name: 'E', critical: true});

-- Relationship: SUPPLIES (Supplier -> Component)
MATCH (s:Supplier {name: 'S1'}), (c:Component {name: 'A'})
CREATE (s)-[:SUPPLIES {lead_time: 14}]->(c);

MATCH (s:Supplier {name: 'S1'}), (c:Component {name: 'D'})
CREATE (s)-[:SUPPLIES {lead_time: 30}]->(c);

MATCH (s:Supplier {name: 'S2'}), (c:Component {name: 'B'})
CREATE (s)-[:SUPPLIES {lead_time: 21}]->(c);

MATCH (s:Supplier {name: 'S2'}), (c:Component {name: 'C'})
CREATE (s)-[:SUPPLIES {lead_time: 7}]->(c);

MATCH (s:Supplier {name: 'S2'}), (c:Component {name: 'E'})
CREATE (s)-[:SUPPLIES {lead_time: 14}]->(c);

-- Relationship: DEPENDS_ON (Component -> Component)
MATCH (a:Component {name: 'X'}), (b:Component {name: 'A'})
CREATE (a)-[:DEPENDS_ON {quantity: 1}]->(b);

MATCH (a:Component {name: 'X'}), (b:Component {name: 'B'})
CREATE (a)-[:DEPENDS_ON {quantity: 2}]->(b);

MATCH (a:Component {name: 'X'}), (b:Component {name: 'E'})
CREATE (a)-[:DEPENDS_ON {quantity: 1}]->(b);

MATCH (a:Component {name: 'B'}), (b:Component {name: 'C'})
CREATE (a)-[:DEPENDS_ON {quantity: 4}]->(b);

MATCH (a:Component {name: 'B'}), (b:Component {name: 'D'})
CREATE (a)-[:DEPENDS_ON {quantity: 1}]->(b);

MATCH (a:Component {name: 'A'}), (b:Component {name: 'C'})
CREATE (a)-[:DEPENDS_ON {quantity: 2}]->(b);

MATCH (a:Component {name: 'E'}), (b:Component {name: 'D'})
CREATE (a)-[:DEPENDS_ON {quantity: 1}]->(b);
