#!/bin/sh
CONFIG_DIR="${CONFIG_DIR:-/data}"
STATE_FILE="$CONFIG_DIR/xhttp_reality_state.json"
INFO_FILE="$CONFIG_DIR/xhttp_reality_config_info.txt"

mkdir -p "$CONFIG_DIR"

STATE_UUID=""
STATE_PRIVATEKEY=""
STATE_PUBLICKEY=""
STATE_DEST=""
STATE_SERVERNAMES=""
STATE_NETWORK=""
STATE_EXTERNAL_PORT=""
STATE_XHTTP_PATH=""

LEGACY_INFO_FILE=""
LEGACY_UUID=""
LEGACY_DEST=""
LEGACY_SERVERNAMES=""
LEGACY_PRIVATEKEY=""
LEGACY_PUBLICKEY=""
LEGACY_NETWORK=""
LEGACY_EXTERNAL_PORT=""
LEGACY_XHTTP_PATH=""

load_state() {
  if [ ! -f "$STATE_FILE" ]; then
    return
  fi

  STATE_VALUES=$(jq -r '[.uuid // "", .private_key // "", .public_key // "", .dest // "", (.servernames // []) | join(" "), .network // "", .external_port // "", .xhttp_path // ""] | @tsv' "$STATE_FILE" 2>/dev/null)
  if [ -z "$STATE_VALUES" ]; then
    return
  fi

  IFS="$(printf '\t')" read -r STATE_UUID STATE_PRIVATEKEY STATE_PUBLICKEY STATE_DEST STATE_SERVERNAMES STATE_NETWORK STATE_EXTERNAL_PORT STATE_XHTTP_PATH <<EOF_STATE
$STATE_VALUES
EOF_STATE
}

load_legacy() {
  if [ -f "$INFO_FILE" ]; then
    LEGACY_INFO_FILE="$INFO_FILE"
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
  fi
}

filter_masked() {
  case "$1" in
    *"*"*) echo "" ;;
    *) echo "$1" ;;
  esac
}

load_state
load_legacy

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
  jq ".inbounds[1].port=$HOSTMODE_PORT" /config.json > /config.json_tmp && mv /config.json_tmp /config.json
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

if [ -z "$NETWORK" ]; then
  if [ -n "$STATE_NETWORK" ]; then
    NETWORK="$STATE_NETWORK"
  elif [ -n "$LEGACY_NETWORK" ]; then
    NETWORK="$LEGACY_NETWORK"
  fi
fi

if [ -z "$NETWORK" ]; then
  echo "NETWORK is not set,set default value xhttp"
  NETWORK="xhttp"
fi

SERVERNAMES_JSON_ARRAY="$(echo "[$(echo $SERVERNAMES | awk '{for(i=1;i<=NF;i++) printf "\"%s\",", $i}' | sed 's/,$//')]")"

jq \
  --arg uuid "$UUID" \
  --arg dest "$DEST" \
  --arg xhttp_path "$XHTTP_PATH" \
  --arg private_key "$PRIVATEKEY" \
  --arg network "$NETWORK" \
  --argjson serverNames "$SERVERNAMES_JSON_ARRAY" \
  '.inbounds[1].settings.clients[0].id = $uuid
  | .inbounds[1].streamSettings.realitySettings.dest = $dest
  | .inbounds[1].streamSettings.xhttpSettings.path = $xhttp_path
  | .inbounds[1].streamSettings.realitySettings.serverNames = $serverNames
  | .inbounds[1].streamSettings.realitySettings.privateKey = $private_key
  | .inbounds[1].streamSettings.network = $network' /config.json > /config.json_tmp && mv /config.json_tmp /config.json

jq -n \
  --arg uuid "$UUID" \
  --arg private_key "$PRIVATEKEY" \
  --arg public_key "$PUBLICKEY" \
  --arg dest "$DEST" \
  --arg network "$NETWORK" \
  --arg external_port "$EXTERNAL_PORT" \
  --arg xhttp_path "$XHTTP_PATH" \
  --argjson servernames "$SERVERNAMES_JSON_ARRAY" \
  '{uuid:$uuid, private_key:$private_key, public_key:$public_key, dest:$dest, servernames:$servernames, network:$network, external_port:$external_port, xhttp_path:$xhttp_path}' > "$STATE_FILE"

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
echo "XHTTP_PATH: $XHTTP_PATH" >> /config_info.txt

if [ "$IPV4" != "null" ]; then
  SUB_IPV4="vless://$UUID@$IPV4:$EXTERNAL_PORT?encryption=none&security=reality&type=$NETWORK&sni=$FIRST_SERVERNAME&fp=firefox&pbk=$PUBLICKEY&path=$XHTTP_PATH&mode=auto#${IPV4}-wulabing_docker_xhttp_reality"
  echo "IPV4 订阅连接: $SUB_IPV4" >> /config_info.txt
  echo -e "IPV4 订阅二维码:\n$(echo "$SUB_IPV4" | qrencode -o - -t UTF8)" >> /config_info.txt
fi
if [ "$IPV6" != "null" ]; then
  SUB_IPV6="vless://$UUID@$IPV6:$EXTERNAL_PORT?encryption=none&security=reality&type=$NETWORK&sni=$FIRST_SERVERNAME&fp=firefox&pbk=$PUBLICKEY&path=$XHTTP_PATH&mode=auto#${IPV6}-wulabing_docker_xhttp_reality"
  echo "IPV6 订阅连接: $SUB_IPV6" >> /config_info.txt
  echo -e "IPV6 订阅二维码:\n$(echo "$SUB_IPV6" | qrencode -o - -t UTF8)" >> /config_info.txt
fi

echo -e "\033[0m" >> /config_info.txt

cp -f /config_info.txt "$INFO_FILE"

# show config info
cat /config_info.txt

# run xray
exec /xray -config /config.json
