-- schema.sql
-- PostgreSQL schema for C2C Fashion Marketplace
-- Author: Edgaras
-- Description: Defines all tables including users, listings, transactions, and trust system components.

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