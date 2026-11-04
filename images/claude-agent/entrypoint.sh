#!/usr/bin/env bash
# Runs `claude remote-control` as the container's main process. Kubernetes
# restarts it if it dies, so no tmux is needed to keep it alive. One process
# hosts several sessions (--capacity); each one you open from claude.ai/code or
# the mobile app runs here.
set -euo pipefail

WORKDIR="${AGENT_WORKDIR:-$HOME/workspace}"
mkdir -p "$WORKDIR" "$HOME/.claude"

# Git identity and GitHub auth. GH_TOKEN comes from Vault through ESO; gh acts
# as git's credential helper, so `git push` over https uses the same token.
git config --global user.name  "${GIT_USER_NAME:-claude-agent}"
git config --global user.email "${GIT_USER_EMAIL:-claude-agent@users.noreply.github.com}"
git config --global init.defaultBranch main
if [ -n "${GH_TOKEN:-}" ]; then
  gh auth setup-git
else
  echo "GH_TOKEN is not set (Vault sealed or kv/agent/github missing): GitHub pushes will fail." >&2
fi

# Remote Control needs a claude.ai login and a trusted folder. Both are done
# once by hand (agent-login) and persist on the PVC.
until [ -s "$HOME/.claude/.credentials.json" ]; do
  echo "Not logged in. Run: kubectl -n agent exec -it claude-agent-0 -- agent-login" >&2
  sleep 30
done

cd "$WORKDIR"
exec claude remote-control \
  --name "${AGENT_NAME:-k3s-agent}" \
  --spawn "${AGENT_SPAWN:-same-dir}" \
  --capacity "${AGENT_CAPACITY:-2}"
