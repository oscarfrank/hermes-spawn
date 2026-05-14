# hermes-spawn

Spin up named [Hermes Agent](https://hermes-agent.nousresearch.com) instances in Docker with a single command. Each instance gets its own data directory, its own gateway, and its own shell command.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/oscarfrank/hermes-spawn/main/install.sh | bash
```

## Updating hermes-spawn

`install.sh` always downloads the current `hermes-spawn` from the `main` branch and overwrites `/usr/local/bin/hermes-spawn` if it is already there. So after you push a new version:

```bash
curl -fsSL https://raw.githubusercontent.com/oscarfrank/hermes-spawn/main/install.sh | bash
```

That is the full update. Running containers and data under `~/hermes-spawn/<name>` are unchanged; the tool on disk is just replaced.

If you installed with the manual one-liner (curl straight to the script), re-run that same one-liner to refresh the binary.

## Use

**1. Spawn an instance:**

```bash
hermes-spawn <name>
```

Example: `hermes-spawn hermes`

The setup wizard will run interactively — enter your API keys and any chat platform tokens when prompted.

**2. Activate the alias:**

```bash
source ~/.bashrc
```

> Run this after every spawn. New SSH sessions read `~/.bashrc` automatically, so you only need it in the session where you just spawned.

**3. Chat with your instance:**

```bash
<name>
```

Example: `hermes` — drops you into chat. Use `/exit` or Ctrl+D to leave.

That's it.

## Multiple instances

Each instance is independent — its own config, memory, and bot tokens.

```bash
hermes-spawn assistant
hermes-spawn support
hermes-spawn research
source ~/.bashrc          # one source picks up all new aliases
```

Then `assistant`, `support`, and `research` are all separate commands.

Ports are auto-assigned starting at 8642, bound to `127.0.0.1` only.

## Prerequisites

- Linux server (tested on Ubuntu/Debian)
- [Docker](https://docs.docker.com/engine/install/) installed and running
- `bash`, `curl`, and standard GNU coreutils (already present on most distros)

## Naming rules

- Lowercase letters, numbers, and hyphens only
- Must start with a letter or number
- Cannot match a reserved system command (`ls`, `docker`, `git`, etc.)
- Cannot collide with an existing Docker container, data directory, alias, or binary on PATH

If any conflict is detected, the script aborts cleanly without changing anything.

## Managing instances

**Update an instance to the latest Hermes image (pull + recreate container, data unchanged):**

```bash
hermes-spawn update <name>
hermes-spawn update hermes              # example
hermes-spawn update hermes --no-pull    # recreate from local image only
hermes-spawn update hermes --image nousresearch/hermes-agent:<tag>
```

By default, `update` runs `docker pull nousresearch/hermes-agent` (the `latest` tag), stops and removes the existing container, then starts a new one with the same data directory, host port, and `HERMES_UID` / `HERMES_GID` settings. Your `~/.bashrc` alias is unchanged. Expect a short gateway outage during the swap.

**Remove an instance (container, `~/.bashrc` block, and data):**

```bash
hermes-spawn remove <name>   # interactive prompt if data is non-empty; use -y in scripts/CI
hermes-spawn remove <name> --keep-data   # drop the container and alias, keep ~/hermes-spawn/<name>
hermes-spawn rm <name> -y   # same as `remove` but delete data without asking
```

**Other useful commands:**

```bash
docker ps                    # list running instances
docker logs -f <name>        # tail an instance's logs
docker stop <name>           # stop the gateway
docker start <name>          # start it again
```

You can still `docker rm -f <name>` to drop only the container (data under `~/hermes-spawn/<name>` and the shell alias in `~/.bashrc` stay — use `hermes-spawn remove` for a full cleanup).

## Manual install

If you prefer not to pipe to bash:

```bash
sudo curl -fsSL https://raw.githubusercontent.com/oscarfrank/hermes-spawn/main/hermes-spawn -o /usr/local/bin/hermes-spawn
sudo chmod +x /usr/local/bin/hermes-spawn
```

## Security notes

- **Gateway ports are bound to `127.0.0.1` by default.** They are not reachable from the internet. To access remotely, use SSH tunneling, Tailscale, or a reverse proxy with authentication. The Hermes gateway has no built-in auth.
- **Do not reuse bot tokens** across instances. Hermes has built-in token locks that will refuse to start a second gateway with the same token, but it's cleaner to use unique tokens from the start.
- **API key budget alerts.** Customer-facing instances can rack up costs fast if abused. Set spending limits in your provider's dashboard.
- **The data directory is `chmod 777`** to work around Docker UID/GID mismatches. On a single-user VPS this is fine; on shared hosts, restrict access to the parent directory.

## Uninstall

`hermes-spawn` is a single file on disk (and optional `install.sh` if someone saved it). Nothing is registered with systemd, your package manager, or apt—so uninstalling the **tool** is just deleting that file:

```bash
sudo rm /usr/local/bin/hermes-spawn
```

(If you put it somewhere else, remove that path, or run `which hermes-spawn` to see where the shell is using it from.)

**That only removes the helper script.** Any Hermes containers, data under `~/hermes-spawn/`, and aliases in `~/.bashrc` are still there. Before or after you delete the binary, tear down each instance if you no longer want them (while `hermes-spawn` is still on disk you can use `hermes-spawn remove <name> -y`; after removal, use `docker rm -f <name>`, `rm -rf ~/hermes-spawn/<name>`, and delete the `hermes-spawn` `alias` / comment lines from `~/.bashrc` as in [Managing instances](#managing-instances)). Then optionally remove the empty `~/hermes-spawn` directory.

## How it works

`hermes-spawn` is a thin bash script around a few Docker commands, plus `update` and `remove` / `rm` subcommands. On the host, each instance's files live in `~/hermes-spawn/<name>` and are bind-mounted to `/opt/data` in the container. To create an instance, it:

1. Validates inputs and detects conflicts
2. Calls `docker run ... setup` interactively for the wizard
3. Calls `docker run -d ... gateway run` to start the persistent service
4. Appends `alias <name>='docker exec -it <name> /opt/hermes/.venv/bin/hermes'` to `~/.bashrc`

`hermes-spawn remove <name>` does the reverse: `docker rm -f`, prunes the alias block, and (unless `--keep-data`) removes `~/hermes-spawn/<name>` after a prompt or ` -y` / `--yes` in non-interactive environments.

`hermes-spawn update <name>` pulls a new image (by default `nousresearch/hermes-agent`), reads the existing container's port mapping, data mount, and env vars, recreates the gateway container, and leaves data and aliases in place.

Read the script — it's plain bash with no dependencies beyond Docker and standard Unix tools. <https://github.com/oscarfrank/hermes-spawn/blob/main/hermes-spawn>

## License

MIT
