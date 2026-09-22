#!/bin/sh
CONFIG_DIR="${CONFIG_DIR:-/data}"
STATE_FILE="$CONFIG_DIR/reality_state.json"
# 兼容从 xhttp_reality 镜像迁移过来的用户（旧状态文件）
LEGACY_STATE_FILE="$CONFIG_DIR/xhttp_reality_state.json"
INFO_FILE="$CONFIG_DIR/reality_config_info.txt"

mkdir -p "$CONFIG_DIR"

STATE_UUID=""
STATE_PRIVATEKEY=""
STATE_PUBLICKEY=""
STATE_DEST=""
STATE_SERVERNAMES=""
STATE_NETWORK=""
STATE_EXTERNAL_PORT=""
STATE_XHTTP_PATH=""
STATE_SHORTIDS=""

LEGACY_INFO_FILE=""
LEGACY_UUID=""
LEGACY_DEST=""
LEGACY_SERVERNAMES=""
LEGACY_PRIVATEKEY=""
LEGACY_PUBLICKEY=""
LEGACY_NETWORK=""
LEGACY_EXTERNAL_PORT=""
LEGACY_XHTTP_PATH=""
LEGACY_SHORTIDS=""

load_state() {
  STATE_SEPARATOR="$(printf '\034')"
  for STATE_SRC in "$STATE_FILE" "$LEGACY_STATE_FILE"; do
    if [ ! -f "$STATE_SRC" ]; then
      continue
    fi

    if ! STATE_VALUES=$(jq -er '
      if type == "object" then
        [
          (.uuid // "" | tostring),
          (.private_key // "" | tostring),
          (.public_key // "" | tostring),
          (.dest // "" | tostring),
          ((.servernames // []) | join(" ")),
          (.network // "" | tostring),
          (.external_port // "" | tostring),
          (.xhttp_path // "" | tostring),
          ((.shortids // []) | join(" "))
        ] | join("\u001c")
      else
        empty
      end' "$STATE_SRC" 2>/dev/null); then
      continue
    fi

    IFS="$STATE_SEPARATOR" read -r STATE_UUID STATE_PRIVATEKEY STATE_PUBLICKEY STATE_DEST STATE_SERVERNAMES STATE_NETWORK STATE_EXTERNAL_PORT STATE_XHTTP_PATH STATE_SHORTIDS <<EOF_STATE
$STATE_VALUES
EOF_STATE
    return
  done
}

load_legacy() {
  if [ -f "$INFO_FILE" ]; then
    LEGACY_INFO_FILE="$INFO_FILE"
  elif [ -f "$CONFIG_DIR/xhttp_reality_config_info.txt" ]; then
    LEGACY_INFO_FILE="$CONFIG_DIR/xhttp_reality_config_info.txt"
  elif [ -f "$CONFIG_DIR/config_info.txt" ]; then
    LEGACY_INFO_FILE="$CONFIG_DIR/config_info.txt"
  elif [ -f "/config_info.txt" ]; then
    LEGACY_INFO_FILE="/config_info.txt"
  else
    LEGACY_INFO_FILE=""
  fi

  if [ -n "$LEGACY_INFO_FILE" ]; then
    LEGACY_UUID=$(sed -n 's/^UUID: //p' "$LEGACY_INFO_FILE")
    LEGACY_DEST=$(sed -n 's/^DEST: //p' "$LEGACY_INFO_FILE")
    LEGACY_SERVERNAMES=$(sed -n 's/^SERVERNAMES: //p' "$LEGACY_INFO_FILE" | sed 's/ (.*$//')
    LEGACY_PRIVATEKEY=$(sed -n 's/^PRIVATEKEY: //p' "$LEGACY_INFO_FILE")
    LEGACY_PUBLICKEY=$(sed -n 's/^PUBLICKEY\/PASSWORD: //p' "$LEGACY_INFO_FILE")
    LEGACY_NETWORK=$(sed -n 's/^NETWORK: //p' "$LEGACY_INFO_FILE")
    LEGACY_EXTERNAL_PORT=$(sed -n 's/^PORT: //p' "$LEGACY_INFO_FILE")
    LEGACY_XHTTP_PATH=$(sed -n 's/^XHTTP_PATH: //p' "$LEGACY_INFO_FILE")
    LEGACY_SHORTIDS=$(sed -n 's/^SHORTIDS: //p' "$LEGACY_INFO_FILE")
    if [ -z "$LEGACY_SHORTIDS" ]; then
      LEGACY_SHORTIDS=$(sed -n 's/^SHORTID: [^ ]* (\(.*\) 任选其一)$/\1/p' "$LEGACY_INFO_FILE")
    fi
    if [ -z "$LEGACY_SHORTIDS" ]; then
      LEGACY_SHORTIDS=$(sed -n 's/^SHORTID: \([^ ]*\).*$/\1/p' "$LEGACY_INFO_FILE")
    fi
  fi
}

filter_masked() {
  case "$1" in
    *"*"*) echo "" ;;
    *) echo "$1" ;;
  esac
}

# 解析 PROXY URL：socks5://user:pass@host:port 或 http://host:port
# 解析结果写入 PROXY_PROTO / PROXY_HOST / PROXY_PORT / PROXY_USER / PROXY_PASS
parse_proxy() {
  raw="$1"
  PROXY_SCHEME="${raw%%://*}"
  rest="${raw#*://}"
  case "$rest" in
    *@*)
      creds="${rest%@*}"
      hostport="${rest##*@}"
      PROXY_USER="${creds%%:*}"
      case "$creds" in
        *:*) PROXY_PASS="${creds#*:}" ;;
        *) PROXY_PASS="" ;;
      esac
      ;;
    *)
      hostport="$rest"
      PROXY_USER=""
      PROXY_PASS=""
      ;;
  esac
  PROXY_HOST="${hostport%%:*}"
  PROXY_PORT="${hostport##*:}"
  case "$PROXY_SCHEME" in
    socks5|socks5h|socks) PROXY_PROTO="socks" ;;
    http|https) PROXY_PROTO="http" ;;
    *) PROXY_PROTO="" ;;
  esac
}

load_state
load_legacy

MIN_CLIENT_VER="${MIN_CLIENT_VER:-1.0.0}"
if ! printf '%s\n' "$MIN_CLIENT_VER" | awk -F. '
  NF == 3 &&
  $1 ~ /^[0-9]+$/ && $2 ~ /^[0-9]+$/ && $3 ~ /^[0-9]+$/ &&
  $1 + 0 <= 255 && $2 + 0 <= 255 && $3 + 0 <= 255 { exit 0 }
  { exit 1 }
'; then
  echo "Error: Invalid MIN_CLIENT_VER format. Expected x.y.z with each segment in range 0-255"
  exit 1
fi

LEGACY_UUID="$(filter_masked "$LEGACY_UUID")"
LEGACY_PRIVATEKEY="$(filter_masked "$LEGACY_PRIVATEKEY")"
LEGACY_PUBLICKEY="$(filter_masked "$LEGACY_PUBLICKEY")"

if [ -n "$LEGACY_SERVERNAMES" ]; then
  LEGACY_SERVERNAMES="$(echo "$LEGACY_SERVERNAMES" | awk '{$1=$1;print}')"
fi

IPV6=$(curl -6 -sSL --connect-timeout 3 --retry 2 ip.sb || echo "null")
IPV4=$(curl -4 -sSL --connect-timeout 3 --retry 2 ip.sb || echo "null")

UUID_FROM_ENV=false
if [ -n "$UUID" ]; then
  UUID_FROM_ENV=true
fi

if [ -z "$UUID" ]; then
  if [ -n "$STATE_UUID" ]; then
    UUID="$STATE_UUID"
  elif [ -n "$LEGACY_UUID" ]; then
    UUID="$LEGACY_UUID"
  fi
fi

if [ -z "$UUID" ]; then
  echo "UUID is not set, generate random UUID "
  UUID="$(/xray uuid)"
  echo "UUID: $UUID"
else
  if ! echo "$UUID" | grep -qE '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'; then
    if [ "$UUID_FROM_ENV" = "true" ]; then
      echo "Error: Invalid UUID format. Expected format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
      exit 1
    fi
    echo "Warning: Invalid UUID format from state/legacy, regenerate UUID"
    UUID="$(/xray uuid)"
    echo "UUID: $UUID"
  fi
fi

# NETWORK：tcp（vision flow）或 xhttp，默认 tcp
if [ -z "$NETWORK" ]; then
  if [ -n "$STATE_NETWORK" ]; then
    NETWORK="$STATE_NETWORK"
  elif [ -n "$LEGACY_NETWORK" ]; then
    NETWORK="$LEGACY_NETWORK"
  fi
fi

if [ "$NETWORK" = "xhttp" ]; then
  FLOW=""
  XRAY_NETWORK="xhttp"
  echo "NETWORK: xhttp (flow disabled)"
else
  NETWORK="tcp"
  FLOW="xtls-rprx-vision"
  XRAY_NETWORK="raw"
  echo "NETWORK: tcp (flow xtls-rprx-vision)"
fi

# XHTTP_PATH：仅 xhttp 模式使用
if [ "$NETWORK" = "xhttp" ]; then
  if [ -z "$XHTTP_PATH" ]; then
    if [ -n "$STATE_XHTTP_PATH" ]; then
      XHTTP_PATH="$STATE_XHTTP_PATH"
    elif [ -n "$LEGACY_XHTTP_PATH" ]; then
      XHTTP_PATH="$LEGACY_XHTTP_PATH"
    fi
  fi
  if [ -z "$XHTTP_PATH" ]; then
    echo "XHTTP_PATH is not set, generate random XHTTP_PATH "
    PATH_LENGTH="$(( RANDOM % 4 + 8 ))"
    XHTTP_PATH="/""$(/xray uuid | tr -d '-' | cut -c 1-$PATH_LENGTH)"
    echo "XHTTP_PATH: $XHTTP_PATH"
  fi
fi

if [ -z "$EXTERNAL_PORT" ]; then
  if [ -n "$STATE_EXTERNAL_PORT" ]; then
    EXTERNAL_PORT="$STATE_EXTERNAL_PORT"
  elif [ -n "$LEGACY_EXTERNAL_PORT" ]; then
    EXTERNAL_PORT="$LEGACY_EXTERNAL_PORT"
  fi
fi

if [ -z "$EXTERNAL_PORT" ]; then
  echo "EXTERNAL_PORT is not set, use default value 443"
  EXTERNAL_PORT=443
fi

if [ -n "$HOSTMODE_PORT" ]; then
  EXTERNAL_PORT=$HOSTMODE_PORT
  jq ".inbounds[0].port=$HOSTMODE_PORT" /config.json > /config.json_tmp && mv /config.json_tmp /config.json
fi

DEST_FROM_ENV=false
if [ -n "$DEST" ]; then
  DEST_FROM_ENV=true
fi

if [ -z "$DEST" ]; then
  if [ -n "$STATE_DEST" ]; then
    DEST="$STATE_DEST"
  elif [ -n "$LEGACY_DEST" ]; then
    DEST="$LEGACY_DEST"
  fi
fi

if [ -z "$DEST" ]; then
  echo "DEST is not set. default value www.apple.com:443"
  DEST="www.apple.com:443"
else
  if ! echo "$DEST" | grep -qE '^[^:]+:[0-9]+$'; then
    if [ "$DEST_FROM_ENV" = "true" ]; then
      echo "Error: Invalid DEST format. Expected format: host:port (e.g., www.apple.com:443)"
      exit 1
    fi
    echo "Warning: Invalid DEST format from state/legacy, use default value www.apple.com:443"
    DEST="www.apple.com:443"
  fi
fi

if [ -z "$SERVERNAMES" ]; then
  if [ -n "$STATE_SERVERNAMES" ]; then
    SERVERNAMES="$STATE_SERVERNAMES"
  elif [ -n "$LEGACY_SERVERNAMES" ]; then
    SERVERNAMES="$LEGACY_SERVERNAMES"
  fi
fi

if [ -z "$SERVERNAMES" ]; then
  echo "SERVERNAMES is not set. use default value [\"www.apple.com\",\"images.apple.com\"]"
  SERVERNAMES="www.apple.com images.apple.com"
fi

if [ -z "$PRIVATEKEY" ]; then
  if [ -n "$STATE_PRIVATEKEY" ]; then
    PRIVATEKEY="$STATE_PRIVATEKEY"
  elif [ -n "$LEGACY_PRIVATEKEY" ]; then
    PRIVATEKEY="$LEGACY_PRIVATEKEY"
  fi
fi

if [ -z "$PRIVATEKEY" ]; then
  echo "PRIVATEKEY is not set. generate new key"
  /xray x25519 > /key
  PRIVATEKEY=$(cat /key | grep "Private" | awk -F ': ' '{print $2}')
  PUBLICKEY=$(cat /key | grep "Password" | awk -F ': ' '{print $2}')
  echo "Private key: $PRIVATEKEY"
  echo "Public key: $PUBLICKEY"
  rm -f /key
else
  if [ -z "$PUBLICKEY" ]; then
    if [ -n "$STATE_PUBLICKEY" ] && [ "$STATE_PRIVATEKEY" = "$PRIVATEKEY" ]; then
      PUBLICKEY="$STATE_PUBLICKEY"
    elif [ -n "$LEGACY_PUBLICKEY" ] && [ "$LEGACY_PRIVATEKEY" = "$PRIVATEKEY" ]; then
      PUBLICKEY="$LEGACY_PUBLICKEY"
    else
      echo "Warning: PUBLICKEY is not set; subscription info may be incomplete"
    fi
  fi
fi

# SHORTIDS 空格分隔多值，默认留空 [""] 维持现状
if [ -z "$SHORTIDS" ]; then
  if [ -n "$STATE_SHORTIDS" ]; then
    SHORTIDS="$STATE_SHORTIDS"
  elif [ -n "$LEGACY_SHORTIDS" ]; then
    SHORTIDS="$LEGACY_SHORTIDS"
  fi
fi

FIRST_SHORTID=""
if [ -z "$SHORTIDS" ]; then
  REALITY_SHORTIDS_JSON_ARRAY='[""]'
  SHORTIDS_JSON_ARRAY='[]'
else
  SHORTIDS_VALID=true
  for sid in $SHORTIDS; do
    if ! echo "$sid" | grep -qE '^[0-9a-fA-F]+$' || [ "$(( ${#sid} % 2 ))" -ne 0 ] || [ "${#sid}" -gt 16 ]; then
      SHORTIDS_VALID=false
    fi
  done
  if [ "$SHORTIDS_VALID" = false ]; then
    echo "Warning: invalid SHORTIDS (expect hex, even length, <=16), fallback to empty"
    SHORTIDS=""
    REALITY_SHORTIDS_JSON_ARRAY='[""]'
    SHORTIDS_JSON_ARRAY='[]'
  else
    SHORTIDS_JSON_ARRAY="[$(echo $SHORTIDS | awk '{for(i=1;i<=NF;i++) printf "\"%s\",", $i}' | sed 's/,$//')]"
    REALITY_SHORTIDS_JSON_ARRAY="$SHORTIDS_JSON_ARRAY"
    FIRST_SHORTID=$(echo $SHORTIDS | awk '{print $1}')
  fi
fi

# 仅设置 DOMAIN 时启用本地 Caddy 站点，否则保持裸 reality
USE_CADDY=false
if [ -n "$DOMAIN" ]; then
  USE_CADDY=true
  DEST="127.0.0.1:8443"
  SERVERNAMES="$DOMAIN"
  echo "Steal-self mode enabled: serve local Caddy site for $DOMAIN, dest=$DEST"
fi

SERVERNAMES_JSON_ARRAY="$(echo "[$(echo $SERVERNAMES | awk '{for(i=1;i<=NF;i++) printf "\"%s\",", $i}' | sed 's/,$//')]")"

jq \
  --arg uuid "$UUID" \
  --arg dest "$DEST" \
  --arg flow "$FLOW" \
  --arg private_key "$PRIVATEKEY" \
  --arg network "$XRAY_NETWORK" \
  --arg min_client_ver "$MIN_CLIENT_VER" \
  --argjson serverNames "$SERVERNAMES_JSON_ARRAY" \
  --argjson shortIds "$REALITY_SHORTIDS_JSON_ARRAY" \
  '.inbounds[1].settings.clients[0].id = $uuid
  | .inbounds[1].settings.clients[0].flow = $flow
  | .inbounds[1].streamSettings.realitySettings.target = $dest
  | .inbounds[1].streamSettings.realitySettings.minClientVer = $min_client_ver
  | .inbounds[1].streamSettings.realitySettings.serverNames = $serverNames
  | .inbounds[1].streamSettings.realitySettings.shortIds = $shortIds
  | .routing.rules[0].domain = $serverNames
  | .inbounds[1].streamSettings.realitySettings.privateKey = $private_key
  | .inbounds[1].streamSettings.network = $network' /config.json > /config.json_tmp && mv /config.json_tmp /config.json

# xhttp 模式：注入 xhttpSettings
if [ "$NETWORK" = "xhttp" ]; then
  jq \
    --arg xhttp_path "$XHTTP_PATH" \
    '.inbounds[1].streamSettings.xhttpSettings = {
      "headers": {},
      "host": "",
      "mode": "auto",
      "noSSEHeader": false,
      "path": $xhttp_path,
      "scMaxBufferedPosts": 30,
      "scMaxEachPostBytes": "1000000",
      "scStreamUpServerSecs": "20-80",
      "xPaddingBytes": "100-1000"
    }' /config.json > /config.json_tmp && mv /config.json_tmp /config.json
fi

# PROXY（后置代理）：注入 socks/http 出站，并将全部出站流量改走代理（保留现有 blocked 规则）
if [ -n "$PROXY" ]; then
  parse_proxy "$PROXY"
  if [ -z "$PROXY_PROTO" ] || [ -z "$PROXY_HOST" ] || [ -z "$PROXY_PORT" ]; then
    echo "Warning: invalid PROXY format, expected socks5://[user:pass@]host:port or http://[user:pass@]host:port. Proxy disabled."
  else
    echo "Backend proxy enabled: $PROXY_PROTO://$PROXY_HOST:$PROXY_PORT (auth: $([ -n "$PROXY_USER" ] && echo yes || echo no))"
    if [ -n "$PROXY_USER" ]; then
      PROXY_OUTBOUND=$(jq -n \
        --arg proto "$PROXY_PROTO" --arg addr "$PROXY_HOST" --argjson port "$PROXY_PORT" \
        --arg user "$PROXY_USER" --arg pass "$PROXY_PASS" \
        '{tag:"proxy", protocol:$proto, settings:{servers:[{address:$addr, port:$port, users:[{user:$user, pass:$pass}]}]}}')
    else
      PROXY_OUTBOUND=$(jq -n \
        --arg proto "$PROXY_PROTO" --arg addr "$PROXY_HOST" --argjson port "$PROXY_PORT" \
        '{tag:"proxy", protocol:$proto, settings:{servers:[{address:$addr, port:$port}]}}')
    fi
    # 幂等注入：容器 /config.json 在可写层持久化，重启会重复执行本脚本。
    # 先剔除已存在的 proxy 出站与 proxy 路由，再各加唯一一份，避免重启后
    # 出现重复 tag（xray 报 "existing tag found: proxy" 并崩溃重启循环）。
    jq --argjson proxyout "$PROXY_OUTBOUND" \
      '.outbounds = ((.outbounds | map(select(.tag != "proxy"))) + [$proxyout])
      | .routing.rules = ((.routing.rules | map(select(.outboundTag != "proxy"))) + [{"type":"field","outboundTag":"proxy","network":"tcp,udp"}])' \
      /config.json > /config.json_tmp && mv /config.json_tmp /config.json
  fi
else
  echo "Tip: 设置 PROXY 环境变量可接入家宽代理解锁 Netflix/AI 场景，推荐："
  echo "  Proxy-Cheap https://app.proxy-cheap.com/r/Pbqf9l"
  echo "  IPRoyal https://iproyal.cn/?r=249487"
  echo "  Thordata https://dashboard.thordata.com/zh/register?invitation_code=5P8NDLWV（动态住宅代理 1–350GB 九折，优惠码：WULABING）"
fi

# 持久化状态
jq -n \
  --arg uuid "$UUID" \
  --arg private_key "$PRIVATEKEY" \
  --arg public_key "$PUBLICKEY" \
  --arg dest "$DEST" \
  --arg network "$NETWORK" \
  --arg external_port "$EXTERNAL_PORT" \
  --arg xhttp_path "$XHTTP_PATH" \
  --argjson servernames "$SERVERNAMES_JSON_ARRAY" \
  --argjson shortids "$SHORTIDS_JSON_ARRAY" \
  '{uuid:$uuid, private_key:$private_key, public_key:$public_key, dest:$dest, servernames:$servernames, network:$network, external_port:$external_port, xhttp_path:$xhttp_path, shortids:$shortids}' > "$STATE_FILE"

FIRST_SERVERNAME=$(echo $SERVERNAMES | awk '{print $1}')

if [ "$HIDE_SENSITIVE_INFO" = "true" ]; then
  DISPLAY_UUID="********-****-****-****-************"
  DISPLAY_PRIVATEKEY="********************************"
  DISPLAY_PUBLICKEY="********************************"
else
  DISPLAY_UUID="$UUID"
  DISPLAY_PRIVATEKEY="$PRIVATEKEY"
  DISPLAY_PUBLICKEY="$PUBLICKEY"
fi

# 订阅链接的 sid 参数：仅在 shortId 非空时附加，保持空值时与旧版完全一致
SID_PARAM=""
if [ -n "$FIRST_SHORTID" ]; then
  SID_PARAM="&sid=$FIRST_SHORTID"
fi

# config info with green color
echo -e "\033[32m" > /config_info.txt
echo "IPV6: $IPV6" >> /config_info.txt
echo "IPV4: $IPV4" >> /config_info.txt
echo "UUID: $DISPLAY_UUID" >> /config_info.txt
echo "DEST: $DEST" >> /config_info.txt
echo "PORT: $EXTERNAL_PORT" >> /config_info.txt
echo "SERVERNAMES: $SERVERNAMES (任选其一)" >> /config_info.txt
echo "PRIVATEKEY: $DISPLAY_PRIVATEKEY" >> /config_info.txt
echo "PUBLICKEY/PASSWORD: $DISPLAY_PUBLICKEY" >> /config_info.txt
echo "NETWORK: $NETWORK" >> /config_info.txt
if [ -n "$FIRST_SHORTID" ]; then
  echo "SHORTID: $FIRST_SHORTID ($SHORTIDS 任选其一)" >> /config_info.txt
fi
if [ "$NETWORK" = "xhttp" ]; then
  echo "XHTTP_PATH: $XHTTP_PATH" >> /config_info.txt
fi
if [ "$USE_CADDY" = true ]; then
  echo "STEAL-SELF: enabled (Caddy local site for $DOMAIN)" >> /config_info.txt
fi

# 按 NETWORK 生成订阅链接
build_sub() {
  ip="$1"
  if [ "$NETWORK" = "xhttp" ]; then
    echo "vless://$UUID@$ip:$EXTERNAL_PORT?encryption=none&security=reality&type=xhttp&sni=$FIRST_SERVERNAME&fp=firefox&pbk=$PUBLICKEY${SID_PARAM}&path=$XHTTP_PATH&mode=auto#${ip}-wulabing_docker_xhttp_reality"
  else
    echo "vless://$UUID@$ip:$EXTERNAL_PORT?encryption=none&security=reality&type=tcp&sni=$FIRST_SERVERNAME&fp=firefox&pbk=$PUBLICKEY${SID_PARAM}&flow=xtls-rprx-vision#${ip}-wulabing_docker_vless_reality_vision"
  fi
}

if [ "$IPV4" != "null" ]; then
  SUB_IPV4="$(build_sub "$IPV4")"
  echo "IPV4 订阅连接: $SUB_IPV4" >> /config_info.txt
  echo -e "IPV4 订阅二维码:\n$(echo "$SUB_IPV4" | qrencode -o - -t UTF8)" >> /config_info.txt
fi
if [ "$IPV6" != "null" ]; then
  SUB_IPV6="$(build_sub "$IPV6")"
  echo "IPV6 订阅连接: $SUB_IPV6" >> /config_info.txt
  echo -e "IPV6 订阅二维码:\n$(echo "$SUB_IPV6" | qrencode -o - -t UTF8)" >> /config_info.txt
fi

echo "" >> /config_info.txt
echo "===== 支持本项目 (AFF) =====" >> /config_info.txt
echo "家宽代理(配合 PROXY 变量解锁流媒体/AI):" >> /config_info.txt
echo "  Proxy-Cheap https://app.proxy-cheap.com/r/Pbqf9l" >> /config_info.txt
echo "  IPRoyal https://iproyal.cn/?r=249487" >> /config_info.txt
echo "  Thordata https://dashboard.thordata.com/zh/register?invitation_code=5P8NDLWV（动态住宅代理 1–350GB 九折，优惠码：WULABING）" >> /config_info.txt
echo "VPS: 搬瓦工 https://bandwagonhost.com/aff.php?aff=63939 | DMIT https://www.dmit.io/aff.php?aff=3957" >> /config_info.txt

echo -e "\033[0m" >> /config_info.txt

cp -f /config_info.txt "$INFO_FILE"

# show config info
cat /config_info.txt

# 偷自己模式：先启动 Caddy 并等待证书就绪，再启动 xray
if [ "$USE_CADDY" = true ]; then
  if [ -n "$ACME_EMAIL" ]; then
    CADDY_EMAIL_LINE="email $ACME_EMAIL"
  else
    CADDY_EMAIL_LINE=""
  fi
  export DOMAIN ACME_EMAIL CADDY_EMAIL_LINE
  echo "Starting Caddy for local site $DOMAIN ..."
  caddy run --config /etc/caddy/Caddyfile --adapter caddyfile &
  i=0
  while [ $i -lt 30 ]; do
    if curl -sk --connect-timeout 2 "https://127.0.0.1:8443" >/dev/null 2>&1; then
      echo "Caddy local site is ready on 127.0.0.1:8443"
      break
    fi
    i=$((i+1))
    sleep 2
  done
  if [ $i -ge 30 ]; then
    echo "Warning: Caddy site not confirmed ready within timeout; xray will keep retrying dest connection"
  fi
fi

# run xray
exec /xray run -c /config.json
