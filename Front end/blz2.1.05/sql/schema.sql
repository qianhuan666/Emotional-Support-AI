CREATE TABLE IF NOT EXISTS users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(64) NOT NULL UNIQUE,
    password_hash CHAR(64) NOT NULL,
    display_name VARCHAR(100) NULL,
    status VARCHAR(16) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS conversations (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    title VARCHAR(200) NOT NULL,
    conversation_type VARCHAR(32) NOT NULL DEFAULT 'AI_CHAT',
    status VARCHAR(16) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_conversations_user_id FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS messages (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    conversation_id BIGINT NOT NULL,
    user_id BIGINT NULL,
    role VARCHAR(16) NOT NULL,
    content MEDIUMTEXT NOT NULL,
    content_type VARCHAR(32) NOT NULL DEFAULT 'TEXT',
    provider_message_id VARCHAR(128) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_messages_conversation_id FOREIGN KEY (conversation_id) REFERENCES conversations(id),
    CONSTRAINT fk_messages_user_id FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS model_call_logs (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    conversation_id BIGINT NULL,
    message_id BIGINT NULL,
    provider VARCHAR(32) NOT NULL,
    model VARCHAR(64) NOT NULL,
    request_status VARCHAR(16) NOT NULL,
    request_latency_ms INT NULL,
    prompt_tokens INT NULL,
    completion_tokens INT NULL,
    error_message VARCHAR(500) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_model_logs_conversation_id FOREIGN KEY (conversation_id) REFERENCES conversations(id),
    CONSTRAINT fk_model_logs_message_id FOREIGN KEY (message_id) REFERENCES messages(id)
);

CREATE TABLE IF NOT EXISTS workspace_state (
    user_id BIGINT PRIMARY KEY,
    mood_value VARCHAR(32) NULL,
    mood_label VARCHAR(64) NULL,
    mood_count INT NOT NULL DEFAULT 0,
    journal_content MEDIUMTEXT NULL,
    journal_saved_at VARCHAR(64) NULL,
    plan_json LONGTEXT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_workspace_state_user_id FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS workspace_state (
    user_id BIGINT PRIMARY KEY,
    mood_value VARCHAR(32) NULL,
    mood_label VARCHAR(64) NULL,
    mood_count INT NOT NULL DEFAULT 0,
    journal_content MEDIUMTEXT NULL,
    journal_saved_at VARCHAR(64) NULL,
    plan_json LONGTEXT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_workspace_state_user_id FOREIGN KEY (user_id) REFERENCES users(id)
);
