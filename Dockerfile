ARG GLEAM_VERSION=v1.16.0

FROM ghcr.io/gleam-lang/gleam:${GLEAM_VERSION}-erlang-alpine AS builder

COPY ./shared /build/shared
COPY ./frontend /build/frontend
COPY ./backend /build/backend

RUN cd /build/shared && gleam deps download
RUN cd /build/frontend && gleam deps download
RUN cd /build/backend && gleam deps download

RUN cd /build/frontend \
  && gleam run -m lustre/dev build --minify --outdir=../backend/priv/static

RUN cd /build/backend \
  && gleam export erlang-shipment

FROM ghcr.io/gleam-lang/gleam:${GLEAM_VERSION}-erlang-alpine

COPY --from=builder /build/backend/build/erlang-shipment /app

WORKDIR /app
RUN printf '#!/bin/sh\nexec ./entrypoint.sh "$@"\n' > ./start.sh \
  && chmod +x ./start.sh

ENV HOST=0.0.0.0
ENV PORT=8080

EXPOSE $PORT

CMD ["./start.sh", "run"]
