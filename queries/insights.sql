-- insights.sql
-- Advanced SQL queries for analytics and business intelligence
-- Includes seller performance, fraud detection, delivery metrics, and conversion analysis

--Top 10 Sellers by Rating and Volume
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
--Suspicious Users: Low Rating + Many Reports
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

--Message → Sale Conversion Rate
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

--Revenue by Category Over Time
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

--Listings That Never Sold
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

--Average Delivery Times per Seller
SELECT
    u.username AS seller,
    ROUND(AVG(s.delivery_date - s.ship_date), 2) AS avg_delivery_days
FROM shipping s
JOIN transactions t ON s.transaction_id = t.id
JOIN users u ON u.id = t.seller_id
WHERE s.status = 'delivered'
GROUP BY u.username
ORDER BY avg_delivery_days;
