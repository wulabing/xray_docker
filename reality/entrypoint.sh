#!/bin/sh
# 创建 app 目录用于持久化
mkdir -p /app

if [ -f /app/config_info.txt ]; then
  echo "config.json exist"
else
  IPV6=$(curl -6 -sSL --connect-timeout 3 --retry 2  ip.sb || echo "null")
  IPV4=$(curl -4 -sSL --connect-timeout 3 --retry 2  ip.sb || echo "null")
  if [ -z "$UUID" ]; then
    echo "UUID is not set, generate random UUID "
    UUID="$(/xray uuid)"
    echo "UUID: $UUID"
  fi

  if [ -z "$EXTERNAL_PORT" ]; then
    echo "EXTERNAL_PORT is not set, use default value 443"
    EXTERNAL_PORT=443
  fi

  if [ -n "$HOSTMODE_PORT" ];then
    EXTERNAL_PORT=$HOSTMODE_PORT
    jq ".inbounds[0].port=$HOSTMODE_PORT" /config.json >/config.json_tmp && mv /config.json_tmp /config.json
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
    PUBLICKEY=$(cat /key | grep "Password" | awk -F ': ' '{print $2}')
    echo "Private key: $PRIVATEKEY"
    echo "Public key: $PUBLICKEY"
  fi

  if [ -z "$NETWORK" ]; then
    echo "NETWORK is not set,set default value tcp"
    NETWORK="tcp"
  fi

  if [ -z "$ENABLE_RATE_LIMIT" ]; then
    echo "ENABLE_RATE_LIMIT is not set, default value false"
    ENABLE_RATE_LIMIT="false"
  fi

  # 复制配置文件到 app 目录
  cp /config.json /app/config.json

  # change config
  jq ".inbounds[1].settings.clients[0].id=\"$UUID\"" /app/config.json >/app/config.json_tmp && mv /app/config.json_tmp /app/config.json
  jq ".inbounds[1].streamSettings.realitySettings.dest=\"$DEST\"" /app/config.json >/app/config.json_tmp && mv /app/config.json_tmp /app/config.json

  SERVERNAMES_JSON_ARRAY="$(echo "[$(echo $SERVERNAMES | awk '{for(i=1;i<=NF;i++) printf "\"%s\",", $i}' | sed 's/,$//')]")"
  jq --argjson serverNames "$SERVERNAMES_JSON_ARRAY" '.inbounds[1].streamSettings.realitySettings.serverNames = $serverNames' /app/config.json >/app/config.json_tmp && mv /app/config.json_tmp /app/config.json
  jq --argjson serverNames "$SERVERNAMES_JSON_ARRAY" '.routing.rules[0].domain = $serverNames' /app/config.json >/app/config.json_tmp && mv /app/config.json_tmp /app/config.json

  jq ".inbounds[1].streamSettings.realitySettings.privateKey=\"$PRIVATEKEY\"" /app/config.json >/app/config.json_tmp && mv /app/config.json_tmp /app/config.json
  jq ".inbounds[1].streamSettings.network=\"$NETWORK\"" /app/config.json >/app/config.json_tmp && mv /app/config.json_tmp /app/config.json

  # 添加防盗流量限速配置
  if [ "$ENABLE_RATE_LIMIT" = "true" ]; then
    echo "Enabling rate limit configuration for reality fallback"
    jq '.inbounds[1].streamSettings.realitySettings.limitFallbackUpload = {
      "afterBytes": 4194304,
      "burstBytesPerSec": 94208,
      "bytesPerSec": 20480
    }' /app/config.json >/app/config.json_tmp && mv /app/config.json_tmp /app/config.json
    
    jq '.inbounds[1].streamSettings.realitySettings.limitFallbackDownload = {
      "afterBytes": 4194304,
      "burstBytesPerSec": 94208,
      "bytesPerSec": 20480
    }' /app/config.json >/app/config.json_tmp && mv /app/config.json_tmp /app/config.json
  fi



  FIRST_SERVERNAME=$(echo $SERVERNAMES | awk '{print $1}')
  # config info with green color
  echo -e "\033[32m" >/app/config_info.txt
  echo "IPV6: $IPV6" >>/app/config_info.txt
  echo "IPV4: $IPV4" >>/app/config_info.txt
  echo "UUID: $UUID" >>/app/config_info.txt
  echo "DEST: $DEST" >>/app/config_info.txt
  echo "PORT: $EXTERNAL_PORT" >>/app/config_info.txt
  echo "SERVERNAMES: $SERVERNAMES (任选其一)" >>/app/config_info.txt
  echo "PRIVATEKEY: $PRIVATEKEY" >>/app/config_info.txt
  echo "PUBLICKEY/PASSWORD: $PUBLICKEY" >>/app/config_info.txt
  echo "NETWORK: $NETWORK" >>/app/config_info.txt
  echo "RATE_LIMIT_ENABLED: $ENABLE_RATE_LIMIT" >>/app/config_info.txt
  if [ "$IPV4" != "null" ]; then
    SUB_IPV4="vless://$UUID@$IPV4:$EXTERNAL_PORT?encryption=none&security=reality&type=$NETWORK&sni=$FIRST_SERVERNAME&fp=chrome&pbk=$PUBLICKEY&flow=xtls-rprx-vision#${IPV4}-wulabing_docker_vless_reality_vision"
    echo "IPV4 订阅连接: $SUB_IPV4" >>/app/config_info.txt
    echo -e "IPV4 订阅二维码:\n$(echo "$SUB_IPV4" | qrencode -o - -t UTF8)" >>/app/config_info.txt
  fi
  if [ "$IPV6" != "null" ];then
    SUB_IPV6="vless://$UUID@$IPV6:$EXTERNAL_PORT?encryption=none&security=reality&type=$NETWORK&sni=$FIRST_SERVERNAME&fp=chrome&pbk=$PUBLICKEY&flow=xtls-rprx-vision#${IPV6}-wulabing_docker_vless_reality_vision"
    echo "IPV6 订阅连接: $SUB_IPV6" >>/app/config_info.txt
    echo -e "IPV6 订阅二维码:\n$(echo "$SUB_IPV6" | qrencode -o - -t UTF8)" >>/app/config_info.txt
  fi


  echo -e "\033[0m" >>/app/config_info.txt

fi

# show config info
cat /app/config_info.txt

# run xray
exec /xray -config /app/config.json
