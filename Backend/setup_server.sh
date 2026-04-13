#!/usr/bin/env bash
# ============================================================================
#  Thinky Backend — Server Setup Script
#
#  Usage:
#    chmod +x setup_server.sh
#    ./setup_server.sh          # full setup (deps + venv + pip)
#    ./setup_server.sh --run    # full setup then start the server
#    ./setup_server.sh --start  # skip setup, just start the server
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[ERROR]${NC} $1"; }

# ── Parse flags ──────────────────────────────────────────────
RUN_AFTER=false
START_ONLY=false
for arg in "$@"; do
  case "$arg" in
    --run)   RUN_AFTER=true ;;
    --start) START_ONLY=true ;;
  esac
done

start_server() {
  echo ""
  echo "========================================="
  echo "  Starting Thinky Backend"
  echo "========================================="
  source venv/bin/activate 2>/dev/null || source venv/Scripts/activate 2>/dev/null
  exec uvicorn main:app --host 0.0.0.0 --port 8000 --workers 1
}

if $START_ONLY; then
  start_server
fi

echo "========================================="
echo "  Thinky Backend — Server Setup"
echo "========================================="
echo ""

# ── 1. OS dependencies ──────────────────────────────────────
echo "── Step 1: System dependencies ──"

if ! command -v python3 &>/dev/null; then
  err "Python 3 is not installed. Install Python 3.10+ first."
  exit 1
fi
ok "Python 3 found: $(python3 --version)"

# ODBC Driver 17 for SQL Server (Ubuntu / Debian)
if ! odbcinst -q -d 2>/dev/null | grep -qi "ODBC Driver 17"; then
  warn "ODBC Driver 17 not found — installing..."
  if command -v apt-get &>/dev/null; then
    if ! dpkg -l | grep -q msodbcsql17; then
      sudo apt-get update -qq
      sudo ACCEPT_EULA=Y apt-get install -y -qq msodbcsql17 unixodbc-dev 2>/dev/null || {
        warn "msodbcsql17 not in default repos — adding Microsoft repo..."
        curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg
        DISTRO=$(lsb_release -cs 2>/dev/null || echo "jammy")
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/ubuntu/$(lsb_release -rs)/prod $DISTRO main" | sudo tee /etc/apt/sources.list.d/mssql-release.list
        sudo apt-get update -qq
        sudo ACCEPT_EULA=Y apt-get install -y -qq msodbcsql17 unixodbc-dev
      }
    fi
  else
    warn "Not a Debian-based system. Install ODBC Driver 17 manually:"
    warn "  https://learn.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server"
  fi
fi

if odbcinst -q -d 2>/dev/null | grep -qi "ODBC Driver 17"; then
  ok "ODBC Driver 17 for SQL Server is installed"
else
  warn "Could not verify ODBC Driver 17. The server may fail to connect to the database."
fi

# ── 2. Virtual environment ──────────────────────────────────
echo ""
echo "── Step 2: Python virtual environment ──"

if [ ! -d "venv" ]; then
  python3 -m venv venv
  ok "Created virtual environment: venv/"
else
  ok "Virtual environment already exists"
fi

source venv/bin/activate 2>/dev/null || source venv/Scripts/activate 2>/dev/null
ok "Activated venv ($(python --version))"

# ── 3. Pip dependencies ────────────────────────────────────
echo ""
echo "── Step 3: Installing Python dependencies ──"

pip install --upgrade pip -q
pip install -r requirements.txt -q
ok "All pip packages installed"

# ── 4. Environment file ────────────────────────────────────
echo ""
echo "── Step 4: Environment configuration ──"

if [ ! -f ".env" ]; then
  if [ -f ".env.example" ]; then
    cp .env.example .env
    warn "Created .env from .env.example — EDIT IT with your real credentials!"
    warn "  nano $SCRIPT_DIR/.env"
  else
    err ".env file missing and no .env.example found."
    err "Create a .env file with: DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD, SECRET_KEY"
    exit 1
  fi
else
  ok ".env file found"
fi

# Quick .env validation
MISSING_VARS=()
for var in DB_HOST DB_PORT DB_NAME DB_USER DB_PASSWORD SECRET_KEY; do
  if ! grep -q "^${var}=" .env 2>/dev/null; then
    MISSING_VARS+=("$var")
  fi
done
if [ ${#MISSING_VARS[@]} -gt 0 ]; then
  warn "Missing variables in .env: ${MISSING_VARS[*]}"
  warn "The server may not start correctly."
else
  ok "All required .env variables present"
fi

# ── 5. Quick import test ───────────────────────────────────
echo ""
echo "── Step 5: Verifying backend imports ──"

python -c "
import sys
try:
    from features.drawing.service import drawing_service
    from features.animals.model import AnimalClassifier
    print('[OK] Drawing service loaded')
    print('[OK] Animals ML model loaded')
except Exception as e:
    print(f'[!] Import warning: {e}')
    print('    (Non-critical — the server may still start)')
" 2>&1

# ── 6. Done ────────────────────────────────────────────────
echo ""
echo "========================================="
echo "  Setup complete!"
echo "========================================="
echo ""
echo "  To start the server:"
echo "    cd $SCRIPT_DIR"
echo "    source venv/bin/activate"
echo "    uvicorn main:app --host 0.0.0.0 --port 8000"
echo ""
echo "  Or simply run:"
echo "    ./setup_server.sh --start"
echo ""

if $RUN_AFTER; then
  start_server
fi
