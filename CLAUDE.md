# Rennyaysance

Gleam full-stack party/event platform. Planned: login, riddles, costume voting, scavenger hunt, jousting bracket, tournament leaderboard.

## Stack

- **Frontend**: Lustre 5.x (MVU + effects, JS target) — `frontend/`
- **Backend**: Wisp 2.x + Mist 6.x (Erlang target) — `backend/`
- **Storage**: Storail 3.x (file-based JSON, `backend/data/`)
- **Dev env**: devenv (Nix)

## Project structure

```
rennyaysance/
  Makefile
  backend/
    gleam.toml           — deps: mist, wisp, wisp_mist, storail, lustre, gleam_json, gleam_http, gleam_erlang, gleam_otp, gleam_stdlib
    src/backend.gleam    — server, routing, login handler, user storage
    data/                — storail JSON (gitignored)
    priv/static/
      frontend.js        — compiled frontend bundle (generated)
  frontend/
    gleam.toml           — target=javascript, deps: lustre, modem, rsvp, plinth, gleam_json, gleam_http, gleam_stdlib
    src/
      frontend.gleam     — main, Model, Msg, init, update, view (auth gate)
      router.gleam       — Route type, parse_route, href
      layout.gleam       — page() wrapper, nav_link() (generic over msg)
      local_storage.gleam — get/set/remove via plinth/javascript/storage
      page/              — one file per page, each exports view() -> Element(msg)
  shared/
    src/shared/groceries.gleam  — dead code (tutorial remnant, not imported anywhere)
```

## Dev workflow

```sh
devenv up           # starts backend (:3000) + frontend watcher concurrently
make build-frontend # cd frontend && gleam run -m lustre/dev build --outdir=../backend/priv/static
make build-backend  # gleam build in backend
make dev            # build-frontend then gleam run in backend
make clean
```

## Backend

Wisp over Mist. `wisp.priv_directory("backend")` resolves static dir — no CWD dependency.

Routes:
- `POST /api/login` → check password, upsert user in storail, return `{name}`
- `GET *` → `serve_index()`: SSR minimal HTML shell via lustre element, mounts `#app`
- else → `wisp.not_found()`

Auth: hardcoded `const party_password = "renaissance"` at top of `backend.gleam`. Wrong password → `wisp.response(401)`. User list stored as `List(String)` in storail collection `"users"`.

Key wisp functions: `wisp.json_response(body, status)`, `wisp.html_response(body, status)`, `wisp.response(status)`, `wisp.bad_request(detail)`.

## Frontend

Routing via `modem` — intercepts link clicks + back/forward. All routes defined in `router.gleam` as a `Route` custom type. `parse_route(Uri) -> Route` and `href(Route) -> Attribute(msg)`.

Auth gate in `view`: if `model.user == None`, renders `login.view(...)` regardless of route. If logged in, renders `view_page(route)` wrapped with a logout button.

Session persistence: `local_storage.get/set/remove` wraps `plinth/javascript/storage`. Key: `"rennyaysance:user"`. Read in `init`, written on successful login, cleared on logout.

Login API call uses `rsvp.post` + `rsvp.expect_json(decoder, ServerRespondedToLogin)`. Response msg is `Result(String, rsvp.Error(String))`.

Page files in `page/` each export `pub fn view() -> Element(msg)` (generic over msg — no page-level messages yet). `login.gleam` takes callbacks: `view(name, password, error, loading, on_name_input, on_password_input, on_submit)`.

`layout.page(title, body)` renders a `<nav>` with a Home link + `<h1>` + body. `layout.nav_link(route, label)` produces an `<a>` using `router.href`.

## Styling

CSS lives in `backend/priv/static/app.css`. Loaded via `serve_index()` in `backend.gleam` alongside Open Props and Google Fonts.

**External dependencies (linked in `serve_index()` head):**
- Open Props CDN: `https://unpkg.com/open-props/open-props.min.css` — size/spacing/radius/transition tokens
- Google Fonts: Jacquard 24 (`--font-display`) — used on headings

**Structure:** ITCSS-inspired `@layer` cascade:
- `settings` — raw palette (`--scarlet-*`, `--gold-*`, `--parchment-*`) + semantic aliases (`--color-bg`, `--color-text`, `--color-primary`, `--color-accent`, `--color-border`). Dark mode via `@media (prefers-color-scheme: dark)`.
- `generic` — box-sizing reset, margin zero, font inherit on form elements
- `elements` — defaults for `body`, `h1–h3`, `a`, `button`, `input`
- `components` — scoped UI classes (`.nav`, `.login-form`, etc.) — add here as pages are built
- `utilities` — `.sr-only`, `.flex`, `.stack`, `.cluster`

**Color theme:** Gryffindor (scarlet + gold + parchment). Light mode: parchment-cream bg. Dark mode: near-black warm bg.
