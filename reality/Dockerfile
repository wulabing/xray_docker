# builder
FROM golang:alpine AS builder
LABEL maintainer="wulabing <wulabing@gmail.com>"
LABEL version="0.0.29"


#ENV GOPROXY=https://goproxy.cn,direct
WORKDIR /app

RUN apk add --no-cache --no-scripts git curl jq && \ 
    LATEST_VERSION_TAG=$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases | jq -r '.[0].tag_name') && \
    git clone https://github.com/XTLS/Xray-core.git . && \
    git checkout $LATEST_VERSION_TAG && \
    go mod download -x && \
    go build -v -o xray /app/main/

# runner
FROM alpine:latest AS runner


ENV UUID=""
ENV DEST=""
ENV SERVERNAMES=""
ENV PRIVATEKEY=""
ENV SHORTIDS=""
ENV NETWORK=""
ENV INTERNAL_PORT=""
ENV HOSTMODE_PORT=""
ENV ENABLE_RATE_LIMIT=""
ENV TZ=Asia/Shanghai

WORKDIR /

COPY ./entrypoint.sh /
COPY ./config.json /

COPY --from=builder /app/xray /

RUN apk add --no-cache --no-scripts tzdata ca-certificates jq curl libqrencode-tools && \
    mkdir -p /var/log/xray && \
    mkdir -p /app && \
    wget -O /geosite.dat https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat && \
    wget -O /geoip.dat https://github.com/v2fly/geoip/releases/latest/download/geoip.dat && \
    chmod +x /entrypoint.sh

# 创建一个挂载点，用于持久化配置文件
VOLUME ["/app"]

ENTRYPOINT ["./entrypoint.sh"]
EXPOSE 443
