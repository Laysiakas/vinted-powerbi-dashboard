-- USERS
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    join_date DATE NOT NULL,
    rating NUMERIC(3,2) DEFAULT 5.0,
    status VARCHAR(20) DEFAULT 'active'
);

-- CATEGORIES
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50),
    parent_id INT REFERENCES categories(id) ON DELETE SET NULL
);

-- LISTINGS
CREATE TABLE listings (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id),
    title VARCHAR(100),
    price NUMERIC(10,2),
    brand VARCHAR(50),
    condition VARCHAR(20),
    category_id INT REFERENCES categories(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'active'
);

-- TRANSACTIONS
CREATE TABLE transactions (
    id SERIAL PRIMARY KEY,
    buyer_id INT REFERENCES users(id),
    seller_id INT REFERENCES users(id),
    listing_id INT REFERENCES listings(id),
    transacted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_amount NUMERIC(10,2)
);

-- REVIEWS
CREATE TABLE reviews (
    id SERIAL PRIMARY KEY,
    transaction_id INT REFERENCES transactions(id),
    rated_user_id INT REFERENCES users(id),
    rating INT CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- MESSAGES
CREATE TABLE messages (
    id SERIAL PRIMARY KEY,
    sender_id INT REFERENCES users(id),
    receiver_id INT REFERENCES users(id),
    listing_id INT REFERENCES listings(id),
    message_text TEXT,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    read BOOLEAN DEFAULT FALSE
);

-- SHIPPING
CREATE TABLE shipping (
    id SERIAL PRIMARY KEY,
    transaction_id INT REFERENCES transactions(id),
    ship_date DATE,
    delivery_date DATE,
    shipping_cost NUMERIC(6,2),
    status VARCHAR(20)
);

-- REPORTS
CREATE TABLE reports (
    id SERIAL PRIMARY KEY,
    reporter_id INT REFERENCES users(id),
    reported_user_id INT REFERENCES users(id),
    listing_id INT REFERENCES listings(id),
    reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
SELECT
    u.username,
    COUNT(t.id) AS items_sold,
    ROUND(AVG(r.rating), 2) AS avg_rating
FROM users u
JOIN transactions t ON u.id = t.seller_id
LEFT JOIN reviews r ON r.rated_user_id = u.id
GROUP BY u.username
ORDER BY items_sold DESC, avg_rating DESC
LIMIT 10;

SELECT
    u.username,
    COUNT(re.id) AS report_count,
    u.rating
FROM users u
JOIN reports re ON u.id = re.reported_user_id
WHERE u.rating < 3.5
GROUP BY u.username, u.rating
HAVING COUNT(re.id) >= 3
ORDER BY report_count DESC;

WITH messaged_listings AS (
    SELECT DISTINCT listing_id FROM messages
),
sold_listings AS (
    SELECT DISTINCT listing_id FROM transactions
)
SELECT
    (SELECT COUNT(*) FROM messaged_listings) AS total_messaged,
    (SELECT COUNT(*) FROM sold_listings) AS total_sold,
    (SELECT COUNT(*) FROM messaged_listings WHERE listing_id IN (SELECT listing_id FROM sold_listings)) AS converted,
    ROUND(
        100.0 * (
            SELECT COUNT(*) FROM messaged_listings WHERE listing_id IN (SELECT listing_id FROM sold_listings)
        ) / (SELECT COUNT(*) FROM messaged_listings),
        2
    ) AS conversion_rate_percent;

SELECT
    c.name AS category,
    DATE_TRUNC('month', t.transacted_at) AS month,
    COUNT(*) AS transactions,
    ROUND(SUM(t.total_amount), 2) AS revenue
FROM transactions t
JOIN listings l ON l.id = t.listing_id
JOIN categories c ON c.id = l.category_id
GROUP BY c.name, month
ORDER BY month, category;

SELECT
    l.title,
    u.username,
    l.created_at,
    l.price
FROM listings l
JOIN users u ON l.user_id = u.id
LEFT JOIN transactions t ON l.id = t.listing_id
WHERE t.id IS NULL
ORDER BY l.created_at DESC;

SELECT
    u.username AS seller,
    ROUND(AVG(s.delivery_date - s.ship_date), 2) AS avg_delivery_days
FROM shipping s
JOIN transactions t ON s.transaction_id = t.id
JOIN users u ON u.id = t.seller_id
WHERE s.status = 'delivered'
GROUP BY u.username
ORDER BY avg_delivery_days;

TRUNCATE TABLE transactions RESTART IDENTITY CASCADE;

SELECT transacted_at FROM transactions ORDER BY transacted_at LIMIT 10;

SELECT rating, COUNT(*) 
FROM public.reviews 
GROUP BY rating;

CREATE VIEW seller_avg_rating AS
SELECT
    rated_user_id AS seller_id,
    ROUND(AVG(rating), 2) AS avg_rating
FROM reviews
GROUP BY rated_user_id;

UPDATE users
SET rating = sub.avg_rating
FROM (
    SELECT rated_user_id, ROUND(AVG(rating), 2) AS avg_rating
    FROM reviews
    GROUP BY rated_user_id
) sub
WHERE users.id = sub.rated_user_id;


ALTER TABLE users DROP COLUMN rating;

CREATE VIEW seller_avg_ratings AS
SELECT
    u.id AS seller_id,
    u.username,
    ROUND(AVG(r.rating), 2) AS average_rating
FROM users u
JOIN transactions t ON t.seller_id = u.id
JOIN reviews r ON r.transaction_id = t.id AND r.rated_user_id = u.id
GROUP BY u.id, u.username;

ALTER TABLE users DROP COLUMN rating;
-- or if you want to keep it:
ALTER TABLE users ALTER COLUMN rating DROP DEFAULT;

