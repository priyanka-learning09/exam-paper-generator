-- =====================================================
-- 02_seed.sql : sample data (run AFTER 01_schema.sql)
-- =====================================================
INSERT INTO difficulty (difficulty_level) VALUES ('Easy'), ('Medium'), ('Hard');
-- ids: 1=Easy, 2=Medium, 3=Hard

INSERT INTO subject (subject_name, description)
VALUES ('Database Management Systems', 'Core DBMS concepts');

INSERT INTO chapter (subject_id, chapter_name, description) VALUES
(1, 'Introduction to DBMS', 'Basics and data models'),
(1, 'Relational Model',     'Keys, constraints, algebra'),
(1, 'Normalization',        'FDs and normal forms');

INSERT INTO topic (chapter_id, topic_name, description) VALUES
(1, 'DBMS Basics',            'Purpose and architecture'),
(1, 'Data Models',            'ER, relational, hierarchical'),
(2, 'Keys and Constraints',   'PK, FK, candidate keys'),
(2, 'Relational Algebra',     'Select, project, join'),
(3, 'Functional Dependencies','Armstrong axioms, closure'),
(3, 'Normal Forms',           '1NF to BCNF');

INSERT INTO topic_weightage (subject_id, topic_id, weightage_percent, no_of_questions_to_pick) VALUES
(1, 1, 15, 2),
(1, 2, 15, 2),
(1, 3, 20, 2),
(1, 4, 20, 2),
(1, 5, 15, 1),
(1, 6, 15, 1);

INSERT INTO question
(topic_id, difficulty_id, question_text, option_a, option_b, option_c, option_d, correct_option, marks) VALUES
(1,1,'Which software is used to manage and organize databases?','Compiler','DBMS','Browser','Assembler','B',1),
(1,2,'Which DBMS component translates queries into low-level operations?','Query processor','Loader','Linker','Scheduler','A',1),
(1,1,'What does DBMS stand for?','Data Base Main System','Database Management System','Data Binary Management Set','Digital Base Module System','B',1),
(2,1,'Which model uses tables to represent data?','Network','Hierarchical','Relational','Object','C',1),
(2,2,'In an ER diagram, a rectangle represents what?','Attribute','Relationship','Entity','Constraint','C',1),
(2,3,'Which data model allows a child record to have multiple parents?','Hierarchical','Network','Flat file','Relational','B',2),
(3,1,'A column that uniquely identifies each row is called?','Foreign key','Primary key','Index','View','B',1),
(3,2,'A foreign key enforces which type of integrity?','Domain','Entity','Referential','Semantic','C',1),
(3,3,'Which key is a minimal super key?','Candidate key','Alternate key','Foreign key','Composite key','A',2),
(4,1,'Which relational algebra operation selects rows?','Projection','Selection','Union','Rename','B',1),
(4,2,'Which operation combines tuples from two relations based on a condition?','Join','Projection','Difference','Selection','A',1),
(4,3,'Which operation is NOT commutative?','Union','Intersection','Set difference','Cartesian product','C',2),
(5,2,'If A->B and B->C then A->C. This rule is called?','Reflexivity','Augmentation','Transitivity','Union','C',1),
(5,3,'The closure of an attribute set X is the set of?','Keys only','All attributes functionally determined by X','Foreign keys','Indexes','B',2),
(6,1,'A relation is in 1NF if all attributes are?','Atomic','Unique','Indexed','Keys','A',1),
(6,2,'3NF removes which type of dependency?','Partial','Transitive','Multivalued','Join','B',1),
(6,3,'BCNF requires that for every non-trivial FD X->Y, X is a?','Candidate key','Super key','Foreign key','Prime attribute','B',2);