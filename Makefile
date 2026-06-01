.PHONY: dev build build-frontend build-backend clean seed

dev: build-frontend
	cd backend && gleam run

build: build-frontend build-backend

build-frontend:
	cd frontend && gleam run -m lustre/dev build --outdir=../backend/priv/static

build-backend:
	cd backend && gleam build

seed:
	cd backend && gleam run -m seed

clean:
	rm -f backend/priv/static/app.js
	rm -rf frontend/build backend/build
