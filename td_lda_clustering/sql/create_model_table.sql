-- Create model storage table if not exists
CREATE TABLE IF NOT EXISTS model_${set[params].name} (
    time bigint,
    chunk_id int,         -- Chunk identifier (0, 1, 2, ...)
    total_chunks int,     -- Total number of chunks for this model
    model_data varchar,   -- Base64 encoded serialized model chunk
    n_cluster int
);