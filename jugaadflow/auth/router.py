from fastapi import APIRouter, HTTPException, Depends, status
from pydantic import BaseModel, EmailStr

from jugaadflow.auth.supabase_client import get_supabase
from jugaadflow.auth.jwt import create_access_token
from jugaadflow.auth.deps import get_current_user

router = APIRouter(prefix="/api/auth", tags=["auth"])


class SignupRequest(BaseModel):
    email: EmailStr
    password: str
    name: str
    role: str = "viewer"


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: dict


@router.post("/signup", response_model=TokenResponse)
async def signup(req: SignupRequest):
    if req.role not in ("admin", "viewer"):
        raise HTTPException(status_code=400, detail="Role must be 'admin' or 'viewer'")

    sb = get_supabase()
    try:
        result = sb.auth.admin.create_user({
            "email": req.email,
            "password": req.password,
            "email_confirm": True,
            "user_metadata": {"role": req.role, "name": req.name},
        })
    except Exception as e:
        msg = str(e)
        if "already been registered" in msg or "unique" in msg.lower():
            raise HTTPException(status_code=409, detail="Email already registered")
        raise HTTPException(status_code=400, detail=msg)

    user_data = {
        "sub": str(result.user.id),
        "email": result.user.email,
        "role": req.role,
        "name": req.name,
    }
    token = create_access_token(user_data)
    return TokenResponse(access_token=token, user=user_data)


@router.post("/login", response_model=TokenResponse)
async def login(req: LoginRequest):
    sb = get_supabase()
    try:
        result = sb.auth.sign_in_with_password({
            "email": req.email,
            "password": req.password,
        })
    except Exception as e:
        raise HTTPException(status_code=401, detail="Invalid email or password")

    meta = result.user.user_metadata or {}
    user_data = {
        "sub": str(result.user.id),
        "email": result.user.email,
        "role": meta.get("role", "viewer"),
        "name": meta.get("name", ""),
    }
    token = create_access_token(user_data)
    return TokenResponse(access_token=token, user=user_data)


@router.get("/me")
async def get_me(user: dict = Depends(get_current_user)):
    return user


@router.post("/update-role")
async def update_role(
    target_email: str,
    new_role: str,
    user: dict = Depends(get_current_user),
):
    if user.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Only admins can change roles")
    if new_role not in ("admin", "viewer"):
        raise HTTPException(status_code=400, detail="Role must be 'admin' or 'viewer'")

    sb = get_supabase()
    users = sb.auth.admin.list_users()
    target = next((u for u in users if u.email == target_email), None)
    if target is None:
        raise HTTPException(status_code=404, detail="User not found")

    sb.auth.admin.update_user_by_id(
        str(target.id),
        {"user_metadata": {**(target.user_metadata or {}), "role": new_role}},
    )
    return {"email": target_email, "role": new_role}
