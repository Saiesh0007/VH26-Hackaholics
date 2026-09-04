# FlashFlow Backend Startup Script
# Run this from the backend/ directory

Write-Host "Starting FlashFlow FastAPI backend..." -ForegroundColor Cyan
Write-Host ""
Write-Host "API docs will be available at: http://localhost:8000/docs" -ForegroundColor Green
Write-Host "Demo credentials:" -ForegroundColor Yellow
Write-Host "  Admin:    admin@flashflow.dev / admin123" -ForegroundColor Yellow
Write-Host "  Customer: maya@flashflow.dev  / user123" -ForegroundColor Yellow
Write-Host ""

python -m uvicorn main:app --reload --port 8000 --host 0.0.0.0
