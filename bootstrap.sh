#!/usr/bin/env bash
#----------------------------------------
# Hardened, fully defensive bootstrap script
# - Nix-first / fallback to official distributions
# - Idempotent, concurrency-safe
# - Telemetry/logging for all failure modes
# - Environment variable / secrets-aware
# - Adaptive ports for Phoenix LiveView
#----------------------------------------
set -euo pipefail
IFS=$'\n\t'

#----------------------------------------
# CONFIGURATION
#----------------------------------------
PROJECT_NAME="${1:-plume_organism}"
WORKDIR="${PWD}/${PROJECT_NAME}"
GIT_REPO_URL="${2:-}"
PORT="${PORT:-4000}"

LOGFILE="${WORKDIR}/telemetry/bootstrap.log"
LOCKFILE="/tmp/${PROJECT_NAME}.lock"
mkdir -p "$WORKDIR" "$WORKDIR/telemetry"

echo "[$(date --iso-8601=seconds)] Starting bootstrap" >> "$LOGFILE"

#----------------------------------------
# 0. CONCURRENT SAFE
#----------------------------------------
if [ -e "$LOCKFILE" ]; then
  echo "Bootstrap already running, exiting." | tee -a "$LOGFILE"
  exit 1
else
  touch "$LOCKFILE"
  trap "rm -f $LOCKFILE" EXIT
fi

#----------------------------------------
# 1. CREATE PROJECT DIRECTORY
#----------------------------------------
mkdir -p "$WORKDIR" || { echo "ERROR: cannot create $WORKDIR" | tee -a "$LOGFILE"; exit 1; }
cd "$WORKDIR"

#----------------------------------------
# 2. CHECK ENV VARS / SECRETS
#----------------------------------------
: "${MIX_ENV:=dev}"
: "${PORT:?Missing PORT env variable}"
echo "Environment: MIX_ENV=$MIX_ENV PORT=$PORT" >> "$LOGFILE"

#----------------------------------------
# 3. NIX ENVIRONMENT
#----------------------------------------
if command -v nix >/dev/null 2>&1; then
  echo "Using Nix environment" | tee -a "$LOGFILE"
  if [ ! -f "default.nix" ]; then
    mkdir -p nix
    cat > default.nix <<'EOF'
{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  buildInputs = [ pkgs.erlang pkgs.elixir pkgs.nodejs pkgs.git pkgs.curl pkgs.wget ];
  shellHook = ''
    export MIX_ENV=dev
    export PORT=4000
  '';
}
EOF
  fi
  nix-shell --pure --run "echo 'Nix-shell ready'" || { echo "ERROR: nix-shell failed" | tee -a "$LOGFILE"; exit 1; }
  NIX_USED=1
else
  NIX_USED=0
fi

#----------------------------------------
# 4. OFFICIAL DISTRIBUTION FALLBACK
#----------------------------------------
install_official_deps() {
  echo "Installing missing dependencies via official distributions" | tee -a "$LOGFILE"
  declare -a MISSING_DEPS=()
  for dep in erl elixir node; do
    if ! command -v $dep >/dev/null 2>&1; then
      MISSING_DEPS+=($dep)
    fi
  done

  if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo "Missing deps: ${MISSING_DEPS[*]}" | tee -a "$LOGFILE"
    for dep in "${MISSING_DEPS[@]}"; do
      case $dep in
        erl) sudo apt-get install -y esl-erlang ;;
        elixir) sudo apt-get install -y elixir ;;
        node) sudo apt-get install -y nodejs npm ;;
      esac
    done
  fi
}

if [ "$NIX_USED" -eq 0 ]; then
  install_official_deps
fi

#----------------------------------------
# 5. PHOENIX LIVEVIEW SKELETON
#----------------------------------------
if [ ! -d "assets" ]; then
  echo "Creating Phoenix LiveView skeleton" | tee -a "$LOGFILE"
  mix phx.new . --no-ecto --live --app "$PROJECT_NAME" || { echo "ERROR: mix phx.new failed" | tee -a "$LOGFILE"; exit 1; }
fi

#----------------------------------------
# 6. ADAPTIVE PORT CHECK
#----------------------------------------
while lsof -i:$PORT >/dev/null 2>&1; do
  echo "Port $PORT in use, incrementing..." | tee -a "$LOGFILE"
  PORT=$((PORT+1))
done
echo "Using PORT=$PORT" | tee -a "$LOGFILE"

#----------------------------------------
# 7. ENV FILES
#----------------------------------------
for file in .env .dev; do
  if [ ! -f "$file" ]; then
    cat > "$file" <<EOF
MIX_ENV=$MIX_ENV
PORT=$PORT
EOF
  fi
done

#----------------------------------------
# 8. GIT REPO HANDLING
#----------------------------------------
if [[ -n "$GIT_REPO_URL" && ! -d ".git" ]]; then
  git clone "$GIT_REPO_URL" . || { echo "ERROR: git clone failed" | tee -a "$LOGFILE"; exit 1; }
elif [ ! -d ".git" ]; then
  git init
  git add .
  git commit -m "Initial commit: bootstrap project"
fi

#----------------------------------------
# 9. TOOLING REPOS
#----------------------------------------
mkdir -p tools
cd tools
TOOL_REPOS=("https://github.com/elixir-lang/ex_doc.git" "https://github.com/phoenixframework/phoenix_live_view.git")
for repo in "${TOOL_REPOS[@]}"; do
  dir_name=$(basename "$repo" .git)
  if [ ! -d "$dir_name" ]; then
    git clone "$repo" || echo "WARNING: Could not clone $repo" | tee -a "$LOGFILE"
  fi
done
cd ..

#----------------------------------------
# 10. TELEMETRY STUB
#----------------------------------------
echo "{\"last_run\":\"$(date --iso-8601=seconds)\",\"status\":\"success\"}" > telemetry/last_run.json

#----------------------------------------
# 11. SUMMARY
#----------------------------------------
echo "Bootstrap complete!" | tee -a "$LOGFILE"
echo "Project directory: $WORKDIR" | tee -a "$LOGFILE"
echo "Port: $PORT" | tee -a "$LOGFILE"
echo "Nix used: $NIX_USED" | tee -a "$LOGFILE"
echo "Run server: mix phx.server"