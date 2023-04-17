## xray_docker_reality
xray reality  docker 镜像

[![xray_docker_reality_docker_image_build](https://github.com/wulabing/xray_docker/actions/workflows/xray_docker_reality.yml/badge.svg)](https://github.com/wulabing/xray_docker/actions/workflows/xray_docker_reality.yml)

## 基础使用方法
如果你没有安装 docker 请先安装docker

```
curl -fsSL get.docker.com -o get-docker.sh && sh get-docker.sh
```

如果你已经安装docker，可以直接使用下面的命令，运行后会自动下载镜像并启动容器，
EXTERNAL_PORT 为你想要使用的端口，如下所示，你将使用443端口

```
EXTERNAL_PORT=443
docker run -d --name xray_reality --restart=always -p $EXTERNAL_PORT:443 -e EXTERNAL_PORT=$EXTERNAL_PORT wulabing/xray_docker_reality:latest
```

查看日志获取配置信息，如下所示，按照提示配置客户端即可，

```
docker logs -f xray_reality 
```

## 进阶使用方法

如果你不想使用443端口，你可以自定义端口，例如使用8443端口，如下所示

```
EXTERNAL_PORT=8443
docker run -d --name xray_reality --restart=always -p $EXTERNAL_PORT:443 -e EXTERNAL_PORT=$EXTERNAL_PORT wulabing/xray_docker_reality:latest
```

如果你想启动多个reality服务，你可以使用不同的容器名，并注意端口不要冲突，如下所示你将启动两个reality服务，分别使用444和445端口

```
EXTERNAL_PORT=444
docker run -d --name xray_reality_1 --restart=always -p $EXTERNAL_PORT:443 -e EXTERNAL_PORT=$EXTERNAL_PORT wulabing/xray_docker_reality:latest
EXTERNAL_PORT=445
docker run -d --name xray_reality_2 --restart=always -p $EXTERNAL_PORT:443 -e EXTERNAL_PORT=$EXTERNAL_PORT wulabing/xray_docker_reality:latest
```

如果你不想使用默认参数，你可以自定义参数，例如使用自定义的UUID,以及自定义目标地址和服务器名称，如下所示，**支持的自定义参数请参考下方环境变量说明**

存在多个SERVERNAMES时使用空格分开，例如：www.apple.com images.apple.com

请注意，如果你使用自定义参数，你需要自己保证参数的正确性，否则可能会导致容器无法启动
```
EXTERNAL_PORT=443
docker run -d --name xray_reality --restart=always -p $EXTERNAL_PORT:443 -e EXTERNAL_PORT=$EXTERNAL_PORT -e UUID="XXX" -e SERVERNAMES="www.apple.com images.apple.com" -e DEST="www.apple.com:443" -e PRIVATEKEY="XXX" wulabing/xray_docker_reality:latest
```

使用以下命令删除已经创建的容器，如下所示，需要将xray_reality替换为你自己的容器名 (--name 所设置的名称)

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