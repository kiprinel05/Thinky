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

# ODBC Driver for SQL Server (Ubuntu / Debian)
# Driver 18 is required for Ubuntu 24.04+; Driver 17 for older versions.
ODBC_INSTALLED=false
if odbcinst -q -d 2>/dev/null | grep -qi "ODBC Driver 18"; then
  ok "ODBC Driver 18 for SQL Server is installed"
  ODBC_INSTALLED=true
elif odbcinst -q -d 2>/dev/null | grep -qi "ODBC Driver 17"; then
  ok "ODBC Driver 17 for SQL Server is installed"
  ODBC_INSTALLED=true
fi

if ! $ODBC_INSTALLED && command -v apt-get &>/dev/null; then
  warn "ODBC Driver not found — installing..."
  # Add Microsoft repo
  if [ ! -f /usr/share/keyrings/microsoft-prod.gpg ]; then
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg
  fi
  UBUNTU_VER=$(lsb_release -rs 2>/dev/null || echo "22.04")
  DISTRO=$(lsb_release -cs 2>/dev/null || echo "jammy")
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/ubuntu/${UBUNTU_VER}/prod ${DISTRO} main" \
    | sudo tee /etc/apt/sources.list.d/mssql-release.list >/dev/null
  sudo apt-get update -qq

  # Try Driver 18 first (Ubuntu 24.04+), fall back to 17
  if sudo ACCEPT_EULA=Y apt-get install -y -qq msodbcsql18 unixodbc-dev 2>/dev/null; then
    ok "Installed ODBC Driver 18 for SQL Server"
    ODBC_INSTALLED=true
  elif sudo ACCEPT_EULA=Y apt-get install -y -qq msodbcsql17 unixodbc-dev 2>/dev/null; then
    ok "Installed ODBC Driver 17 for SQL Server"
    ODBC_INSTALLED=true
  else
    err "Could not install ODBC driver. Install manually:"
    err "  https://learn.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server"
  fi
elif ! $ODBC_INSTALLED; then
  warn "Not a Debian-based system. Install ODBC Driver 18 manually:"
  warn "  https://learn.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server"
fi

# Detect which driver is installed and ensure .env has the right DB_DRIVER
if odbcinst -q -d 2>/dev/null | grep -qi "ODBC Driver 18"; then
  DETECTED_DRIVER="ODBC Driver 18 for SQL Server"
elif odbcinst -q -d 2>/dev/null | grep -qi "ODBC Driver 17"; then
  DETECTED_DRIVER="ODBC Driver 17 for SQL Server"
else
  DETECTED_DRIVER=""
fi

if [ -n "$DETECTED_DRIVER" ] && [ -f ".env" ]; then
  if grep -q "^DB_DRIVER=" .env; then
    sed -i "s|^DB_DRIVER=.*|DB_DRIVER=${DETECTED_DRIVER}|" .env
  else
    echo "DB_DRIVER=${DETECTED_DRIVER}" >> .env
  fi
  ok "DB_DRIVER set to: ${DETECTED_DRIVER}"
elif [ -n "$DETECTED_DRIVER" ]; then
  warn "Remember to add DB_DRIVER=${DETECTED_DRIVER} to your .env"
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
