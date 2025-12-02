# Xray Docker 限速配置说明

## 功能介绍

新增了限速配置功能，支持对上传和下载流量进行限速控制。同时优化了文件结构，将配置文件和生成的信息文件放入 `/app` 目录下，便于持久化。

## 环境变量

### 新增环境变量

- `ENABLE_RATE_LIMIT`: 是否启用限速功能
  - `true`: 启用限速配置
  - `false` 或未设置: 不启用限速（默认）

### 限速参数说明

当 `ENABLE_RATE_LIMIT=true` 时，系统会自动应用以下限速配置：

```json
{
  "limitFallbackUpload": {
    "afterBytes": 4194304,       // 前 4MB 不限速
    "burstBytesPerSec": 94208,   // 最大突发：92 KB/s
    "bytesPerSec": 20480         // 持续限速：20 KB/s
  },
  "limitFallbackDownload": {
    "afterBytes": 4194304,       // 前 4MB 不限速
    "burstBytesPerSec": 94208,   // 最大突发：92 KB/s
    "bytesPerSec": 20480         // 持续限速：20 KB/s
  }
}
```

## 文件持久化

### 新的文件结构

- `/app/config.json`: 运行时配置文件
- `/app/config_info.txt`: 连接信息和二维码

### Docker 挂载

推荐使用以下方式挂载 `/app` 目录以实现配置持久化：

```bash
docker run -d \
  -v /path/to/local/app:/app \
  -p 443:443 \
  -e ENABLE_RATE_LIMIT=true \
  your-image-name
```

## 使用示例

### Reality 版本

```bash
# 启用限速
docker run -d \
  --name xray-reality \
  -v ./xray-app:/app \
  -p 443:443 \
  -e UUID=your-uuid \
  -e DEST=www.apple.com:443 \
  -e SERVERNAMES="www.apple.com images.apple.com" \
  -e ENABLE_RATE_LIMIT=true \
  xray-reality:latest

# 不启用限速（默认）
docker run -d \
  --name xray-reality \
  -v ./xray-app:/app \
  -p 443:443 \
  -e UUID=your-uuid \
  -e DEST=www.apple.com:443 \
  -e SERVERNAMES="www.apple.com images.apple.com" \
  xray-reality:latest
```

### XHTTP Reality 版本

```bash
# 启用限速
docker run -d \
  --name xray-xhttp-reality \
  -v ./xray-app:/app \
  -p 443:443 \
  -e UUID=your-uuid \
  -e DEST=www.apple.com:443 \
  -e SERVERNAMES="www.apple.com images.apple.com" \
  -e XHTTP_PATH=/custom-path \
  -e ENABLE_RATE_LIMIT=true \
  xray-xhttp-reality:latest
```

## Docker Compose 示例

```yaml
version: '3.8'

services:
  xray-reality:
    image: xray-reality:latest
    container_name: xray-reality
    ports:
      - "443:443"
    volumes:
      - ./xray-app:/app
    environment:
      - UUID=your-uuid-here
      - DEST=www.apple.com:443
      - SERVERNAMES=www.apple.com images.apple.com
      - ENABLE_RATE_LIMIT=true
    restart: unless-stopped

  xray-xhttp-reality:
    image: xray-xhttp-reality:latest
    container_name: xray-xhttp-reality
    ports:
      - "444:443"
    volumes:
      - ./xray-xhttp-app:/app
    environment:
      - UUID=your-uuid-here
      - DEST=www.apple.com:443
      - SERVERNAMES=www.apple.com images.apple.com
      - XHTTP_PATH=/custom-path
      - ENABLE_RATE_LIMIT=true
    restart: unless-stopped
```

## 配置信息查看

容器启动后，可以通过以下方式查看配置信息：

```bash
# 查看配置信息
docker exec xray-reality cat /app/config_info.txt

# 或者直接查看挂载的本地文件
cat ./xray-app/config_info.txt
```

配置信息中会显示是否启用了限速：
```
RATE_LIMIT_ENABLED: true  # 或 false
```

## 注意事项

1. 限速配置只有在 `ENABLE_RATE_LIMIT=true` 时才会生效
2. 配置文件会在首次运行时生成，如需重新生成，请删除 `/app/config_info.txt` 文件
3. 挂载 `/app` 目录可以保持配置在容器重启后不丢失
4. 限速参数目前是固定的，如需自定义可以修改 `entrypoint.sh` 脚本