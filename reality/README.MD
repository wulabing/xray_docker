## xray_docker_reality
xray reality  docker 镜像

## 使用方法
如果你没有安装 docker 请先安装docker

```
curl -fsSL get.docker.com -o get-docker.sh && sh get-docker.sh
```

如果你已经安装docker，可以直接使用下面的命令


```
ocker run -d --name xray_reality -p 443:443 wulabing/xray_docker_reality:0.0.1
```

查看日志获取配置信息

```
docker logs -f xray_reality
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