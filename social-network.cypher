// ============================================================
// Social Network Dataset
// 10 nodes (User), 18 edges (FOLLOWS)
// For Graph Analysis Workshop - Unit 2
// ============================================================

// DDL: Node table
CREATE NODE TABLE User(username STRING, region STRING, PRIMARY KEY(username));

// DDL: Relationship table
CREATE REL TABLE FOLLOWS(FROM User TO User);

// Data: User nodes
CREATE (:User {username: 'alice',   region: 'TW'});
CREATE (:User {username: 'bob',     region: 'TW'});
CREATE (:User {username: 'carol',   region: 'TW'});
CREATE (:User {username: 'dave',    region: 'JP'});
CREATE (:User {username: 'eve',     region: 'JP'});
CREATE (:User {username: 'frank',   region: 'US'});
CREATE (:User {username: 'grace',   region: 'US'});
CREATE (:User {username: 'henry',   region: 'US'});
CREATE (:User {username: 'iris',    region: 'SG'});
CREATE (:User {username: 'jack',    region: 'SG'});

// Data: FOLLOWS relationships
// alice follows
MATCH (a:User {username: 'alice'}),  (b:User {username: 'bob'})   CREATE (a)-[:FOLLOWS]->(b);
MATCH (a:User {username: 'alice'}),  (b:User {username: 'carol'}) CREATE (a)-[:FOLLOWS]->(b);
MATCH (a:User {username: 'alice'}),  (b:User {username: 'dave'})  CREATE (a)-[:FOLLOWS]->(b);

// bob follows
MATCH (a:User {username: 'bob'}),    (b:User {username: 'eve'})   CREATE (a)-[:FOLLOWS]->(b);
MATCH (a:User {username: 'bob'}),    (b:User {username: 'frank'}) CREATE (a)-[:FOLLOWS]->(b);

// carol follows
MATCH (a:User {username: 'carol'}),  (b:User {username: 'frank'}) CREATE (a)-[:FOLLOWS]->(b);
MATCH (a:User {username: 'carol'}),  (b:User {username: 'grace'}) CREATE (a)-[:FOLLOWS]->(b);

// dave follows
MATCH (a:User {username: 'dave'}),   (b:User {username: 'eve'})   CREATE (a)-[:FOLLOWS]->(b);
MATCH (a:User {username: 'dave'}),   (b:User {username: 'iris'})  CREATE (a)-[:FOLLOWS]->(b);

// eve follows
MATCH (a:User {username: 'eve'}),    (b:User {username: 'grace'}) CREATE (a)-[:FOLLOWS]->(b);
MATCH (a:User {username: 'eve'}),    (b:User {username: 'henry'}) CREATE (a)-[:FOLLOWS]->(b);

// frank follows
MATCH (a:User {username: 'frank'}),  (b:User {username: 'henry'}) CREATE (a)-[:FOLLOWS]->(b);
MATCH (a:User {username: 'frank'}),  (b:User {username: 'jack'})  CREATE (a)-[:FOLLOWS]->(b);

// grace follows
MATCH (a:User {username: 'grace'}),  (b:User {username: 'iris'})  CREATE (a)-[:FOLLOWS]->(b);

// henry follows
MATCH (a:User {username: 'henry'}),  (b:User {username: 'jack'})  CREATE (a)-[:FOLLOWS]->(b);
MATCH (a:User {username: 'henry'}),  (b:User {username: 'alice'}) CREATE (a)-[:FOLLOWS]->(b);

// iris follows
MATCH (a:User {username: 'iris'}),   (b:User {username: 'bob'})   CREATE (a)-[:FOLLOWS]->(b);

// jack follows
MATCH (a:User {username: 'jack'}),   (b:User {username: 'carol'}) CREATE (a)-[:FOLLOWS]->(b);
