"""Orders router — customer-only (admins are blocked)."""
from fastapi import APIRouter, Depends, HTTPException, status
from auth import require_customer
from models import OrderCreate
import database as db

router = APIRouter(prefix="/api/orders", tags=["Orders"])

_customer = Depends(require_customer)


@router.get("")
def list_orders(user: dict = _customer):
    """Return all orders for the currently authenticated customer."""
    orders = db.get_orders(user["sub"])
    return {"orders": orders, "total": len(orders)}


@router.get("/{order_id}")
def get_order(order_id: str, user: dict = _customer):
    """Return a single order by ID (must belong to the current customer)."""
    order = db.get_order(user["sub"], order_id)
    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Order '{order_id}' not found.",
        )
    return order


@router.post("", status_code=status.HTTP_201_CREATED)
def place_order(payload: OrderCreate, user: dict = _customer):
    """
    Place a new order (checkout).
    Items are validated against the product catalog before persisting.
    """
    items = []
    for item in payload.items:
        product = db.get_product(item.product_id)
        if not product:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Product '{item.product_id}' not found.",
            )
        if product["stock"] < item.quantity:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Insufficient stock for '{product['name']}'. Available: {product['stock']}.",
            )
        items.append({
            "product_id": item.product_id,
            "name":       product["name"],
            "quantity":   item.quantity,
            "price":      product["price"],
        })

    order = db.create_order(
        user_id=user["sub"],
        items=items,
        shipping_address=payload.shipping_address or "Demo address",
    )
    db.create_event({
        "id": f"evt-order-{order['id']}",
        "type": "ORDER_CREATED",
        "priority": "P0",
        "decision": "STREAM",
        "queue": "P0",
        "pressure": 0,
        "worker": 0,
        "reason": f"Customer order {order['id']} accepted on the critical path",
    })
    return {"order": order, "message": f"Order {order['id']} placed successfully."}
