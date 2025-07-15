import psycopg2
from faker import Faker
import random
from datetime import datetime, timedelta, date
from tqdm import tqdm

# --- Database Configuration ---
DB_NAME = "fashion_marketplace"
DB_USER = "postgres"
DB_PASSWORD = "123lopas123"
DB_HOST = "localhost"
DB_PORT = "5432"

# --- Connect to DB ---
conn = psycopg2.connect(
    dbname=DB_NAME, user=DB_USER, password=DB_PASSWORD,
    host=DB_HOST, port=DB_PORT
)
cur = conn.cursor()

# ✅ Now safe to run TRUNCATE
cur.execute("""
    TRUNCATE TABLE shipping, reviews, reports, messages,
    transactions, listings, users, categories
    RESTART IDENTITY CASCADE;
""")
conn.commit()

fake = Faker()

# --- Insert Categories ---
categories = ['Shoes', 'Bags', 'Dresses', 'Tops', 'Pants', 'Jackets', 'Accessories', 'Hats', 'Jewelry', 'Activewear']
category_ids = []

for name in categories:
    cur.execute("INSERT INTO categories (name) VALUES (%s) RETURNING id", (name,))
    category_ids.append(cur.fetchone()[0])
conn.commit()

# --- Insert Users ---
used_usernames = set()
used_emails = set()
user_ids = []

for _ in tqdm(range(100), desc="Inserting users"):
    username = fake.user_name()
    email = fake.email()

    # Ensure unique username
    while username in used_usernames:
        username = fake.user_name()
    used_usernames.add(username)

    # Ensure unique email
    while email in used_emails:
        email = fake.email()
    used_emails.add(email)

    join_date = fake.date_between(start_date='-2y', end_date='today')
    status = random.choice(['active', 'inactive', 'banned'])

    cur.execute("""
        INSERT INTO users (username, email, join_date, status)
        VALUES (%s, %s, %s, %s) RETURNING id
    """, (username, email, join_date, status))
    user_ids.append(cur.fetchone()[0])

conn.commit()


# --- Insert Listings ---
listing_ids = []
for _ in tqdm(range(500), desc="Inserting listings"):
    user_id = random.choice(user_ids)
    title = fake.sentence(nb_words=3)
    price = round(random.uniform(5, 200), 2)
    brand = fake.company()
    condition = random.choice(['new', 'good', 'worn'])
    category_id = random.choice(category_ids)
    created_at = fake.date_time_between(start_date='-1y', end_date='now')
    status = random.choice(['active', 'sold', 'expired'])
    cur.execute("""
        INSERT INTO listings (user_id, title, price, brand, condition, category_id, created_at, status)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s) RETURNING id
    """, (user_id, title, price, brand, condition, category_id, created_at, status))
    listing_ids.append(cur.fetchone()[0])
conn.commit()

# --- Insert Transactions ---
for _ in tqdm(range(200), desc="Inserting transactions"):
    listing_id = random.choice(listing_ids)
    seller_id = random.choice(user_ids)
    buyer_id = random.choice([uid for uid in user_ids if uid != seller_id])
# Generate a random date in the past 6 months
    start_date = datetime.today() - timedelta(days=180)
    end_date = datetime.today()

    transacted_at = fake.date_time_between(start_date=start_date, end_date=end_date)

    amount = round(random.uniform(10, 250), 2)
    cur.execute("""
        INSERT INTO transactions (buyer_id, seller_id, listing_id, transacted_at, total_amount)
        VALUES (%s, %s, %s, %s, %s)
    """, (buyer_id, seller_id, listing_id, transacted_at, amount))
conn.commit()

print("Data inserted successfully!")
# --- Insert Reviews ---
print("\nInserting reviews...")

cur = conn.cursor()
for _ in tqdm(range(300), desc="Inserting reviews"):
    # Randomly pick a transaction to review
    cur.execute("SELECT id, seller_id FROM transactions ORDER BY RANDOM() LIMIT 1")
    result = cur.fetchone()
    if not result:
        continue
    transaction_id, rated_user_id = result

    rating = random.randint(1, 5)
    comment = fake.sentence()
    created_at = fake.date_time_between(start_date='-6mon', end_date='now')

    cur.execute("""
        INSERT INTO reviews (transaction_id, rated_user_id, rating, comment, created_at)
        VALUES (%s, %s, %s, %s, %s)
    """, (transaction_id, rated_user_id, rating, comment, created_at))

conn.commit()
print("Reviews inserted.")
# --- Insert Messages ---
print("\nInserting messages...")

for _ in tqdm(range(500), desc="Inserting messages"):
    sender_id = random.choice(user_ids)
    receiver_id = random.choice([uid for uid in user_ids if uid != sender_id])
    listing_id = random.choice(listing_ids)
    message_text = fake.sentence()
    sent_at = fake.date_time_between(start_date='-6mon', end_date='now')
    read = random.choice([True, False])

    cur.execute("""
        INSERT INTO messages (sender_id, receiver_id, listing_id, message_text, sent_at, read)
        VALUES (%s, %s, %s, %s, %s, %s)
    """, (sender_id, receiver_id, listing_id, message_text, sent_at, read))

conn.commit()
print("Messages inserted.")
# --- Insert Reports ---
print("\nInserting reports...")

for _ in tqdm(range(200), desc="Inserting reports"):
    reporter_id = random.choice(user_ids)
    reported_user_id = random.choice([uid for uid in user_ids if uid != reporter_id])
    listing_id = random.choice(listing_ids)
    reason = random.choice([
        "Scam suspicion", "Fake brand", "Offensive content",
        "Broken item", "Wrong category", "Price manipulation"
    ])
    created_at = fake.date_time_between(start_date='-6mon', end_date='now')

    cur.execute("""
        INSERT INTO reports (reporter_id, reported_user_id, listing_id, reason, created_at)
        VALUES (%s, %s, %s, %s, %s)
    """, (reporter_id, reported_user_id, listing_id, reason, created_at))

conn.commit()
print("Reports inserted.")
print("\nInserting shipping records...")

cur.execute("SELECT id FROM transactions")
transaction_ids = [row[0] for row in cur.fetchall()]

six_months_ago = date.today() - timedelta(days=180)
three_days_ago = date.today() - timedelta(days=3)

for tid in tqdm(transaction_ids, desc="Inserting shipping"):
    ship_date = fake.date_between(start_date=six_months_ago, end_date=three_days_ago)
    delivery_date = ship_date + timedelta(days=random.randint(1, 10))
    shipping_cost = round(random.uniform(1.5, 7.0), 2)
    status = random.choice(['shipped', 'delivered', 'failed'])

    cur.execute("""
        INSERT INTO shipping (transaction_id, ship_date, delivery_date, shipping_cost, status)
        VALUES (%s, %s, %s, %s, %s)
    """, (tid, ship_date, delivery_date, shipping_cost, status))

conn.commit()
print("Shipping records inserted.")



cur.close()
conn.close()
