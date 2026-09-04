"""
In-memory database for FlashFlow.
Pre-seeded with demo users, products, and sample orders.
"""
from passlib.context import CryptContext
from models import Product, Order, OrderItem
from datetime import datetime, timedelta
import uuid

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# ─── Users ─────────────────────────────────────────────────────────────────────
# Stored as: { email: { id, name, email, hashed_password, role } }
users_db: dict[str, dict] = {}


def _seed_users():
    """Create demo admin and customer accounts."""
    users_db["admin@flashflow.dev"] = {
        "id": "usr-admin-001",
        "name": "Ari Morgan",
        "email": "admin@flashflow.dev",
        "hashed_password": pwd_context.hash("admin123"),
        "role": "admin",
    }
    users_db["maya@flashflow.dev"] = {
        "id": "usr-cust-001",
        "name": "Maya Chen",
        "email": "maya@flashflow.dev",
        "hashed_password": pwd_context.hash("user123"),
        "role": "customer",
    }
    users_db["demo@flashflow.dev"] = {
        "id": "usr-cust-002",
        "name": "Demo User",
        "email": "demo@flashflow.dev",
        "hashed_password": pwd_context.hash("demo123"),
        "role": "customer",
    }


_seed_users()


def get_user(email: str) -> dict | None:
    return users_db.get(email.lower())


def create_user(name: str, email: str, password: str, role: str) -> dict:
    email = email.lower()
    user = {
        "id": "usr-" + str(uuid.uuid4())[:8],
        "name": name,
        "email": email,
        "hashed_password": pwd_context.hash(password),
        "role": role,
    }
    users_db[email] = user
    return user


def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)


# ─── Products ──────────────────────────────────────────────────────────────────
products_db: list[dict] = [
    {"id": "p1", "name": "AeroFlex Runner",    "category": "Footwear",     "price": 129.0, "stock": 248, "rating": 4.8, "color": "#dff2ef", "tag": "Fast mover"},
    {"id": "p2", "name": "Orbit Sound Pro",    "category": "Electronics",  "price": 249.0, "stock": 84,  "rating": 4.7, "color": "#e8eef9", "tag": "New arrival"},
    {"id": "p3", "name": "Daybreak Carryall",  "category": "Accessories",  "price": 98.0,  "stock": 132, "rating": 4.6, "color": "#f6eadb", "tag": "Staff pick"},
    {"id": "p4", "name": "Terra Knit Set",     "category": "Apparel",      "price": 149.0, "stock": 61,  "rating": 4.9, "color": "#e9e5f5", "tag": "Limited"},
    {"id": "p5", "name": "Pulse Smartwatch",   "category": "Electronics",  "price": 199.0, "stock": 39,  "rating": 4.5, "color": "#dfeaf3", "tag": "Trending"},
    {"id": "p6", "name": "Cloud Lounge Chair", "category": "Home",         "price": 329.0, "stock": 17,  "rating": 4.8, "color": "#f0e8df", "tag": "Premium"},
]


def get_products(search: str | None = None) -> list[dict]:
    if not search:
        return products_db
    q = search.lower()
    return [p for p in products_db if q in p["name"].lower() or q in p["category"].lower()]


def get_product(product_id: str) -> dict | None:
    return next((p for p in products_db if p["id"] == product_id), None)


# ─── Orders ────────────────────────────────────────────────────────────────────
# Stored as: { user_id: [order, ...] }
orders_db: dict[str, list[dict]] = {}


def _seed_orders():
    now = datetime.now()
    for user_id, orders in [
        ("usr-cust-001", [
            {
                "id": "FF-10482",
                "user_id": "usr-cust-001",
                "items": [
                    {"product_id": "p1", "name": "AeroFlex Runner",  "quantity": 1, "price": 129.0},
                    {"product_id": "p2", "name": "Orbit Sound Pro",  "quantity": 1, "price": 249.0},
                ],
                "total": 378.0,
                "status": "Processing",
                "created_at": (now - timedelta(hours=2)).strftime("%Y-%m-%dT%H:%M:%S"),
                "shipping_address": "123 Commerce Lane, Mumbai",
            },
            {
                "id": "FF-10471",
                "user_id": "usr-cust-001",
                "items": [{"product_id": "p3", "name": "Daybreak Carryall", "quantity": 1, "price": 98.0}],
                "total": 98.0,
                "status": "Delivered",
                "created_at": (now - timedelta(days=1)).strftime("%Y-%m-%dT%H:%M:%S"),
                "shipping_address": "123 Commerce Lane, Mumbai",
            },
            {
                "id": "FF-10443",
                "user_id": "usr-cust-001",
                "items": [{"product_id": "p2", "name": "Orbit Sound Pro", "quantity": 1, "price": 249.0}],
                "total": 249.0,
                "status": "Delivered",
                "created_at": (now - timedelta(days=2)).strftime("%Y-%m-%dT%H:%M:%S"),
                "shipping_address": "123 Commerce Lane, Mumbai",
            },
        ]),
    ]:
        orders_db[user_id] = orders


_seed_orders()


def get_orders(user_id: str) -> list[dict]:
    return orders_db.get(user_id, [])


def get_order(user_id: str, order_id: str) -> dict | None:
    return next((o for o in orders_db.get(user_id, []) if o["id"] == order_id), None)


def create_order(user_id: str, items: list[dict], shipping_address: str) -> dict:
    total = sum(i["price"] * i["quantity"] for i in items)
    order_num = 10500 + len([o for orders in orders_db.values() for o in orders])
    order = {
        "id": f"FF-{order_num}",
        "user_id": user_id,
        "items": items,
        "total": total,
        "status": "Processing",
        "created_at": datetime.now().strftime("%Y-%m-%dT%H:%M:%S"),
        "shipping_address": shipping_address,
    }
    orders_db.setdefault(user_id, []).insert(0, order)
    return order
