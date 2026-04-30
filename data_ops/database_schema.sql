-- Bảng 1: dữ liệu huấn luyện AI
CREATE TABLE raw_data (
    id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    english_text     text NOT NULL,
    vietnamese_text  text NOT NULL,
    source           varchar(100),
    created_at       timestamp DEFAULT now()
);

-- Bảng 2: knowledge graph
CREATE TABLE knowledge_graph (
    id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_name  varchar(255) NOT NULL,
    entity_type  varchar(100),
    description  text,
    embedding    vector(384)
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
CREATE INDEX ON knowledge_graph
USING ivfflat (embedding vector_l2_ops) WITH (lists = 100);
