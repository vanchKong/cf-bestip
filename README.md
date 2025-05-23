> 作者：端端/Gotchaaa，转载请标明作者，感谢！
> 
> 项目地址 [cf-bestip](https://github.com/vanchkong/cf-bestip)
> 
> 感谢脚本真正核心的开源项目：[CloudflareSpeedTest](https://github.com/XIU2/CloudflareSpeedTest)

```
services:
  cf-bestip:
    image: vanch/cf-bestip:latest
    container_name: cf-bestip
    restart: always
    network_mode: host
    environment:
      - PUID=0
      - PGID=0
    volumes:
      - /etc/hosts:/etc/hosts
```

```
docker run -itd --name cf-bestip -v /etc/hosts:/etc/hosts --network=host vanch/cf-bestip:latest
```