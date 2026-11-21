FROM node:alpine3.22
WORKDIR /tmp
COPY index.js index.html package.json ./
EXPOSE 3000/tcp
RUN apk add --no-cache openssl curl gcompat iproute2 coreutils bash ca-certificates && npm install \
    && curl -fsSL https://github.com/fatedier/frp/releases/download/v0.68.1/frp_0.68.1_linux_amd64.tar.gz | tar -xz --strip-components=1 -C /usr/local/bin frp_0.68.1_linux_amd64/frpc \
    && chmod +x /usr/local/bin/frpc
RUN sed -i 's/if (fs.existsSync(botPath)) {/if (!process.env.FRP_ONLY \&\& fs.existsSync(botPath)) {/' index.js
RUN printf '%s\n' \
    '#!/bin/sh' \
    'set -eu' \
    'umask 077' \
    'mkdir -p /tmp/frpc-runtime' \
    'printf %s "$FRP_CERT_B64" | base64 -d > /tmp/frpc-runtime/client.crt' \
    'printf %s "$FRP_KEY_B64" | base64 -d > /tmp/frpc-runtime/client.key' \
    'printf %s "$FRP_CONFIG_B64" | base64 -d > /tmp/frpc-runtime/frpc.ini' \
    '/usr/local/bin/frpc -c /tmp/frpc-runtime/frpc.ini &' \
    'exec node index.js' > /usr/local/bin/start-frp && chmod +x /usr/local/bin/start-frp
ENV FRP_ONLY=1
CMD ["/usr/local/bin/start-frp"]
