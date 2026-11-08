# Running as the cluster agent

You run in a pod (`agent/claude-agent-0`) on the owner's k3s cluster, reached
through Remote Control. Several sessions can run at once in this pod, so keep
your work isolated from the others.

## Workspace

- Clone repositories once into `~/workspace/repos/<owner>/<repo>`
  (`gh repo clone owner/repo ~/workspace/repos/owner/repo`). If it exists,
  `git fetch` instead of cloning again.
- Never edit the main clone directly. For each task, create a worktree on a
  new branch: `git -C ~/workspace/repos/<owner>/<repo> worktree add
  ~/workspace/wt/<repo>-<task> -b agent/<task> origin/main`, and work there.
- Remove the worktree after the PR is opened or the task is dropped
  (`git worktree remove`).

## Changes

- Never push to `main` and never merge. Push your branch and open a PR with
  `gh pr create`; the owner reviews and merges.
- For Kubernetes manifests, check before opening a PR: `kubectl kustomize`
  on changed kustomize dirs, `kubeconform -strict -ignore-missing-schemas` on
  the output.
- Say in the PR what you verified and what you could not.

## Cluster access

- `kubectl` is read-only (ServiceAccount `agent/claude-agent`, bound to
  `view` plus `agent-cluster-read`). No Secrets, exec, port-forward or
  writes. Propose changes as PRs to `rohitpotato/k8s-apps`; Argo CD applies
  them after merge.
- Network: you cannot reach pods, services or node IPs inside the cluster,
  only the API server and the internet.

## Resources

The pod has a 2Gi memory limit shared by every session. Avoid large builds,
long-running servers, or loading huge files; ask first if a task needs them.

## Argo CD and Grafana

- `argocd` is preconfigured (`ARGOCD_SERVER`, and `ARGOCD_OPTS` pointing at
  the mounted config `/var/run/secrets/agent/argocd/config`) as the
  read-only account `agent`: `argocd app list`, `app get`, `app diff`,
  `app history`, `app logs`. Sync, delete and exec are denied by RBAC.
- Grafana API as a Viewer service account, reading the token file on each
  call so a rotated token is picked up:
  `curl -s -H "Authorization: Bearer $(cat /var/run/secrets/agent/grafana/token)" "$GRAFANA_URL/api/search"`.
  Query Prometheus through Grafana's datasource proxy, e.g.
  `"$GRAFANA_URL/api/datasources/proxy/uid/prometheus/api/v1/query?query=up"`
  (look the uid up with `/api/datasources` if that one 404s).
- Token files update within a few minutes of a Vault change, no restart
  needed. If a file is missing or empty, the Vault entry is missing; say so
  instead of working around it.
