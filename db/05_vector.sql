-- 05_vector.sql : similarity search with pgvector
CREATE OR REPLACE FUNCTION find_similar_questions(
    p_question_id INT,
    p_limit INT DEFAULT 5
)
RETURNS TABLE (question_id INT, question_text TEXT, similarity NUMERIC)
LANGUAGE sql STABLE AS $$
    SELECT q2.question_id,
           q2.question_text,
           ROUND((1 - (q2.embedding <=> q1.embedding))::numeric, 3)
    FROM question q1
    JOIN question q2 ON q2.question_id <> q1.question_id
    WHERE q1.question_id = p_question_id
      AND q2.embedding IS NOT NULL
    ORDER BY q2.embedding <=> q1.embedding
    LIMIT p_limit;
$$;
