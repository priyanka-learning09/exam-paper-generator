-- =====================================================
-- 01_schema.sql : Exam Paper Generator
-- =====================================================
CREATE EXTENSION IF NOT EXISTS vector;

-- Drop in reverse dependency order (safe re-runs)
DROP TABLE IF EXISTS exam_question CASCADE;
DROP TABLE IF EXISTS exam CASCADE;
DROP TABLE IF EXISTS topic_weightage CASCADE;
DROP TABLE IF EXISTS question CASCADE;
DROP TABLE IF EXISTS difficulty CASCADE;
DROP TABLE IF EXISTS topic CASCADE;
DROP TABLE IF EXISTS chapter CASCADE;
DROP TABLE IF EXISTS subject CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- ---------- USERS (authentication + roles) ----------
CREATE TABLE users (
    user_id        SERIAL PRIMARY KEY,
    full_name      VARCHAR(100) NOT NULL,
    email          VARCHAR(150) NOT NULL UNIQUE,
    password_hash  VARCHAR(255) NOT NULL,
    role           VARCHAR(10)  NOT NULL CHECK (role IN ('ADMIN','TEACHER')),
    created_at     TIMESTAMP    NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_email_format CHECK (email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$')
);

-- ---------- SUBJECT ----------
CREATE TABLE subject (
    subject_id    SERIAL PRIMARY KEY,
    subject_name  VARCHAR(100) NOT NULL UNIQUE,
    description   TEXT
);

-- ---------- CHAPTER ----------
CREATE TABLE chapter (
    chapter_id    SERIAL PRIMARY KEY,
    subject_id    INT NOT NULL REFERENCES subject(subject_id) ON DELETE CASCADE,
    chapter_name  VARCHAR(150) NOT NULL,
    description   TEXT,
    UNIQUE (subject_id, chapter_name)
);

-- ---------- TOPIC ----------
CREATE TABLE topic (
    topic_id      SERIAL PRIMARY KEY,
    chapter_id    INT NOT NULL REFERENCES chapter(chapter_id) ON DELETE CASCADE,
    topic_name    VARCHAR(150) NOT NULL,
    description   TEXT,
    UNIQUE (chapter_id, topic_name)
);

-- ---------- DIFFICULTY ----------
CREATE TABLE difficulty (
    difficulty_id     SERIAL PRIMARY KEY,
    difficulty_level  VARCHAR(10) NOT NULL UNIQUE
                      CHECK (difficulty_level IN ('Easy','Medium','Hard'))
);

-- ---------- QUESTION ----------
CREATE TABLE question (
    question_id     SERIAL PRIMARY KEY,
    topic_id        INT NOT NULL REFERENCES topic(topic_id) ON DELETE CASCADE,
    difficulty_id   INT NOT NULL REFERENCES difficulty(difficulty_id),
    question_text   TEXT NOT NULL CHECK (length(trim(question_text)) > 5),
    option_a        VARCHAR(500) NOT NULL,
    option_b        VARCHAR(500) NOT NULL,
    option_c        VARCHAR(500) NOT NULL,
    option_d        VARCHAR(500) NOT NULL,
    correct_option  CHAR(1) NOT NULL CHECK (correct_option IN ('A','B','C','D')),
    marks           INT NOT NULL DEFAULT 1 CHECK (marks > 0 AND marks <= 20),
    created_by      INT REFERENCES users(user_id) ON DELETE SET NULL,
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    -- Full-text search column (auto-maintained)
    search_vector   tsvector GENERATED ALWAYS AS
                    (to_tsvector('english', question_text)) STORED,
    -- Vector embedding (384 dims = all-MiniLM-L6-v2)
    embedding       vector(384)
);

-- ---------- TOPIC_WEIGHTAGE ----------
CREATE TABLE topic_weightage (
    subject_id              INT NOT NULL REFERENCES subject(subject_id) ON DELETE CASCADE,
    topic_id                INT NOT NULL REFERENCES topic(topic_id) ON DELETE CASCADE,
    weightage_percent       NUMERIC(5,2) NOT NULL CHECK (weightage_percent BETWEEN 0 AND 100),
    no_of_questions_to_pick INT NOT NULL CHECK (no_of_questions_to_pick >= 0),
    PRIMARY KEY (subject_id, topic_id)
);

-- ---------- EXAM ----------
CREATE TABLE exam (
    exam_id          SERIAL PRIMARY KEY,
    exam_name        VARCHAR(150) NOT NULL,
    subject_id       INT NOT NULL REFERENCES subject(subject_id),
    exam_date_time   TIMESTAMP NOT NULL,
    duration_minutes INT NOT NULL CHECK (duration_minutes BETWEEN 10 AND 300),
    total_marks      INT NOT NULL DEFAULT 0 CHECK (total_marks >= 0),
    created_by       INT REFERENCES users(user_id) ON DELETE SET NULL
);

-- ---------- EXAM_QUESTION (resolves EXAM <-> QUESTION M:N) ----------
CREATE TABLE exam_question (
    exam_id      INT NOT NULL REFERENCES exam(exam_id) ON DELETE CASCADE,
    question_id  INT NOT NULL REFERENCES question(question_id),
    sequence_no  INT NOT NULL CHECK (sequence_no > 0),
    marks        INT NOT NULL CHECK (marks > 0),
    PRIMARY KEY (exam_id, question_id),
    UNIQUE (exam_id, sequence_no)
);

-- =====================================================
-- INDEXES
-- =====================================================
CREATE INDEX idx_chapter_subject     ON chapter(subject_id);
CREATE INDEX idx_topic_chapter       ON topic(chapter_id);
CREATE INDEX idx_question_topic      ON question(topic_id);
CREATE INDEX idx_question_difficulty ON question(difficulty_id);
CREATE INDEX idx_exam_subject        ON exam(subject_id);
CREATE INDEX idx_examq_question      ON exam_question(question_id);

-- Full-text search index
CREATE INDEX idx_question_fts ON question USING GIN (search_vector);

-- Vector similarity index (cosine distance)
CREATE INDEX idx_question_embedding ON question
    USING hnsw (embedding vector_cosine_ops);