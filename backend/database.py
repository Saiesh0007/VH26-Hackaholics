"""Supabase data access for FlashFlow."""
import os
import uuid

from dotenv import load_dotenv
from supabase import Client, create_client

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_ANON_KEY = os.getenv("SUPABASE_ANON_KEY")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
if not SUPABASE_URL or not SUPABASE_ANON_KEY or not SUPABASE_SERVICE_ROLE_KEY:
    raise RuntimeError("SUPABASE_URL, SUPABASE_ANON_KEY, and SUPABASE_SERVICE_ROLE_KEY are required")

supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
auth_client: Client = create_client(SUPABASE_URL, SUPABASE_ANON_KEY)


def get_user_by_id(user_id: str) -> dict | None:
    result = supabase.table("profiles").select("*").eq("id", user_id).maybe_single().execute()
    return result.data


def get_products(search: str | None = None) -> list[dict]:
    query = supabase.table("products").select("*").order("created_at")
    if search:
        query = query.or_(f"name.ilike.%{search}%,category.ilike.%{search}%")
    return query.execute().data or []


def get_product(product_id: str) -> dict | None:
    result = supabase.table("products").select("*").eq("id", product_id).maybe_single().execute()
    return result.data


def get_orders(user_id: str) -> list[dict]:
    result = supabase.table("orders").select("*").eq("user_id", user_id).order("created_at", desc=True).execute()
    return result.data or []


def get_order(user_id: str, order_id: str) -> dict | None:
    result = supabase.table("orders").select("*").eq("user_id", user_id).eq("id", order_id).maybe_single().execute()
    return result.data


def create_order(user_id: str, items: list[dict], shipping_address: str) -> dict:
    result = supabase.table("orders").insert({
        "id": f"FF-{uuid.uuid4().hex[:8].upper()}",
        "user_id": user_id,
        "items": items,
        "total": sum(item["price"] * item["quantity"] for item in items),
        "status": "Processing",
        "shipping_address": shipping_address,
    }).execute()
    return result.data[0]

def create_event(event: dict) -> dict:
    result = supabase.table("pipeline_events").insert(event).execute()
    return result.data[0]

def get_events(limit: int = 20) -> list[dict]:
    result = supabase.table("pipeline_events").select("*").order("created_at", desc=True).limit(limit).execute()
    return [
        {
            "id": event["id"],
            "type": event["type"],
            "priority": event["priority"],
            "decision": event["decision"],
            "queue": event["queue"],
            "pressure": event["pressure"],
            "worker": event["worker"],
            "time": event["created_at"].split("T")[-1][:8],
            "reason": event["reason"],
        }
        for event in result.data or []
    ]
