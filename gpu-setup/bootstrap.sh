#!/usr/bin/env bash
# bootstrap.sh - idempotent setup for claude code on GPU instances
# usage: curl -fsSL <raw-url>/bootstrap.sh | bash
set -euo pipefail

echo "=== claude code gpu bootstrap ==="

# ---- detect persistent storage ----
if [ -d "/workspace" ]; then
    PERSIST_DIR="/workspace"
    echo "detected runpod (/workspace)"
else
    PERSIST_DIR="$HOME"
    echo "using home dir ($HOME)"
fi

# ---- check api key ----
if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
    echo "error: ANTHROPIC_API_KEY is not set. export it and re-run."
    exit 1
fi

# ---- system deps ----
echo "--- system deps ---"
NEED_APT=false
for cmd in git curl jq; do
    if ! command -v "$cmd" > /dev/null 2>&1; then
        NEED_APT=true
        break
    fi
done
# also check build-essential via dpkg
if ! dpkg -s build-essential > /dev/null 2>&1; then
    NEED_APT=true
fi

if [ "$NEED_APT" = true ]; then
    echo "installing system deps..."
    apt-get update -qq
    apt-get install -y -qq git curl jq build-essential > /dev/null
else
    echo "system deps already installed"
fi

# ---- node 22.x ----
echo "--- node ---"
if ! command -v node > /dev/null 2>&1; then
    echo "installing node 22.x..."
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash - > /dev/null 2>&1
    apt-get install -y -qq nodejs > /dev/null
    echo "node $(node --version) installed"
else
    echo "node $(node --version) already installed"
fi

# ---- bun ----
echo "--- bun ---"
if ! command -v bun > /dev/null 2>&1; then
    echo "installing bun..."
    curl -fsSL https://bun.sh/install | bash > /dev/null 2>&1
    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"
    echo "bun installed"
else
    echo "bun already installed"
fi

# ---- uv ----
echo "--- uv ---"
if ! command -v uv > /dev/null 2>&1; then
    echo "installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh > /dev/null 2>&1
    export PATH="$HOME/.local/bin:$PATH"
    echo "uv installed"
else
    echo "uv already installed"
fi

# ---- pipx ----
echo "--- pipx ---"
if ! command -v pipx > /dev/null 2>&1; then
    echo "installing pipx..."
    apt-get install -y -qq pipx > /dev/null 2>&1 || pip install --user pipx > /dev/null 2>&1
    pipx ensurepath > /dev/null 2>&1
    export PATH="$HOME/.local/bin:$PATH"
    echo "pipx installed"
else
    echo "pipx already installed"
fi

# ---- claude code ----
echo "--- claude code ---"
if ! command -v claude > /dev/null 2>&1; then
    echo "installing claude code..."
    npm install -g @anthropic-ai/claude-code > /dev/null 2>&1
    echo "claude code installed"
else
    echo "claude code already installed"
fi

# ---- clone config repo ----
echo "--- config repo ---"
CONFIG_DIR="$PERSIST_DIR/claude-code-config"
REPO_URL="https://github.com/tomzhengy/claude-code.git"

if [ -d "$CONFIG_DIR/.git" ]; then
    echo "config repo exists, pulling latest..."
    git -C "$CONFIG_DIR" pull --ff-only -q 2>/dev/null || echo "pull failed (maybe dirty), continuing with existing"
else
    echo "cloning config repo..."
    # try https with token header first (avoids leaking token in .git/config),
    # then plain https, then ssh
    if [ -n "${GITHUB_PERSONAL_ACCESS_TOKEN:-}" ]; then
        git -c "http.https://github.com/.extraheader=Authorization: token ${GITHUB_PERSONAL_ACCESS_TOKEN}" \
            clone -q "$REPO_URL" "$CONFIG_DIR"
    elif git clone -q "$REPO_URL" "$CONFIG_DIR" 2>/dev/null; then
        true
    else
        git clone -q "git@github.com:tomzhengy/claude-code.git" "$CONFIG_DIR"
    fi
    echo "config repo cloned"
fi

