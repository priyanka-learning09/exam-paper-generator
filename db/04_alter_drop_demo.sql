-- =====================================================
-- 04_alter_drop_demo.sql : ALTER / DROP demonstration
-- =====================================================
ALTER TABLE question ADD COLUMN explanation TEXT;
ALTER TABLE exam ADD COLUMN instructions TEXT DEFAULT 'Answer all questions.';
ALTER TABLE exam ADD CONSTRAINT chk_exam_name_len
    CHECK (length(trim(exam_name)) >= 3);
ALTER TABLE exam DROP COLUMN instructions;

CREATE TABLE temp_demo (id INT PRIMARY KEY, note TEXT);
DROP TABLE temp_demo;