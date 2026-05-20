// ============================================================
// Supply Chain BOM Dataset
// 8 nodes, 12 edges
// For Graph Analysis Workshop - Unit 1 & 2
// ============================================================

// DDL: Node tables
CREATE NODE TABLE Supplier(name STRING, country STRING, PRIMARY KEY(name));
CREATE NODE TABLE Component(name STRING, critical BOOLEAN, PRIMARY KEY(name));

// DDL: Relationship tables
CREATE REL TABLE SUPPLIES(FROM Supplier TO Component, lead_time INT64);
CREATE REL TABLE DEPENDS_ON(FROM Component TO Component, quantity INT64);

// Data: Supplier nodes
CREATE (:Supplier {name: 'S1', country: 'TW'});
CREATE (:Supplier {name: 'S2', country: 'JP'});

// Data: Component nodes
CREATE (:Component {name: 'X', critical: true});
CREATE (:Component {name: 'A', critical: true});
CREATE (:Component {name: 'B', critical: true});
CREATE (:Component {name: 'C', critical: false});
CREATE (:Component {name: 'D', critical: false});
CREATE (:Component {name: 'E', critical: true});

// Data: SUPPLIES relationships
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

// Data: DEPENDS_ON relationships
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
