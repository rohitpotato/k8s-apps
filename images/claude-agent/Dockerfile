# Claude Code agent for the k3s cluster: the CLI plus the tools it drives
# (git, gh, kubectl, kubeconform). The model runs at Anthropic; this image only
# needs outbound HTTPS. Bump CLAUDE_CODE_VERSION to upgrade: the auto-updater is
# off because the root filesystem is read-only in the pod.
FROM node:22-bookworm-slim

ARG CLAUDE_CODE_VERSION=2.1.311
ARG KUBECTL_VERSION=v1.34.4
ARG KUBECONFORM_VERSION=v0.6.7

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl git gnupg jq less make openssh-client procps \
      python3 ripgrep tmux unzip \
 && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
 && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends gh \
 && rm -rf /var/lib/apt/lists/*

RUN curl -fsSLo /usr/local/bin/kubectl \
      "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
 && chmod +x /usr/local/bin/kubectl \
 && curl -fsSL "https://github.com/yannh/kubeconform/releases/download/${KUBECONFORM_VERSION}/kubeconform-linux-amd64.tar.gz" \
      | tar -xz -C /usr/local/bin kubeconform

RUN npm install -g "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}" \
 && npm cache clean --force

COPY --chmod=0755 entrypoint.sh agent-login /usr/local/bin/

# uid 1000 (`node`). $HOME is the PVC in the pod, so logins, ~/.claude.json
# (folder trust), repos and worktrees survive restarts. Do not set
# CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC: Remote Control needs feature-flag
# evaluation and refuses to start with it.
USER node
ENV HOME=/home/node \
    DISABLE_AUTOUPDATER=1
WORKDIR /home/node
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