# ---- symlinks ----
echo "--- symlinks ---"
CLAUDE_DIR="$HOME/.claude"
mkdir -p "$CLAUDE_DIR"

CONF_BASE="$CONFIG_DIR/claude-code"

# symlink directories
for dir in agents commands rules; do
    target="$CONF_BASE/$dir"
    link="$CLAUDE_DIR/$dir"
    if [ -e "$link" ] && [ ! -L "$link" ]; then
        echo "warning: $link exists and is not a symlink, backing up"
        mv "$link" "${link}.bak"
    fi
    ln -sfn "$target" "$link"
    echo "  $link -> $target"
done

# symlink individual files
ln -sf "$CONF_BASE/config/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
echo "  $CLAUDE_DIR/CLAUDE.md -> $CONF_BASE/config/CLAUDE.md"

ln -sf "$CONF_BASE/config/statusline-command.sh" "$CLAUDE_DIR/statusline-command.sh"
chmod +x "$CONF_BASE/config/statusline-command.sh"
echo "  $CLAUDE_DIR/statusline-command.sh -> $CONF_BASE/config/statusline-command.sh"

# ---- generate settings.json (strip macOS-only hooks) ----
echo "--- settings.json ---"
SOURCE_SETTINGS="$CONF_BASE/config/settings.json"
TARGET_SETTINGS="$CLAUDE_DIR/settings.json"

# strip macOS-only entries: afplay hooks (Notification, PermissionRequest, Stop) and swift-lsp plugin
# denylist approach so new top-level keys are preserved automatically
jq 'del(.hooks.Notification, .hooks.PermissionRequest, .hooks.Stop, .enabledPlugins)' \
    "$SOURCE_SETTINGS" > "$TARGET_SETTINGS"
echo "  settings.json generated (macOS hooks stripped)"

# ---- write ~/.claude.json (MCP servers) ----
echo "--- mcp config ---"
MCP_FILE="$HOME/.claude.json"

# build MCP config, only include servers whose tokens are set
MCP_JSON='{"mcpServers":{}}'

if [ -n "${GITHUB_PERSONAL_ACCESS_TOKEN:-}" ]; then
    MCP_JSON=$(echo "$MCP_JSON" | GITHUB_PERSONAL_ACCESS_TOKEN="$GITHUB_PERSONAL_ACCESS_TOKEN" \
        jq '.mcpServers.Github = {
            "command": "npx",
            "args": ["-y", "@modelcontextprotocol/server-github"],
            "env": {
                "GITHUB_PERSONAL_ACCESS_TOKEN": env.GITHUB_PERSONAL_ACCESS_TOKEN
            }
        }')
    echo "  github MCP configured"
else
    echo "  github MCP skipped (no GITHUB_PERSONAL_ACCESS_TOKEN)"
fi

if [ -n "${NIA_API_KEY:-}" ]; then
    MCP_JSON=$(echo "$MCP_JSON" | NIA_API_KEY="$NIA_API_KEY" \
        jq '.mcpServers.nia = {
            "command": "pipx",
            "args": ["run", "--no-cache", "nia-mcp-server"],
            "env": {
                "NIA_API_KEY": env.NIA_API_KEY,
                "NIA_API_URL": "https://apigcp.trynia.ai/"
            }
        }')
    echo "  nia MCP configured"
else
    echo "  nia MCP skipped (no NIA_API_KEY)"
fi

echo "$MCP_JSON" | jq '.' > "$MCP_FILE"
echo "  wrote $MCP_FILE"

# ---- persist PATH to .bashrc ----
echo "--- bashrc ---"
BASHRC="$HOME/.bashrc"
touch "$BASHRC"

add_to_bashrc() {
    local line="$1"
    if ! grep -qF "$line" "$BASHRC"; then
        echo "$line" >> "$BASHRC"
        echo "  added: $line"
    fi
}

add_to_bashrc 'export PATH="$HOME/.bun/bin:$PATH"'
add_to_bashrc 'export PATH="$HOME/.local/bin:$PATH"'
add_to_bashrc 'export BUN_INSTALL="$HOME/.bun"'

echo ""
echo "=== bootstrap complete ==="
echo "run: claude"
