# Rennyaysance

A Gleam full-stack web app. Party/event platform with planned features: login, riddles, costume voting, scavenger hunt, tournament leaderboard.

## Stack

- **Frontend**: Lustre 5.x (MVU, JavaScript target) — `frontend/`
- **Backend**: Mist 6.x HTTP server (Erlang target) — `backend/`
- **Styles**: Open Props via CDN in `index.html`
- **Dev env**: devenv (Nix)

Reference: https://hexdocs.pm/lustre/guide/06-full-stack-applications.html

## Project structure

```
rennyaysance/
  devenv.nix             — dev processes (backend + frontend watcher)
  Makefile               — manual build targets
  backend/
    gleam.toml           — deps: mist, gleam_http, gleam_erlang, gleam_otp, gleam_stdlib
    src/backend.gleam    — Mist server on :8080
    priv/static/
      index.html         — HTML shell, mounts #app, loads Open Props CDN
      app.css            — Open Props variable usage
      app.js             — compiled frontend bundle (generated, not committed)
  frontend/
    gleam.toml           — target = "javascript", deps: lustre, lustre_dev_tools
    src/frontend.gleam   — Lustre MVU app entry point
```

## Dev workflow

```sh
devenv up
```

Starts two processes concurrently:
- `backend` — `cd backend && gleam run` (Mist on :8080)
- `frontend` — builds JS bundle on startup and re-runs on any `frontend/src/**/*.gleam` change

The frontend process runs:
```sh
cd frontend && gleam run -m lustre/dev build --outdir=../backend/priv/static
```

`lustre/dev build` uses esbuild under the hood. `--outdir` writes `app.js` directly into the backend's static dir, no copy step needed.

Manual targets:
```sh
make build-frontend   # one-shot JS build
make build-backend    # gleam build for backend
make build            # both
make dev              # build-frontend then gleam run in backend
```

## Backend (Mist 6.x)

`mist.new(handler) |> mist.port(8080) |> mist.start` — note: it's `mist.start`, not `mist.start_http` (renamed in v6).

Routing in `handle_request`:
- `[]` → `priv/static/index.html`
- `[file]` → `priv/static/<file>` with inferred content-type
- anything deeper → 404

Static files are resolved relative to the CWD when `gleam run` is invoked, which is the `backend/` project root.

`mist.send_file(path, offset: 0, limit: None)` for file responses. `mist.Bytes(bytes_tree.from_string(...))` for inline responses.

Gleam case guards do not allow function calls — use pipeline transforms before the `case` instead.

## Frontend (Lustre 5.x)

MVU pattern: `lustre.simple(init, update, view)` → `lustre.start(app, "#app", Nil)`.

Key imports:
```gleam
import lustre
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
```

`html.text`, `html.div`, `html.button` etc. are all in `lustre/element/html`. Text nodes: `html.text("...")`.

## Styling (Open Props)

Loaded via CDN in `index.html`:
```html
<link rel="stylesheet" href="https://unpkg.com/open-props" />
<link rel="stylesheet" href="https://unpkg.com/open-props/normalize.min.css" />
```

Use `var(--font-size-fluid-3)`, `var(--indigo-6)`, `var(--size-fluid-3)` etc. in `app.css`. Full prop reference at https://open-props.style/.

## Future structure

As the app grows, consider a `shared/` Gleam package for types and JSON codecs used by both frontend and backend (see the full-stack guide). For server-side rendering / hydration, embed initial state as JSON in a `<script id="model">` tag and decode it in the Lustre `init` flags.
