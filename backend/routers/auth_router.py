"""Auth router — login, signup, me."""
from fastapi import APIRouter, HTTPException, status, Depends
from models import UserCreate, UserLogin, Token, UserOut
from auth import get_current_user
import database as db

router = APIRouter(prefix="/api/auth", tags=["Auth"])


def _user_out(user) -> UserOut:
    profile = db.get_user_by_id(str(user.id)) or {}
    metadata = user.user_metadata or {}
    return UserOut(
        id=str(user.id),
        name=profile.get("name") or metadata.get("name") or user.email.split("@")[0],
        email=user.email,
        role=profile.get("role") or metadata.get("role") or "customer",
    )


@router.post("/signup", response_model=Token, status_code=status.HTTP_201_CREATED)
def signup(payload: UserCreate):
    result = db.auth_client.auth.sign_up({"email": payload.email, "password": payload.password, "options": {"data": {"name": payload.name, "role": "customer"}}})
    if not result.user or not result.session:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Email confirmation is required.")
    return Token(access_token=result.session.access_token, user=_user_out(result.user))


@router.post("/login", response_model=Token)
def login(payload: UserLogin):
    result = db.auth_client.auth.sign_in_with_password({"email": payload.email, "password": payload.password})
    if not result.user or not result.session:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Incorrect email or password.")
    return Token(access_token=result.session.access_token, user=_user_out(result.user))


@router.get("/me", response_model=UserOut)
def me(current_user: dict = Depends(get_current_user)):
    """Return the currently authenticated user's profile."""
    return UserOut(
        id=current_user["sub"],
        name=current_user["name"],
        email=current_user["email"],
        role=current_user["role"],
    )
