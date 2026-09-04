"""Auth router — login, signup, me."""
from fastapi import APIRouter, HTTPException, status, Depends
from models import UserCreate, UserLogin, Token, UserOut
from auth import create_access_token, get_current_user
import database as db

router = APIRouter(prefix="/api/auth", tags=["Auth"])


@router.post("/signup", response_model=Token, status_code=status.HTTP_201_CREATED)
def signup(payload: UserCreate):
    """Create a new account (customer or admin)."""
    if db.get_user(payload.email):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="An account with this email already exists.",
        )
    user = db.create_user(payload.name, payload.email, payload.password, payload.role)
    token_data = {
        "sub":   user["id"],
        "email": user["email"],
        "name":  user["name"],
        "role":  user["role"],
    }
    access_token = create_access_token(token_data)
    return Token(
        access_token=access_token,
        user=UserOut(**{k: user[k] for k in ("id", "name", "email", "role")}),
    )


@router.post("/login", response_model=Token)
def login(payload: UserLogin):
    """Authenticate and receive a JWT."""
    user = db.get_user(payload.email)
    if not user or not db.verify_password(payload.password, user["hashed_password"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    token_data = {
        "sub":   user["id"],
        "email": user["email"],
        "name":  user["name"],
        "role":  user["role"],
    }
    access_token = create_access_token(token_data)
    return Token(
        access_token=access_token,
        user=UserOut(**{k: user[k] for k in ("id", "name", "email", "role")}),
    )


@router.get("/me", response_model=UserOut)
def me(current_user: dict = Depends(get_current_user)):
    """Return the currently authenticated user's profile."""
    return UserOut(
        id=current_user["sub"],
        name=current_user["name"],
        email=current_user["email"],
        role=current_user["role"],
    )
