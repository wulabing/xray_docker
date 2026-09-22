[English](README.MD) | **简体中文**

## xray_docker_xhttp_reality（已合并至 reality）

> ⚠️ **本镜像已停止独立维护。** 自 `reality` 镜像 0.1.0 起，xhttp 模式已整合进统一的 `wulabing/xray_docker_reality` 镜像

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

## 如何迁移

只需改用 `reality` 镜像并设置 `NETWORK=xhttp`，其余参数（UUID/DEST/SERVERNAMES/PRIVATEKEY/XHTTP_PATH）保持一致即可：

```
docker pull wulabing/xray_docker_reality:latest
docker run -d --name xray_xhttp_reality --restart=always --log-opt max-size=100m --log-opt max-file=3 \
  -p 443:443 -e NETWORK=xhttp \
  -v "./wulabing_xray_config:/data" \
  wulabing/xray_docker_reality:latest
```

旧的持久化文件（`xhttp_reality_state.json` / `xhttp_reality_config_info.txt`）会被新镜像自动兼容读取，连接信息保持不变。

完整使用说明请见 👉 [xray_docker_reality](https://github.com/wulabing/xray_docker/tree/master/reality)

## 支持这个项目

如果您想支持我，可以走我的 AFF 购买服务器 / 代理：

**服务器 / 代理：** [搬瓦工](https://bandwagonhost.com/aff.php?aff=63939) · [JustMySocks](https://justmysocks.net/members/aff.php?aff=17621) · [DMIT](https://www.dmit.io/aff.php?aff=3957) · [Nube.sh（按量付费）](https://nube.sh/invite/5986088028ENM0) · [Vultr](https://www.vultr.com/?ref=6881279)

**socks5 / http 家宽代理：** [Proxy-Cheap](https://app.proxy-cheap.com/r/Pbqf9l) · [IPRoyal](https://iproyal.cn/?r=249487) · [Thordata](https://dashboard.thordata.com/zh/register?invitation_code=5P8NDLWV)（动态住宅代理 1–350GB 九折，优惠码：`WULABING`）

也可以通过 USDT 支持我，感谢您的支持 —— TRC20：`TU8mLTPfa5Y9nmszyfyt2VRAtuZhdLexL8`
