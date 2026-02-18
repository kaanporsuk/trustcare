-- Safety lock for duplicates
ALTER TABLE providers 
ADD CONSTRAINT unique_provider_location 
UNIQUE (name, latitude, longitude);
