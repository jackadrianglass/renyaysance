# Rennyaysance

A Gleam full-stack web app. Party/event platform with planned features: login, riddles, costume voting, scavenger hunt, tournament leaderboard.

**Note**: The current code is the Lustre full-stack tutorial example (a grocery list app). Anything involving groceries (`shared/groceries.gleam`, grocery routes, `GroceryItem`, etc.) is tutorial scaffolding that will be replaced.

## Stack

- **Frontend**: Lustre 5.x (MVU with effects, JavaScript target) — `frontend/`
- **Backend**: Wisp 2.x over Mist 6.x (Erlang target) — `backend/`
- **Shared**: `shared/` package for types and JSON codecs used by both sides
- **Storage**: Storail 3.x (file-based JSON, `./data/`) — tutorial placeholder, not for production
- **Dev env**: devenv (Nix)

Reference: https://hexdocs.pm/lustre/guide/06-full-stack-applications.html

## Project structure

```
rennyaysance/
  Makefile               — manual build targets
  backend/
    gleam.toml           — deps: mist, wisp, wisp_mist, storail, lustre, gleam_json, gleam_http, gleam_erlang, gleam_otp, gleam_stdlib
    src/backend.gleam    — Wisp+Mist server on :3000, SSR HTML, storail DB
    data/                — storail JSON storage (gitignored)
    priv/static/
      index.html         — minimal fallback shell (HTML is primarily rendered server-side)
      frontend.js        — compiled frontend bundle (generated, not committed)
  frontend/
    gleam.toml           — target = "javascript", deps: lustre, rsvp, plinth, gleam_json, gleam_http, gleam_stdlib
    src/frontend.gleam   — Lustre MVU app with effects, hydration from SSR
  shared/
    gleam.toml           — deps: gleam_json, gleam_stdlib
    src/shared/          — shared types and JSON codecs (currently: groceries.gleam — tutorial)
```

## Dev workflow

```sh
devenv up
```

Starts two processes concurrently:
- `backend` — `cd backend && gleam run` (Wisp/Mist on :3000)
- `frontend` — builds JS bundle on startup and re-runs on any `frontend/src/**/*.gleam` change

The frontend process runs:
```sh
cd frontend && gleam run -m lustre/dev build --outdir=../backend/priv/static
```

Output bundle is `frontend.js` (not `app.js`).

Manual targets:
```sh
make build-frontend   # one-shot JS build
make build-backend    # gleam build for backend
make build            # both
make dev              # build-frontend then gleam run in backend
make clean            # remove built artifacts
```

## Backend (Wisp 2.x + Mist 6.x)

Uses Wisp as the HTTP framework layered over Mist. Entry point:
```gleam
handle_request(db, static_directory, _)
|> wisp_mist.handler(secret_key_base)
|> mist.new
|> mist.port(3000)
|> mist.start
```

Middleware stack in `app_middleware`:
- `wisp.method_override` — supports PUT/DELETE via form POST
- `wisp.log_request`
- `wisp.rescue_crashes`
- `wisp.handle_head`
- `wisp.serve_static(req, under: "/static", from: static_directory)` — serves `priv/static/`

Routing in `handle_request`:
- `POST /api/groceries` — JSON body, decode, save to storail
- `GET *` — server-side renders full HTML with hydration data
- anything else → `wisp.not_found()`

SSR: the backend renders the full HTML document using lustre's `element.to_document_string`, injecting initial state as a JSON script tag:
```gleam
html.script(
  [attribute.type_("application/json"), attribute.id("model")],
  json.to_string(...)
)
```

Static files resolved via `wisp.priv_directory("backend")` — no CWD dependency.

## Frontend (Lustre 5.x)

Uses `lustre.application` (not `lustre.simple`) to support effects.

Hydration: reads initial state from the server-injected `<script id="model">` tag on startup:
```gleam
document.query_selector("#model")
|> result.map(plinth_element.inner_text)
|> result.try(fn(json) { json.parse(json, decoder()) ... })
```

Key deps:
- `rsvp` — HTTP requests from the frontend (e.g. `rsvp.post`)
- `plinth` — browser DOM access (`plinth/browser/document`, `plinth/browser/element`)

MVU: `lustre.application(init, update, view)` → `lustre.start(app, "#app", initial_data)`.

## Shared package

`shared/` is a plain Gleam package (no JS/Erlang target set) depended on by both frontend and backend via `{ path = "../shared" }`.

Currently contains only `shared/groceries.gleam` (tutorial code — will be replaced). This is the right place for domain types and JSON codecs shared across the stack.

## Styling

No CSS framework currently active. `backend/priv/static/index.html` is a minimal shell; styles are applied inline in the Lustre view functions for now.

Open Props was used in an earlier iteration and may be re-added:
```html
<link rel="stylesheet" href="https://unpkg.com/open-props" />
<link rel="stylesheet" href="https://unpkg.com/open-props/normalize.min.css" />
```
