#
#   Copyright (C) 2023 fiskaly GmbH <https://fiskaly.com>
#   All rights reserved.
#
#   Developed by: Philipp Paulweber et al.
#   <https://github.com/fiskaly/docker.sta/graphs/contributors>
#
#   This file is part of docker.sta.
#
#   Permission is hereby granted, free of charge, to any person obtaining a copy
#   of this software and associated documentation files (the "Software"), to deal
#   in the Software without restriction, including without limitation the rights
#   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#   copies of the Software, and to permit persons to whom the Software is
#   furnished to do so, subject to the following conditions:
#
#   The above copyright notice and this permission notice shall be included in all
#   copies or substantial portions of the Software.
#
#   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#   SOFTWARE.

FROM mhart/alpine-node:16.4.2 \
  AS build

ENV USER=appuser
ENV UID=10001
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid "${UID}" \
    "${USER}"

RUN apk update \
 && apk add --no-cache ca-certificates python3 gcc g++ make linux-headers \
 && update-ca-certificates \
 && ln -sf python3 /usr/bin/python \
 && npm i -g pkg -D -S \
 && pkg -v

WORKDIR '/app'

# npm install node-musl \
#  && 

RUN npm install swagger-typescript-api@12.0.3 \
 && npx swagger-typescript-api --version

RUN pkg -t node18-linuxstatic node_modules/.bin/swagger-typescript-api \
 && ./swagger-typescript-api --help

FROM scratch \
  AS image

COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build /etc/passwd /etc/passwd
COPY --from=build /etc/group /etc/group
COPY --from=build /app/swagger-typescript-api /sta

USER appuser:appuser
ENTRYPOINT ["/sta"]
CMD ["--help"]
