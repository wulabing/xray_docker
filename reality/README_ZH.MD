[English](README.MD) | **简体中文**

## xray_docker_reality

XRay VLESS-Reality Docker 镜像，支持 tcp（vision）、xhttp、后置代理以及self-steal。

[![xray_docker_reality_docker_image_build](https://github.com/wulabing/xray_docker/actions/workflows/xray_docker_reality.yml/badge.svg)](https://github.com/wulabing/xray_docker/actions/workflows/xray_docker_reality.yml)

> 镜像每两天 UTC+8 04:00 自动构建。

> 还没有 VPS？可通过我的 AFF 购买：[搬瓦工](https://bandwagonhost.com/aff.php?aff=63939) / [DMIT](https://www.dmit.io/aff.php?aff=3957) / [Vultr](https://www.vultr.com/?ref=6881279) / [nube 按量付费](https://nube.sh/invite/5986088028ENM0)

## ❤️ 赞助商

> 想出现在这里？欢迎通过 issue 或 [Telegram 群组](https://t.me/wulabing_v2ray) 联系我

<table>
<tr>
<td width="180"><a href="https://api.capybaracode.cc/register?aff=ENZE8PZ2VBDE"><img src="https://raw.githubusercontent.com/wulabing/xray_docker/master/image/sponsors/capybaracode.png" alt="CapybaraCode" width="150"></a></td>
<td>感谢 <a href="https://api.capybaracode.cc/register?aff=ENZE8PZ2VBDE">CapybaraCode</a> 赞助本项目 —— 这是本项目收到的第一笔赞助，感谢这份认可！<br>稳定、低延迟的 Claude Code / AI 编码 API 中转服务，开箱即用、按量计费，日常写代码足够顺手。注册时填写优惠码 <code>WULABING</code> 可额外获得 <b>4 美元</b>额度。</td>
</tr>
<tr>
<td width="180"><a href="https://www.uhdnow.com/signup?invite=IMAX4K"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/wulabing/xray_docker/master/image/sponsors/uhdnow-dark.png"><img src="https://raw.githubusercontent.com/wulabing/xray_docker/master/image/sponsors/uhdnow.png" alt="UHDNOW" width="150"></picture></a></td>
<td>感谢 <a href="https://www.uhdnow.com/signup?invite=IMAX4K">UHDNOW</a> 赞助本项目！<br>一个用心维护的 Emby 私服，4K / IMAX 原盘、杜比视界与 HDR 片源齐全，多线路直连、拖拉即播，喜欢折腾影音的朋友可以去看看。</td>
</tr>
</table>

## 懒人一键安装

```
EXTERNAL_PORT=2333 && docker run -d --name xray_reality --restart=always --log-opt max-size=100m --log-opt max-file=3 -p $EXTERNAL_PORT:443 -e EXTERNAL_PORT=$EXTERNAL_PORT wulabing/xray_docker_reality:latest && sleep 3 && docker exec -it xray_reality cat /config_info.txt
```

## 快速开始

未安装 Docker 时：

```
curl -fsSL get.docker.com -o get-docker.sh && sh get-docker.sh
```

**端口映射**（`EXTERNAL_PORT` 为宿主机对外端口）：

```
docker pull wulabing/xray_docker_reality:latest
EXTERNAL_PORT=443
docker run -d --name xray_reality --restart=always --log-opt max-size=100m --log-opt max-file=3 -p $EXTERNAL_PORT:443 -e EXTERNAL_PORT=$EXTERNAL_PORT wulabing/xray_docker_reality:latest
```

**host 模式**（使用 `HOSTMODE_PORT`，`EXTERNAL_PORT` 不生效）：

```
docker pull wulabing/xray_docker_reality:latest
HOSTMODE_PORT=443
docker run -d --name xray_reality --restart=always --log-opt max-size=100m --log-opt max-file=3 --network host -e HOSTMODE_PORT=$HOSTMODE_PORT wulabing/xray_docker_reality:latest
```

**持久化配置（推荐）**：挂载 `./wulabing_xray_config:/data`，更新镜像后 UUID/密钥/订阅不变。旧版 `config_info.txt`、`xhttp_reality_state.json` 等文件名会自动兼容读取。

```
docker pull wulabing/xray_docker_reality:latest
EXTERNAL_PORT=443
docker run -d --name xray_reality --restart=always --log-opt max-size=100m --log-opt max-file=3 -p $EXTERNAL_PORT:443 -e EXTERNAL_PORT=$EXTERNAL_PORT -v "./wulabing_xray_config:/data" wulabing/xray_docker_reality:latest
```

## 获取配置信息

```
docker logs -f xray_reality
```

## 进阶配置

**自定义 Reality 参数**（需自行保证参数正确；多个 `SERVERNAMES` 用空格分隔）：

```
EXTERNAL_PORT=443
docker run -d --name xray_reality --restart=always --log-opt max-size=100m --log-opt max-file=3 -p $EXTERNAL_PORT:443 -e EXTERNAL_PORT=$EXTERNAL_PORT -e UUID="XXX" -e SERVERNAMES="www.apple.com images.apple.com" -e DEST="www.apple.com:443" -e PRIVATEKEY="XXX" -v "./wulabing_xray_config:/data" wulabing/xray_docker_reality:latest
```

**xhttp 模式**：`NETWORK=xhttp`（默认 `tcp` 为 vless-vision）。`XHTTP_PATH` 未设置时随机生成。

```
docker run -d --name xray_reality --restart=always --log-opt max-size=100m --log-opt max-file=3 -p 443:443 -e NETWORK=xhttp -v "./wulabing_xray_config:/data" wulabing/xray_docker_reality:latest
```

**shortId**：`SHORTIDS` 为空格分隔的 hex（偶数长度、≤16）。不设置时留空；仅非空时在订阅链接附加 `&sid=`。

```
docker run -d --name xray_reality --restart=always --log-opt max-size=100m --log-opt max-file=3 -p 443:443 -e SHORTIDS="6ba85179e30d4fc2" -v "./wulabing_xray_config:/data" wulabing/xray_docker_reality:latest
```

**后置代理**：`PROXY` 为 `socks5://` 或 `http://` URL（可含账密）。启用后除 `geoip:cn`、`geoip:private`、`bittorrent` 外，其余出站走上游代理。主要用于链式代理纯净家宽 IP，用于解锁 Netflix 流媒体及 AI 使用/付款场景

> 推荐家宽代理（AFF）：[Proxy-Cheap](https://app.proxy-cheap.com/r/Pbqf9l) / [IPRoyal](https://iproyal.cn/?r=249487) / [Thordata](https://dashboard.thordata.com/zh/register?invitation_code=5P8NDLWV)（动态住宅代理 1–350GB 九折，优惠码：`WULABING`），购买 socks5/http 家宽代理后填入 `PROXY` 即可

```
# socks5
docker run -d --name xray_reality --restart=always --log-opt max-size=100m --log-opt max-file=3 -p 443:443 -e PROXY="socks5://user:pass@1.2.3.4:1080" wulabing/xray_docker_reality:latest

# http
docker run -d --name xray_reality --restart=always --log-opt max-size=100m --log-opt max-file=3 -p 443:443 -e PROXY="http://user:pass@10.0.0.1:8080" wulabing/xray_docker_reality:latest
```

**偷自己（self-steal）**：设置 `DOMAIN` 后内置 Caddy 为该域名签 Let's Encrypt 证书并托管站点，`DEST`/`SERVERNAMES` 由域名自动接管。需 DNS 指向本机，并映射 **80 与 443**；首次签发证书需等待数秒至数十秒。可与 `NETWORK=xhttp`、`SHORTIDS`、`PROXY` 组合使用。

```
docker run -d --name xray_reality --restart=always --log-opt max-size=100m --log-opt max-file=3 -p 443:443 -p 80:80 -e DOMAIN="your.domain.com" -v "./wulabing_xray_config:/data" wulabing/xray_docker_reality:latest
```

> **建议自定义伪装站点以提升隐蔽性**——挂载自己的静态站点目录到 `/srv/www` 即可覆盖默认页：

```
docker run -d --name xray_reality --restart=always --log-opt max-size=100m --log-opt max-file=3 -p 443:443 -p 80:80 -e DOMAIN="your.domain.com" -v "./my_site:/srv/www" -v "./wulabing_xray_config:/data" wulabing/xray_docker_reality:latest
```

**多实例**：不同 `--name` 与端口，避免冲突。

```
EXTERNAL_PORT=444
docker run -d --name xray_reality_1 --restart=always --log-opt max-size=100m --log-opt max-file=3 -p $EXTERNAL_PORT:443 -e EXTERNAL_PORT=$EXTERNAL_PORT wulabing/xray_docker_reality:latest

EXTERNAL_PORT=445
docker run -d --name xray_reality_2 --restart=always --log-opt max-size=100m --log-opt max-file=3 -p $EXTERNAL_PORT:443 -e EXTERNAL_PORT=$EXTERNAL_PORT wulabing/xray_docker_reality:latest
```

**删除容器**：将 `xray_reality` 替换为实际容器名。

```
docker rm -f xray_reality
```

## 环境变量

* UUID：XRay 的唯一用户标识符。若未设置，脚本将自动生成一个随机 UUID。
* DEST：目标地址。默认值为 www.apple.com:443。（偷自己模式下由 DOMAIN 自动接管）
* SERVERNAMES：服务器名称列表（空格分隔）。默认值为 www.apple.com images.apple.com。（偷自己模式下由 DOMAIN 自动接管）
* PRIVATEKEY：私钥。若未设置，脚本将自动生成一个新的私钥和对应的公钥。
* NETWORK：网络类型，`tcp`（vless-vision）或 `xhttp`。默认值为 tcp。
* XHTTP_PATH：xhttp 模式的路径，仅 NETWORK=xhttp 生效。未设置时随机生成。
* SHORTIDS：reality shortId（空格分隔可多个，hex/偶数长度/≤16）。默认留空。
* PROXY：后置代理 URL，`socks5://[user:pass@]host:port` 或 `http://[user:pass@]host:port`。默认不启用。（家宽代理推荐见「后置代理」章节）
* DOMAIN：偷自己模式的自有域名，设置后自动启用内置 Caddy 自建站。默认不启用。
* ACME_EMAIL：偷自己模式下 ACME 证书注册邮箱（可选）。
* EXTERNAL_PORT：端口映射模式对外端口。默认 443。
* HOSTMODE_PORT：host 模式端口。
* CONFIG_DIR：持久化目录。默认值为 /data。

## 常量

* flow：xtls-rprx-vision（tcp 模式）/ 留空（xhttp 模式）
* security：reality

## 注意事项

请确保在使用前已正确安装和配置 XRay 客户端。
为了保证安全和稳定，请勿将 UUID、私钥等敏感信息泄露给他人。
容器默认限制日志大小（`max-size=100m`、`max-file=3`），可按需调整。

## 支持这个项目

如果您想支持我，可以走我的 AFF 购买服务器 / 代理：

**服务器 / 代理：** [搬瓦工](https://bandwagonhost.com/aff.php?aff=63939) · [JustMySocks](https://justmysocks.net/members/aff.php?aff=17621) · [DMIT](https://www.dmit.io/aff.php?aff=3957) · [Nube.sh（按量付费）](https://nube.sh/invite/5986088028ENM0) · [Vultr](https://www.vultr.com/?ref=6881279)

**socks5 / http 家宽代理：** [Proxy-Cheap](https://app.proxy-cheap.com/r/Pbqf9l) · [IPRoyal](https://iproyal.cn/?r=249487) · [Thordata](https://dashboard.thordata.com/zh/register?invitation_code=5P8NDLWV)（动态住宅代理 1–350GB 九折，优惠码：`WULABING`）

也可以通过 USDT 支持我，感谢您的支持 —— TRC20：`TU8mLTPfa5Y9nmszyfyt2VRAtuZhdLexL8`
