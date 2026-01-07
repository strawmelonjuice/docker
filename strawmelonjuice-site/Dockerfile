FROM oven/bun:1 AS base
RUN apt-get update && \
    apt-get install -y --no-install-recommends git curl ca-certificates tar && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /usr/src/app
COPY start.sh ./
EXPOSE 8080/tcp
ENTRYPOINT [ "bash", "start.sh" ]
