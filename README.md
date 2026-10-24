# hermes-spawn

Spin up named [Hermes Agent](https://hermes-agent.nousresearch.com) instances in Docker with a single command. Each instance gets its own data directory, its own gateway, and its own shell command.

```bash
hermes-spawn <name>                 # create a new instance
hermes-spawn restore <name>         # recreate container from existing data
hermes-spawn dashboard <name>       # enable web dashboard (+ browser Chat tab)
hermes-spawn connect <name>         # use it from your phone (Hermsy): one command, one scan
hermes-spawn update <name>          # pull latest image and recreate container
hermes-spawn remove <name>          # tear down instance (container, alias, data)
```

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

**4. (Optional) Enable the web dashboard:**

```bash
hermes-spawn dashboard <name>
```

Example: `hermes-spawn dashboard hermes` — prompts for a dashboard username/password, then opens a browser UI at `http://127.0.0.1:<port>` (dashboard port starts at 9119). The Chat tab is on by default. See [Managing instances](#managing-instances) for `--no-tui`, `--oauth`, `--disable`, and remote access.

**5. (Optional) Use it from your phone:**

```bash
hermes-spawn connect <name>
```

Sets everything up for [Hermsy](#use-it-from-your-phone-hermsy), the phone app for Hermes, and ends with a QR code to scan. A new instance offers this at the end of `hermes-spawn <name>`.

That's it.

## Use it from your phone (Hermsy)

[Hermsy](https://play.google.com/store/apps/details?id=com.illbytes.hermsy_app) is a phone app for your Hermes: chat, voice calls, an Inbox for what Hermes sends on its own, and a daily Brief. To use it, your phone needs to reach Hermes over HTTPS. `connect` does all of it:

```bash
hermes-spawn connect hermes
```

1. **Switches on Hermes's API server**, with a strong random key (an existing key is kept).
2. **Installs the [Hermsy plugin](https://github.com/illBytes/hermsy-hermes)** and restarts the instance.
3. **Gives Hermes an HTTPS address** your phone can reach. It suggests the right way for your machine; press Enter to accept:

   | | Best for | You do |
   |---|---|---|
   | **Caddy** | A server with a public IP (most VPSs) | Nothing: an automatic address like `https://<name>.203-0-113-5.sslip.io`, one per instance. Or type your own domain and add one DNS record. |
   | **Cloudflare Tunnel** | A machine at home; no open ports | Click one login link (your domain must be on Cloudflare). |
   | **Tailscale** | Keeping Hermes private | Click one login link; install Tailscale on your phone. |

   Caddy and Tailscale are installed if missing (after asking). An existing Caddyfile gets one marked site, after a backup, and is validated before reloading. `connect` stops rather than taking over ports used by another web server.
4. **Checks it end to end**: the address answers over HTTPS, and the plugin answers with your key.
5. **Prints a QR code.** In Hermsy, tap **Scan QR code** (on the first screen, or Settings › Hermes) and point the phone at it. Hermsy fills in the address and key, checks them, and connects.

Push notifications need nothing on your side: the plugin calls out to Hermsy's push service, so there is no extra port or DNS record for them.

```bash
hermes-spawn connect hermes --status      # API server, plugin, address: is it all working?
hermes-spawn connect hermes --show-key    # print the key too, to type it in by hand
hermes-spawn connect hermes --off         # stop sharing it (removes the Caddy site / tunnel / Tailscale serve)
hermes-spawn connect hermes --caddy --domain hermes.example.com   # skip the questions
```

Running `connect` again is safe: it keeps what already works and fixes what doesn't. `hermes-spawn remove <name>` takes the instance's address down with it, and `connect` clears away any address left by an instance that no longer exists.

> **Security.** With Caddy or Cloudflare, your agent is reachable from the internet, guarded by its API key (64 random characters). Anyone with the key can use your agent, so keep the QR code and key private. With Tailscale, nothing is public at all.
>
> If your Hermes takes its key from a secret manager (Bitwarden etc.) rather than `.env`, `connect` notices and asks you to paste it for the QR code, or you type it in Hermsy yourself.

## Multiple instances

Each instance is independent — its own config, memory, and bot tokens.

```bash
hermes-spawn assistant
hermes-spawn support
hermes-spawn research
source ~/.bashrc          # one source picks up all new aliases
```

Then `assistant`, `support`, and `research` are all separate commands.

Ports are auto-assigned starting at 8642 (gateway) and 9119 (dashboard, when enabled), bound to `127.0.0.1` only. `connect` works per instance; with Tailscale, the second instance gets port 8443 on your tailnet name.

## Prerequisites

- Linux server (tested on Ubuntu/Debian)
- [Docker](https://docs.docker.com/engine/install/) installed and running
- `bash`, `curl`, and standard GNU coreutils (already present on most distros)

## Naming rules

- Lowercase letters, numbers, and hyphens only
- Must start with a letter or number
- Cannot match a reserved name — including `hermes-spawn` subcommands (`restore`, `dashboard`, `connect`, `update`, `remove`, `rm`) and common system commands (`ls`, `docker`, `git`, etc.)
- Cannot collide with an existing Docker container, data directory, alias, or binary on PATH

If any conflict is detected, the script aborts cleanly without changing anything. You cannot spawn an instance named `dashboard` or `restore` — those words are subcommands (e.g. `hermes-spawn restore hermes`). The same applies to `update`, `remove`, and `rm`.

## Managing instances

**Restore a container from leftover data (container gone, data still on disk):**

```bash
hermes-spawn restore <name>
hermes-spawn restore hermes    # example
```

Use this when the Docker container (and maybe the shell alias) were removed but `~/hermes-spawn/<name>` still has your config, sessions, and keys. Restore skips the setup wizard, reattaches a new gateway container to the existing data directory, picks a free gateway port, and re-adds the `~/.bashrc` alias if it is missing. Run `hermes-spawn dashboard <name>` afterward if you had the web UI enabled before — dashboard settings are not stored on disk.

Pairs with `hermes-spawn remove <name> --keep-data`, which drops the container and alias but leaves data behind.

**Update an instance to the latest Hermes image (pull + recreate container, data unchanged):**

```bash
hermes-spawn update <name>
hermes-spawn update hermes              # example
hermes-spawn update hermes --no-pull    # recreate from local image only
hermes-spawn update hermes --image nousresearch/hermes-agent:<tag>
```

By default, `update` runs `docker pull nousresearch/hermes-agent` (the `latest` tag), stops and removes the existing container, then starts a new one with the same data directory, host port, dashboard settings (if enabled), and `HERMES_UID` / `HERMES_GID` settings. Your `~/.bashrc` alias is unchanged. Expect a short gateway outage during the swap.

**Enable the web dashboard (official Hermes side-process in the same container):**

```bash
hermes-spawn dashboard <name>
hermes-spawn dashboard hermes                 # example — prompts for login, Chat tab on
hermes-spawn dashboard hermes --no-tui        # dashboard without the Chat tab
hermes-spawn dashboard hermes --oauth         # Hermes OAuth gate instead of password
hermes-spawn dashboard hermes --reset-auth    # set a new username/password
hermes-spawn dashboard hermes --disable       # turn dashboard off again
```

This recreates the existing gateway container with `HERMES_DASHBOARD=1` and `HERMES_DASHBOARD_TUI=1` (Chat tab on by default). **By default it prompts interactively for a username and password** and passes them as `HERMES_DASHBOARD_BASIC_AUTH_*` — required on current Hermes images, which bind the dashboard to `0.0.0.0` inside the container and refuse to start without an auth provider (`HERMES_DASHBOARD_INSECURE=1` is now a deprecated no-op). Use **`--oauth`** if you want Hermes's built-in OAuth gate instead (typically with `HERMES_DASHBOARD_OAUTH_CLIENT_ID`). Credentials are kept on the container so `hermes-spawn update` can recreate it without re-prompting; use `--reset-auth` to change them.

The command publishes a localhost dashboard port starting at 9119 and leaves your data and shell alias unchanged. Open `http://127.0.0.1:<port>` in a browser and sign in with the credentials you set.

On a remote server, tunnel the dashboard port first:

```bash
ssh -L 9119:127.0.0.1:9119 user@your-server
```

Then open `http://127.0.0.1:9119` locally. `hermes-spawn update <name>` preserves dashboard settings.

**Remove an instance (container, `~/.bashrc` block, and data):**

```bash
hermes-spawn remove <name>   # interactive prompt if data is non-empty; use -y in scripts/CI
hermes-spawn remove <name> --keep-data   # drop the container and alias, keep ~/hermes-spawn/<name>
hermes-spawn restore <name>              # bring the container back from kept data
hermes-spawn rm <name> -y   # same as `remove` but delete data without asking
```

**Other useful commands:**

```bash
docker ps                    # list running instances
docker logs -f <name>        # tail gateway (+ [dashboard]) logs
docker stop <name>           # stop the gateway
docker start <name>          # start it again
hermes-spawn dashboard <name>   # enable web dashboard
hermes-spawn update <name>      # pull latest Hermes image
```

You can still `docker rm -f <name>` to drop only the container (data under `~/hermes-spawn/<name>` and the shell alias in `~/.bashrc` may stay — use `hermes-spawn restore <name>` to attach a new container to the data, or `hermes-spawn remove` for a full cleanup).

## Manual install

If you prefer not to pipe to bash:

```bash
sudo curl -fsSL https://raw.githubusercontent.com/oscarfrank/hermes-spawn/main/hermes-spawn -o /usr/local/bin/hermes-spawn
sudo chmod +x /usr/local/bin/hermes-spawn
```

## Security notes

- **Gateway ports are bound to `127.0.0.1` by default.** They are not reachable from the internet. `hermes-spawn connect` is the supported way to reach an instance from outside: it puts HTTPS in front (Caddy, Cloudflare Tunnel or Tailscale) and turns on the API server's key. Otherwise use SSH tunneling or a reverse proxy with authentication.
- **The web dashboard requires login by default** (Hermes username/password provider). Current Hermes images ignore `HERMES_DASHBOARD_INSECURE=1` and fail closed on a non-loopback bind without an auth provider. Dashboard ports are still bound to `127.0.0.1` on the host; the password gate is what satisfies Hermes inside Docker. Pass `--oauth` only when you want Hermes's OAuth gate instead. The dashboard can still read/write API keys in `.env` after you sign in.
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

`hermes-spawn` is a thin bash script around a few Docker commands, plus `restore`, `dashboard`, `update`, and `remove` / `rm` subcommands. On the host, each instance's files live in `~/hermes-spawn/<name>` and are bind-mounted to `/opt/data` in the container. To create an instance, it:

1. Validates inputs and detects conflicts
2. Calls `docker run ... setup` interactively for the wizard
3. Calls `docker run -d ... gateway run` to start the persistent service
4. Appends `alias <name>='docker exec -it <name> /opt/hermes/.venv/bin/hermes'` to `~/.bashrc`

`hermes-spawn remove <name>` does the reverse: `docker rm -f`, prunes the alias block, and (unless `--keep-data`) removes `~/hermes-spawn/<name>` after a prompt or ` -y` / `--yes` in non-interactive environments.

`hermes-spawn restore <name>` recreates a gateway container from an existing non-empty data directory (no setup wizard), re-adds the shell alias if needed, and assigns a new localhost gateway port.

`hermes-spawn update <name>` pulls a new image (by default `nousresearch/hermes-agent`), reads the existing container's port mapping, data mount, dashboard settings, and env vars, recreates the gateway container, and leaves data and aliases in place.

`hermes-spawn dashboard <name>` enables or disables Hermes's built-in web dashboard as a side-process in the same container (`HERMES_DASHBOARD=1`, optional `HERMES_DASHBOARD_TUI=1` for the browser Chat tab, interactive basic auth by default or `--oauth` for the OAuth gate), following the [official Docker pattern](https://hermes-agent.nousresearch.com/docs/user-guide/docker#running-the-dashboard).

`hermes-spawn connect <name>` edits the instance's `.env` in place (after a backup) to switch on the API server, installs the Hermsy plugin with the instance's own `hermes plugins install`, restarts it, and adds an HTTPS route on the host: a marked block in `/etc/caddy/Caddyfile`, a `<name>-tunnel` cloudflared container, or `tailscale serve`. What it set up is remembered in `~/hermes-spawn/.connect/<name>`, so `--status` and `--off` know what to check and undo. The QR code is drawn with Python inside the instance's container, so the host needs nothing extra.

Read the script — it's plain bash with no dependencies beyond Docker and standard Unix tools. <https://github.com/oscarfrank/hermes-spawn/blob/main/hermes-spawn>

## License

MIT
