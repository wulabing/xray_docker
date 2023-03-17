#!/bin/sh
if [ -f /config_info.txt ]; then
  echo "config.json exist"
else
  if [ -z "$UUID" ]; then
    echo "UUID is not set, generate random UUID "
    UUID="$(uuidgen)"
    echo "UUID: $UUID"

  fi

  if [ -z "$DEST" ]; then
    echo "DEST is not set. default value www.apple.com:443"
    DEST="www.apple.com:443"
  fi

  if [ -z "$SERVERNAMES" ]; then
    echo "SERVERNAMES is not set. use default value [\"www.apple.com\",\"images.apple.com\"]"
    SERVERNAMES="www.apple.com images.apple.com"
  fi

  if [ -z "$PRIVATEKEY" ]; then
    echo "PRIVATEKEY is not set. generate new key"
    /xray x25519 >/key
    PRIVATEKEY=$(cat /key | grep "Private" | awk -F ': ' '{print $2}')
    PUBLICKEY=$(cat /key | grep "Public" | awk -F ': ' '{print $2}')
    echo "Private key: $PRIVATEKEY"
    echo "Public key: $PUBLICKEY"
  fi

  if [ -z "$NETWORK" ]; then
    echo "NETWORK is not set,set default value tcp"
    NETWORK="tcp"
  fi
  # change config
  jq ".inbounds[0].settings.clients[0].id=\"$UUID\"" /config.json >/config.json_tmp && mv /config.json_tmp /config.json
  jq ".inbounds[0].streamSettings.realitySettings.dest=\"$DEST\"" /config.json >/config.json_tmp && mv /config.json_tmp /config.json

  SERVERNAMES_JSON_ARRAY="$(echo "[$(echo $SERVERNAMES | awk '{for(i=1;i<=NF;i++) printf "\"%s\",", $i}' | sed 's/,$//')]")"
  jq --argjson serverNames "$SERVERNAMES_JSON_ARRAY" '.inbounds[0].streamSettings.realitySettings.serverNames = $serverNames' /config.json >/config.json_tmp && mv /config.json_tmp /config.json

  jq ".inbounds[0].streamSettings.realitySettings.privateKey=\"$PRIVATEKEY\"" /config.json >/config.json_tmp && mv /config.json_tmp /config.json
  jq ".inbounds[0].streamSettings.network=\"$NETWORK\"" /config.json >/config.json_tmp && mv /config.json_tmp /config.json

  # config info with green color
  echo -e "\033[32m" >/config_info.txt
  echo "UUID: $UUID" >>/config_info.txt
  echo "DEST: $DEST" >>/config_info.txt
  echo "SERVERNAMES: $SERVERNAMES (任选其一)" >>/config_info.txt
  echo "PRIVATEKEY: $PRIVATEKEY" >>/config_info.txt
  echo "PUBLICKEY: $PUBLICKEY" >>/config_info.txt
  echo "NETWORK: $NETWORK" >>/config_info.txt
  echo -e "\033[0m" >>/config_info.txt
fi

# show config info
cat /config_info.txt

# run xray
exec /xray -config /config.json
