-- Bảng 1: dữ liệu huấn luyện AI
CREATE TABLE raw_data (
    id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    english_text     text NOT NULL,
    vietnamese_text  text NOT NULL,
    source           varchar(100),
    created_at       timestamp DEFAULT now()
);

-- Bảng 2: knowledge graph
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE knowledge_graph_entities (

    id BIGSERIAL PRIMARY KEY,

    entity_name TEXT NOT NULL,

    normalized_name TEXT NOT NULL UNIQUE,

    entity_type VARCHAR(50) NOT NULL,

    language VARCHAR(10),

    frequency INT DEFAULT 1,

    preserve_in_translation BOOLEAN DEFAULT TRUE,

    is_translatable BOOLEAN DEFAULT FALSE,

    embedding VECTOR(384),

    created_at TIMESTAMP DEFAULT NOW(),

    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE knowledge_graph_aliases (

    id BIGSERIAL PRIMARY KEY,

    entity_id BIGINT REFERENCES knowledge_graph_entities(id),

    alias TEXT NOT NULL,

    normalized_alias TEXT NOT NULL,

    alias_type VARCHAR(30),

    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE knowledge_graph_mentions (

    id BIGSERIAL PRIMARY KEY,

    entity_id BIGINT REFERENCES knowledge_graph_entities(id),

    source_sentence TEXT,

    detected_label VARCHAR(50),

    confidence FLOAT,

    language VARCHAR(10),

    created_at TIMESTAMP DEFAULT NOW()
);

-- Bảng 3: lịch sử dịch
CREATE TABLE translation_history (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id      uuid NOT NULL,
    input_text     text NOT NULL,
    output_text    text,
    model_version  varchar(50),
    is_favorite    boolean DEFAULT false,
    rating         int CHECK (rating >= 1 AND rating <= 5),
    created_at       timestamp DEFAULT now()
);

-- Index tăng tốc tìm kiếm vector cho knowledge_graph
CREATE INDEX idx_entities_normalized
ON knowledge_graph_entities(normalized_name);

CREATE INDEX idx_aliases_normalized
ON knowledge_graph_aliases(normalized_alias);
