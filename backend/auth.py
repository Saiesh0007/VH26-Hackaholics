"""
JWT auth utilities + FastAPI dependency helpers.
"""
import os
from datetime import datetime, timedelta, timezone
from typing import Optional

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError, jwt
from dotenv import load_dotenv

load_dotenv()

SECRET_KEY = os.getenv("SECRET_KEY", "flashflow-super-secret-key-change-in-production")
ALGORITHM  = os.getenv("ALGORITHM", "HS256")
EXPIRE_HRS = int(os.getenv("ACCESS_TOKEN_EXPIRE_HOURS", "24"))

bearer_scheme = HTTPBearer()


# ─── Token Creation ───────────────────────────────────────────────────────────

def create_access_token(data: dict) -> str:
    """Create a signed JWT with an expiry."""
    payload = data.copy()
    expire  = datetime.now(timezone.utc) + timedelta(hours=EXPIRE_HRS)
    payload.update({"exp": expire})
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


# ─── Token Verification ───────────────────────────────────────────────────────

def _decode_token(token: str) -> dict:
    try:
        return jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
            headers={"WWW-Authenticate": "Bearer"},
        )


# ─── Dependency: current authenticated user ───────────────────────────────────

def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
) -> dict:
    """FastAPI dependency — returns the decoded user dict from JWT."""
    return _decode_token(credentials.credentials)


# ─── Role Guards ─────────────────────────────────────────────────────────────

def require_admin(user: dict = Depends(get_current_user)) -> dict:
    """Dependency that raises 403 if the caller is not an admin."""
    if user.get("role") != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required",
        )
    return user


def require_customer(user: dict = Depends(get_current_user)) -> dict:
    """Dependency that raises 403 if the caller is not a customer."""
    if user.get("role") != "customer":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Customer access required. Admins cannot place orders.",
        )
    return user
