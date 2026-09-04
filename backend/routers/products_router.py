"""Products router — accessible by both roles (authenticated)."""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from auth import get_current_user
import database as db

router = APIRouter(prefix="/api/products", tags=["Products"])

_auth = Depends(get_current_user)


@router.get("")
def list_products(
    search: str | None = Query(default=None, description="Filter by name or category"),
    user: dict = _auth,
):
    """Return all products, optionally filtered by search query."""
    return {"products": db.get_products(search)}


@router.get("/{product_id}")
def get_product(product_id: str, user: dict = _auth):
    """Return a single product by ID."""
    product = db.get_product(product_id)
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Product '{product_id}' not found.",
        )
    return product
