#FROM golang:1.25.1-alpine AS build
#WORKDIR /src
#COPY go.mod go.sum ./
#RUN go mod download
#COPY . .
#RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
#    go build -o /out/server ./api/cmd/server
#
#
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /app

# Base tooling: curl, gnupg, Python, pip, yq, jq, nginx, supervisor
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg lsb-release apt-transport-https \
    bash python3 python3-pip jq \
    unixodbc \
    nginx supervisor \
 && rm -rf /var/lib/apt/lists/*

# --- yq (binary) ---
ARG YQ_VERSION=v4.44.3
RUN curl -fsSL -o /usr/local/bin/yq \
      https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64 \
 && chmod +x /usr/local/bin/yq

# --- Azure CLI from Microsoft repo (cleaner than the curl | bash) ---
RUN mkdir -p /etc/apt/keyrings \
 && curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmor -o /etc/apt/keyrings/microsoft.gpg \
 && echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" \
    > /etc/apt/sources.list.d/azure-cli.list \
 && apt-get update && apt-get install -y --no-install-recommends azure-cli \
 && rm -rf /var/lib/apt/lists/*

# --- kubectl ---
ARG KUBECTL_VERSION=v1.30.4
RUN curl -fsSL -o /usr/local/bin/kubectl \
      https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl \
 && chmod +x /usr/local/bin/kubectl

# Go toolchain (official tarball)
ARG GO_VERSION=1.25.1
RUN curl -fsSL https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz -o /tmp/go.tgz \
 && rm -rf /usr/local/go && tar -C /usr/local -xzf /tmp/go.tgz && rm /tmp/go.tgz
ENV PATH="/usr/local/go/bin:${PATH}"

# Copy source 
COPY . /app/src

# --- Holmes (Python) ---
RUN python3 -m pip install --no-cache-dir --upgrade pip \
 && python3 -m pip install --no-cache-dir holmesgpt

# Copy configuration and scripts
COPY container/config.yaml /root/.holmes/config.yaml
COPY container/update_builtin_vars.sh /app/update_builtin_vars.sh
RUN chmod 755 /app/update_builtin_vars.sh /root/.holmes/config.yaml


# Nginx static site + config
COPY web/ /usr/share/nginx/html/
RUN mkdir -p /run/nginx
COPY web/nginx.conf /etc/nginx/sites-enabled/default


# Supervisor config
COPY container/supervisord.conf /etc/supervisord.conf

COPY container/odbc.sh /app/odbc.sh
RUN chmod 755 /app/odbc.sh


COPY container/entrypoint.sh /app/entrypoint.sh
RUN chmod 755 /app/entrypoint.sh

EXPOSE 80
ENTRYPOINT ["/app/entrypoint.sh"]