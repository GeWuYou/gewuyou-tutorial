CREATE TABLE bind_table (uuid UUID PRIMARY KEY, created_at TIMESTAMP);
INSERT INTO bind_table VALUES (gen_random_uuid(), NOW());
