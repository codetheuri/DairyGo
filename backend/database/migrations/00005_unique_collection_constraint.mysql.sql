-- +goose Up
ALTER TABLE milk_collections 
    ADD CONSTRAINT uq_collections_member_date_shift UNIQUE (sacco_id, member_id, collection_date, shift);

-- +goose Down
ALTER TABLE milk_collections 
    DROP INDEX uq_collections_member_date_shift;
