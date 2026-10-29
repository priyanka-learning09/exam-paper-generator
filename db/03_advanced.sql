-- =====================================================
-- 03_advanced.sql : procedure, triggers, views
-- =====================================================

-- ---------- TRIGGER 1: keep exam.total_marks correct ----------
CREATE OR REPLACE FUNCTION fn_update_exam_total()
RETURNS TRIGGER AS $$
DECLARE
    v_exam_id INT;
BEGIN
    IF TG_OP = 'DELETE' THEN
        v_exam_id := OLD.exam_id;
    ELSE
        v_exam_id := NEW.exam_id;
    END IF;

    UPDATE exam
    SET total_marks = COALESCE(
        (SELECT SUM(marks) FROM exam_question WHERE exam_id = v_exam_id), 0)
    WHERE exam_id = v_exam_id;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_update_exam_total ON exam_question;
CREATE TRIGGER trg_update_exam_total
AFTER INSERT OR UPDATE OR DELETE ON exam_question
FOR EACH ROW EXECUTE FUNCTION fn_update_exam_total();

-- ---------- TRIGGER 2: question must belong to the exam's subject ----------
CREATE OR REPLACE FUNCTION fn_check_question_subject()
RETURNS TRIGGER AS $$
DECLARE
    v_q_subject INT;
    v_e_subject INT;
BEGIN
    SELECT c.subject_id INTO v_q_subject
    FROM question q
    JOIN topic t   ON t.topic_id = q.topic_id
    JOIN chapter c ON c.chapter_id = t.chapter_id
    WHERE q.question_id = NEW.question_id;

    SELECT subject_id INTO v_e_subject
    FROM exam WHERE exam_id = NEW.exam_id;

    IF v_q_subject IS DISTINCT FROM v_e_subject THEN
        RAISE EXCEPTION 'Question % does not belong to the subject of exam %',
            NEW.question_id, NEW.exam_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_check_question_subject ON exam_question;
CREATE TRIGGER trg_check_question_subject
BEFORE INSERT OR UPDATE ON exam_question
FOR EACH ROW EXECUTE FUNCTION fn_check_question_subject();

-- ---------- MAIN FEATURE: generate_exam() ----------
-- Picks questions per topic using topic_weightage, preferring questions
-- not used in earlier exams of the same subject.
-- A function runs as ONE transaction: any error rolls back everything.
CREATE OR REPLACE FUNCTION generate_exam(
    p_exam_name  VARCHAR,
    p_subject_id INT,
    p_exam_date  TIMESTAMP,
    p_duration   INT,
    p_created_by INT DEFAULT NULL
) RETURNS INT
LANGUAGE plpgsql AS $$
DECLARE
    v_exam_id   INT;
    v_tw        RECORD;
    v_q         RECORD;
    v_available INT;
    v_seq       INT := 0;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM topic_weightage WHERE subject_id = p_subject_id) THEN
        RAISE EXCEPTION 'No topic weightage configured for subject %', p_subject_id;
    END IF;

    INSERT INTO exam (exam_name, subject_id, exam_date_time, duration_minutes, created_by)
    VALUES (p_exam_name, p_subject_id, p_exam_date, p_duration, p_created_by)
    RETURNING exam_id INTO v_exam_id;

    FOR v_tw IN
        SELECT topic_id, no_of_questions_to_pick
        FROM topic_weightage
        WHERE subject_id = p_subject_id AND no_of_questions_to_pick > 0
        ORDER BY topic_id
    LOOP
        SELECT COUNT(*) INTO v_available
        FROM question WHERE topic_id = v_tw.topic_id;

        IF v_available < v_tw.no_of_questions_to_pick THEN
            RAISE EXCEPTION 'Topic % needs % questions but only % exist',
                v_tw.topic_id, v_tw.no_of_questions_to_pick, v_available;
        END IF;

        FOR v_q IN
            SELECT q.question_id, q.marks
            FROM question q
            WHERE q.topic_id = v_tw.topic_id
            ORDER BY
                EXISTS (SELECT 1
                        FROM exam_question eq
                        JOIN exam e ON e.exam_id = eq.exam_id
                        WHERE eq.question_id = q.question_id
                          AND e.exam_id <> v_exam_id
                          AND e.subject_id = p_subject_id),
                random()
            LIMIT v_tw.no_of_questions_to_pick
        LOOP
            v_seq := v_seq + 1;
            INSERT INTO exam_question (exam_id, question_id, sequence_no, marks)
            VALUES (v_exam_id, v_q.question_id, v_seq, v_q.marks);
        END LOOP;
    END LOOP;

    RETURN v_exam_id;
END;
$$;

-- ---------- VIEWS ----------
CREATE OR REPLACE VIEW v_question_bank AS
SELECT q.question_id, s.subject_name, c.chapter_name, t.topic_name,
       d.difficulty_level, q.question_text, q.correct_option, q.marks
FROM question q
JOIN topic t      ON t.topic_id = q.topic_id
JOIN chapter c    ON c.chapter_id = t.chapter_id
JOIN subject s    ON s.subject_id = c.subject_id
JOIN difficulty d ON d.difficulty_id = q.difficulty_id;

CREATE OR REPLACE VIEW v_topic_coverage AS
SELECT t.topic_id, t.topic_name, c.chapter_name,
       COUNT(q.question_id) AS total_questions,
       COUNT(*) FILTER (WHERE d.difficulty_level = 'Easy')   AS easy_count,
       COUNT(*) FILTER (WHERE d.difficulty_level = 'Medium') AS medium_count,
       COUNT(*) FILTER (WHERE d.difficulty_level = 'Hard')   AS hard_count
FROM topic t
JOIN chapter c         ON c.chapter_id = t.chapter_id
LEFT JOIN question q   ON q.topic_id = t.topic_id
LEFT JOIN difficulty d ON d.difficulty_id = q.difficulty_id
GROUP BY t.topic_id, t.topic_name, c.chapter_name;

CREATE OR REPLACE VIEW v_exam_summary AS
SELECT e.exam_id, e.exam_name, s.subject_name, e.exam_date_time,
       e.duration_minutes, e.total_marks,
       COUNT(eq.question_id) AS question_count
FROM exam e
JOIN subject s          ON s.subject_id = e.subject_id
LEFT JOIN exam_question eq ON eq.exam_id = e.exam_id
GROUP BY e.exam_id, e.exam_name, s.subject_name,
         e.exam_date_time, e.duration_minutes, e.total_marks;