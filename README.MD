## xray_docker_reality
xray reality docker 镜像

[![xray_docker_reality_docker_image_build](https://github.com/wulabing/xray_docker/actions/workflows/xray_docker_reality.yml/badge.svg)](https://github.com/wulabing/xray_docker/actions/workflows/xray_docker_reality.yml)

> 新的命令中添加了日志大小的限制，可以调整 max-size=100m 的数量来调整日志的最大大小，需要限制日志大小的用户请重新创建容器

## 懒人一键安装（docker已经准备好）
```
EXTERNAL_PORT=2333 && docker run -d --name xray_reality --restart=always --log-opt max-size=100m --log-opt max-file=3 -p $EXTERNAL_PORT:443 -e EXTERNAL_PORT=$EXTERNAL_PORT wulabing/xray_docker_reality:latest && sleep 3 && docker exec -it xray_reality cat /config_info.txt
```

## 基础使用方法

如果你没有安装 docker 请先安装 docker

```
curl -fsSL get.docker.com -o get-docker.sh && sh get-docker.sh
```
### 端口映射模式
如果你已经安装 docker，可以直接使用下面的命令，运行后会自动下载镜像并启动容器，
EXTERNAL_PORT 为你想要使用的端口，如下所示，你将使用443端口

```
docker pull wulabing/xray_docker_reality:latest
EXTERNAL_PORT=443
docker run -d --name xray_reality --restart=always --log-opt max-size=100m --log-opt max-file=3 -p $EXTERNAL_PORT:443 -e EXTERNAL_PORT=$EXTERNAL_PORT wulabing/xray_docker_reality:latest
```

### host 模式
如果你想使用 host 模式，你可以使用以下命令，运行后会自动下载镜像并启动容器，
HOSTMODE_PORT 为你想要使用的端口，如下所示，你将使用443端口
>请注意，如果你使用 host 模式，EXTERNAL_PORT 变量将不会生效，请使用 HOSTMODE_PORT 变量

```
docker pull wulabing/xray_docker_reality:latest
HOSTMODE_PORT=443
docker run -d --name xray_reality --restart=always --log-opt max-size=100m --log-opt max-file=3 --network host -e HOSTMODE_PORT=$HOSTMODE_PORT wulabing/xray_docker_reality:latest
```


查看日志获取配置信息，如下所示，按照提示配置客户端即可，

```
docker logs -f xray_reality 
```

## 进阶使用方法
如果你不想使用 443 端口，你可以自定义端口，例如使用 8443 端口，如下所示

```
EXTERNAL_PORT=8443
docker run -d --name xray_reality --restart=always --log-opt max-size=100m --log-opt max-file=3 -p $EXTERNAL_PORT:443 -e EXTERNAL_PORT=$EXTERNAL_PORT wulabing/xray_docker_reality:latest
```

如果你想启动多个 reality 服务，你可以使用不同的容器名，并注意端口不要冲突，如下所示你将启动两个 reality 服务，分别使用444和445端口

```
EXTERNAL_PORT=444
docker run -d --name xray_reality_1 --restart=always --log-opt max-size=100m --log-opt max-file=3 -p $EXTERNAL_PORT:443 -e EXTERNAL_PORT=$EXTERNAL_PORT wulabing/xray_docker_reality:latest

EXTERNAL_PORT=445
docker run -d --name xray_reality_2 --restart=always --log-opt max-size=100m --log-opt max-file=3 -p $EXTERNAL_PORT:443 -e EXTERNAL_PORT=$EXTERNAL_PORT wulabing/xray_docker_reality:latest
```

如果你不想使用默认参数，你可以自定义参数，例如使用自定义的 UUID,以及自定义目标地址和服务器名称，如下所示，**支持的自定义参数请参考下方环境变量说明**

存在多个 SERVERNAMES 时使用空格分开，例如：www.apple.com images.apple.com

请注意，如果你使用自定义参数，你需要自己保证参数的正确性，否则可能会导致容器无法启动
```
EXTERNAL_PORT=443
docker run -d --name xray_reality --restart=always --log-opt max-size=100m --log-opt max-file=3 -p $EXTERNAL_PORT:443 -e EXTERNAL_PORT=$EXTERNAL_PORT -e UUID="XXX" -e SERVERNAMES="www.apple.com images.apple.com" -e DEST="www.apple.com:443" -e PRIVATEKEY="XXX" wulabing/xray_docker_reality:latest
```

使用以下命令删除已经创建的容器，如下所示，需要将 xray_reality 替换为你自己的容器名 (--name 所设置的名称)

```
docker rm -f xray_reality
```


## 环境变量
你可以设置以下环境变量来自定义 XRay 的配置。
* UUID：XRay 的唯一用户标识符。若未设置，脚本将自动生成一个随机 UUID。
* DEST：目标地址。默认值为 www.apple.com:443。
* SERVERNAMES：服务器名称列表。默认值为 www.apple.com images.apple.com。
* PRIVATEKEY：私钥。若未设置，脚本将自动生成一个新的私钥和对应的公钥。
* NETWORK：网络类型。默认值为 tcp。

## 常量
* flow：xtls-rprx-vision
* security：reality
* shortIds：留空

## 注意事项
请确保在使用前已正确安装和配置 XRay 客户端。
为了保证安全和稳定，请勿将 UUID、私钥等敏感信息泄露给他人。

## 捐赠

您可以使用我的 搬瓦工 AFF 购买 VPS

https://bandwagonhost.com/aff.php?aff=63939

您可以使用我的 JustMySocks AFF 购买搬瓦工提供的代理

https://justmysocks.net/members/aff.php?aff=17621

您可以使用我的 DMIT AFF 购买 VPS

https://www.dmit.io/aff.php?aff=3957

您可以使用我的 Vultr AFF 创建新的 Vultr 账号并使用

https://www.vultr.com/?ref=6881279

您可以通过 USDT 支持我，感谢您的支持
TRC20:TFannfnajNGYsMTuVDcXfZXXPbcaxAEffa
