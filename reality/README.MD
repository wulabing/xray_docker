**English** | [简体中文](README_ZH.MD)

## xray_docker_reality

XRay VLESS-Reality Docker image, supporting tcp (vision), xhttp, an upstream (outbound) proxy and self-steal.

[![xray_docker_reality_docker_image_build](https://github.com/wulabing/xray_docker/actions/workflows/xray_docker_reality.yml/badge.svg)](https://github.com/wulabing/xray_docker/actions/workflows/xray_docker_reality.yml)

> The image is rebuilt automatically every two days at 04:00 UTC+8.

> No VPS yet? You can buy one through my affiliate links: [BandwagonHost](https://bandwagonhost.com/aff.php?aff=63939) / [DMIT](https://www.dmit.io/aff.php?aff=3957) / [Vultr](https://www.vultr.com/?ref=6881279) / [nube pay-as-you-go](https://nube.sh/invite/5986088028ENM0)

## ❤️ Sponsors

> Want to appear here? Feel free to reach out via an issue or the [Telegram group](https://t.me/wulabing_v2ray)

<table>
<tr>
<td width="180"><a href="https://api.capybaracode.cc/register?aff=ENZE8PZ2VBDE"><img src="https://raw.githubusercontent.com/wulabing/xray_docker/master/image/sponsors/capybaracode.png" alt="CapybaraCode" width="150"></a></td>
<td>Thanks to <a href="https://api.capybaracode.cc/register?aff=ENZE8PZ2VBDE">CapybaraCode</a> for sponsoring this project — the very first sponsorship this project has received, and I truly appreciate the recognition!<br>A stable, low-latency API relay service for Claude Code / AI coding. Works out of the box, pay-as-you-go, and smooth enough for daily coding work. Enter the promo code <code>WULABING</code> when signing up to get an extra <b>$4</b> in credit.</td>
</tr>
<tr>
<td width="180"><a href="https://www.uhdnow.com/signup?invite=IMAX4K"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/wulabing/xray_docker/master/image/sponsors/uhdnow-dark.png"><img src="https://raw.githubusercontent.com/wulabing/xray_docker/master/image/sponsors/uhdnow.png" alt="UHDNOW" width="150"></picture></a></td>
<td>Thanks to <a href="https://www.uhdnow.com/signup?invite=IMAX4K">UHDNOW</a> for sponsoring this project!<br>A carefully maintained private Emby server with a full catalogue of 4K / IMAX remuxes, Dolby Vision and HDR sources, multiple direct-connect routes and instant seeking. Worth a look if you are into home media.</td>
</tr>
</table>

## One-Line Install

```
EXTERNAL_PORT=2333 && docker run -d --name xray_reality --restart=always --log-opt max-size=100m --log-opt max-file=3 -p $EXTERNAL_PORT:443 -e EXTERNAL_PORT=$EXTERNAL_PORT wulabing/xray_docker_reality:latest && sleep 3 && docker exec -it xray_reality cat /config_info.txt
```

## Quick Start

If Docker is not installed yet:

```
curl -fsSL get.docker.com -o get-docker.sh && sh get-docker.sh
```

**Port mapping** (`EXTERNAL_PORT` is the port exposed on the host):

```
docker pull wulabing/xray_docker_reality:latest
EXTERNAL_PORT=443
docker run -d --name xray_reality --restart=always --log-opt max-size=100m --log-opt max-file=3 -p $EXTERNAL_PORT:443 -e EXTERNAL_PORT=$EXTERNAL_PORT wulabing/xray_docker_reality:latest
```

**host mode** (use `HOSTMODE_PORT`; `EXTERNAL_PORT` has no effect):

```
docker pull wulabing/xray_docker_reality:latest
HOSTMODE_PORT=443
docker run -d --name xray_reality --restart=always --log-opt max-size=100m --log-opt max-file=3 --network host -e HOSTMODE_PORT=$HOSTMODE_PORT wulabing/xray_docker_reality:latest
```

**Persistent configuration (recommended)**: mount `./wulabing_xray_config:/data` so that the UUID, keys and subscription stay the same after updating the image. Legacy file names such as `config_info.txt` and `xhttp_reality_state.json` are still read automatically.

```
docker pull wulabing/xray_docker_reality:latest
EXTERNAL_PORT=443
docker run -d --name xray_reality --restart=always --log-opt max-size=100m --log-opt max-file=3 -p $EXTERNAL_PORT:443 -e EXTERNAL_PORT=$EXTERNAL_PORT -v "./wulabing_xray_config:/data" wulabing/xray_docker_reality:latest
```

## Retrieving the Connection Info

```
docker logs -f xray_reality
```

## Advanced Configuration

**Custom Reality parameters** (you are responsible for their correctness; separate multiple `SERVERNAMES` with spaces):

```
EXTERNAL_PORT=443
docker run -d --name xray_reality --restart=always --log-opt max-size=100m --log-opt max-file=3 -p $EXTERNAL_PORT:443 -e EXTERNAL_PORT=$EXTERNAL_PORT -e UUID="XXX" -e SERVERNAMES="www.apple.com images.apple.com" -e DEST="www.apple.com:443" -e PRIVATEKEY="XXX" -v "./wulabing_xray_config:/data" wulabing/xray_docker_reality:latest
```

**xhttp mode**: `NETWORK=xhttp` (the default `tcp` means vless-vision). `XHTTP_PATH` is generated randomly when not set.

```
docker run -d --name xray_reality --restart=always --log-opt max-size=100m --log-opt max-file=3 -p 443:443 -e NETWORK=xhttp -v "./wulabing_xray_config:/data" wulabing/xray_docker_reality:latest
```

**shortId**: `SHORTIDS` is a space-separated list of hex strings (even length, ≤16). Left empty when not set; `&sid=` is appended to the subscription link only when it is non-empty.

```
docker run -d --name xray_reality --restart=always --log-opt max-size=100m --log-opt max-file=3 -p 443:443 -e SHORTIDS="6ba85179e30d4fc2" -v "./wulabing_xray_config:/data" wulabing/xray_docker_reality:latest
```

**Upstream proxy**: `PROXY` is a `socks5://` or `http://` URL (credentials may be included). Once enabled, all outbound traffic goes through the upstream proxy except `geoip:cn`, `geoip:private` and `bittorrent`. This is mainly used for proxy chaining through a clean residential IP, to unblock Netflix and other streaming services, and for AI usage / payment scenarios.

> Recommended residential proxies (affiliate): [Proxy-Cheap](https://app.proxy-cheap.com/r/Pbqf9l) / [IPRoyal](https://iproyal.cn/?r=249487) / [Thordata](https://dashboard.thordata.com/zh/register?invitation_code=5P8NDLWV) (10% off rotating residential proxies, 1–350GB; code: `WULABING`) — buy a socks5/http residential proxy and put it in `PROXY`

```
# socks5
docker run -d --name xray_reality --restart=always --log-opt max-size=100m --log-opt max-file=3 -p 443:443 -e PROXY="socks5://user:pass@1.2.3.4:1080" wulabing/xray_docker_reality:latest

# http
docker run -d --name xray_reality --restart=always --log-opt max-size=100m --log-opt max-file=3 -p 443:443 -e PROXY="http://user:pass@10.0.0.1:8080" wulabing/xray_docker_reality:latest
```

**Self-steal**: once `DOMAIN` is set, the built-in Caddy issues a Let's Encrypt certificate for that domain and serves the site, and `DEST`/`SERVERNAMES` are taken over by the domain automatically. DNS must point to this machine and **both 80 and 443** must be mapped; the first certificate issuance takes anywhere from a few seconds to a few dozen seconds. Can be combined with `NETWORK=xhttp`, `SHORTIDS` and `PROXY`.

```
docker run -d --name xray_reality --restart=always --log-opt max-size=100m --log-opt max-file=3 -p 443:443 -p 80:80 -e DOMAIN="your.domain.com" -v "./wulabing_xray_config:/data" wulabing/xray_docker_reality:latest
```

> **Customising the decoy site is recommended for better camouflage** — mount your own static site directory to `/srv/www` to override the default page:

```
docker run -d --name xray_reality --restart=always --log-opt max-size=100m --log-opt max-file=3 -p 443:443 -p 80:80 -e DOMAIN="your.domain.com" -v "./my_site:/srv/www" -v "./wulabing_xray_config:/data" wulabing/xray_docker_reality:latest
```

**Multiple instances**: use different `--name` values and ports to avoid conflicts.

```
EXTERNAL_PORT=444
docker run -d --name xray_reality_1 --restart=always --log-opt max-size=100m --log-opt max-file=3 -p $EXTERNAL_PORT:443 -e EXTERNAL_PORT=$EXTERNAL_PORT wulabing/xray_docker_reality:latest

EXTERNAL_PORT=445
docker run -d --name xray_reality_2 --restart=always --log-opt max-size=100m --log-opt max-file=3 -p $EXTERNAL_PORT:443 -e EXTERNAL_PORT=$EXTERNAL_PORT wulabing/xray_docker_reality:latest
```

**Removing the container**: replace `xray_reality` with the actual container name.

```
docker rm -f xray_reality
```

## Environment Variables

* UUID: the unique user identifier for XRay. If not set, the script generates a random UUID.
* DEST: the destination address. Defaults to www.apple.com:443. (Taken over by DOMAIN in self-steal mode.)
* SERVERNAMES: the list of server names (space-separated). Defaults to www.apple.com images.apple.com. (Taken over by DOMAIN in self-steal mode.)
* PRIVATEKEY: the private key. If not set, the script generates a new private key and its matching public key.
* NETWORK: the network type, `tcp` (vless-vision) or `xhttp`. Defaults to tcp.
* XHTTP_PATH: the path for xhttp mode; only effective when NETWORK=xhttp. Generated randomly when not set.
* SHORTIDS: reality shortId (space-separated for multiple values; hex, even length, ≤16). Empty by default.
* PROXY: the upstream proxy URL, `socks5://[user:pass@]host:port` or `http://[user:pass@]host:port`. Disabled by default. (See the "Upstream proxy" section for residential proxy recommendations.)
* DOMAIN: your own domain for self-steal mode; setting it automatically enables the built-in Caddy site. Disabled by default.
* ACME_EMAIL: the ACME certificate registration email for self-steal mode (optional).
* EXTERNAL_PORT: the external port in port-mapping mode. Defaults to 443.
* HOSTMODE_PORT: the port in host mode.
* CONFIG_DIR: the persistence directory. Defaults to /data.

## Constants

* flow: xtls-rprx-vision (tcp mode) / empty (xhttp mode)
* security: reality

## Notes

Make sure the XRay client is properly installed and configured before use.
For security and stability, never share sensitive information such as your UUID or private key with anyone.
The container limits log size by default (`max-size=100m`, `max-file=3`); adjust as needed.

## Support This Project

If you would like to support me, you can buy servers / proxies through my affiliate links:

**Servers / proxies:** [BandwagonHost](https://bandwagonhost.com/aff.php?aff=63939) · [JustMySocks](https://justmysocks.net/members/aff.php?aff=17621) · [DMIT](https://www.dmit.io/aff.php?aff=3957) · [Nube.sh (pay-as-you-go)](https://nube.sh/invite/5986088028ENM0) · [Vultr](https://www.vultr.com/?ref=6881279)

**socks5 / http residential proxies:** [Proxy-Cheap](https://app.proxy-cheap.com/r/Pbqf9l) · [IPRoyal](https://iproyal.cn/?r=249487) · [Thordata](https://dashboard.thordata.com/zh/register?invitation_code=5P8NDLWV) (10% off rotating residential proxies, 1–350GB; code: `WULABING`)

You can also support me with USDT — thank you for your support — TRC20: `TU8mLTPfa5Y9nmszyfyt2VRAtuZhdLexL8`
