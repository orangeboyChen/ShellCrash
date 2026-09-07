<h1 align="center">ShellCrash</h1>

<p align="center">
  <a target="_blank" href="https://github.com/MetaCubeX/mihomo/releases">
    <img src="https://img.shields.io/github/release/MetaCubeX/mihomo.svg?style=flat-square&label=Core">
  </a>
  <a target="_blank" href="https://github.com/juewuy/ShellCrash/releases">
    <img src="https://img.shields.io/github/release/juewuy/ShellCrash.svg?style=flat-square&label=ShellCrash&colorB=green">
  </a>
</p>

<p align="center">
  <strong>一款在 Shell 环境下便捷部署与管理 mihomo/sing-box 内核的脚本工具</strong>
</p>

<p align="center">
  简体中文 | <a href="README.md">English</a>
</p>

---

## :rocket: 核心特性

- **多内核支持**：在 Shell 环境下便捷管理及切换 **mihomo** 与 **sing-box** 内核。
- **灵活配置管理**：支持在线导入订阅连结及配置文件，简化配置流程。
- **自动化任务**：支持配置定时任务，实现配置文件与规则的自动定时更新。
- **图形化面板**：支持在线安装并使用本地 Web 面板（Dashboard），直观管理内置规则与流量。
- **多模式运行**：支持路由模式、本机模式等多种流量转发模式切换。
- **一键维护**：内置脚本在线更新功能，保持版本与功能的及时更迭。

## :computer: 设备支持

ShellCrash 旨在兼容绝大多数基于 Linux 内核的网络设备：

* **路由器设备**：支持各种基于 OpenWrt 或其二次开发固件（如 小米路由、网件路由等设备）。
* **Linux 服务器**：支持运行标准 Linux/GNU发行版（如 Debian、CentOS、Armbian、Ubuntu 等）的设备。
* **第三方固件**：兼容 Padavan（保守模式）、潘多拉固件以及华硕/梅林固件。
* **其他设备**：兼容各种基于Linux/GNU或者Linux/busybox开发的设备。
* **Docker**：部分可能不兼容的设备（如群辉、PVE），支持docker环境运行。

> 更多设备支持，请提交 [Issue](https://github.com/juewuy/ShellCrash/issues) 或前往 [Telegram 群组](https://t.me/ShellClash) 反馈（请附上设备型号及 `uname -a` 命令的输出信息）。

---

## :hammer_and_wrench: 安装指南

> [!TIP]
> 安装和更新均从本仓库 GitHub Release 获取，并依次尝试五个代理；每个代理失败三次后自动切换。

### 前置条件
1. 确保设备已开启 **SSH** 并获得 **Root 权限**（带图形介面的 Linux 系统可直接使用终端）。
2. 使用 SSH 工具（如 Putty、JuiceSSH、或系统自带终端）连接至设备。

### :penguin: 统一 Release 安装

> [!IMPORTANT]
> 请以 root 用户进行安装。此命令适用于标准 Linux、路由器和旧版 `wget` 设备。

```sh
asset_url='https://github.com/orangeboyChen/ShellCrash/releases/latest/download/install.sh'
download() {
  if command -v wget >/dev/null 2>&1; then
    wget -q --no-check-certificate -O /tmp/install.sh "$1"
  elif command -v curl >/dev/null 2>&1; then
    curl -kfsSL "$1" -o /tmp/install.sh
  else
    return 1
  fi
}
for proxy in https://gh-proxy.org/ https://v4.gh-proxy.org/ https://v6.gh-proxy.org/ https://cdn.gh-proxy.org/ https://axisnow.gh-proxy.org/; do
  for retry in 1 2 3; do
    download "${proxy}${asset_url}" && break 2
    rm -f /tmp/install.sh
  done
done
[ -s /tmp/install.sh ] && sh /tmp/install.sh && . /etc/profile
```


### :cloud: 虚拟机
- **Alpine Linux 虚拟机**：强烈建议使用 Alpine 镜像以获得最佳兼容性
```sh
# 安装必要依赖
apk add --no-cache wget openrc ca-certificates tzdata nftables iproute2 dcron

# 使用上方“统一 Release 安装”命令
```

 ### :whale: Docker 

 请访问官方 Docker 镜像：

- [ShellCrash on Docker Hub](https://hub.docker.com/r/juewuy/shellcrash)


### :package: 本地安装

若无法进行在线安装，请参照以下指南执行本地安装：

- [本地安装ShellCrash教程 | Juewuy's Blog](https://juewuy.github.io/bdaz)

---

## :book: 使用说明

安装完成后，在终端输入以下指令即可启动管理界面：

```shell
crash        # 启动脚本交互选单
crash -h     # 查看命令帮助列表
```

### 运行依赖说明
| 依赖组件 | 必要性 | 说明 |
| :--- | :--- | :--- |
| curl / wget | 必须 | 缺少时将无法进行节点保存、在线安装及更新操作 |
| iptables / nftables | 重要 | 缺少时仅能运行于纯淨模式 |
| crontab | 较低 | 缺少时定时任务功能将失效 |
| net-tools | 极低 | 缺少时无法自动检测端口占用 |
| ubus / iproute-doc | 极低 | 缺少时无法自动获取本机 Host 地址 |

---

## :link: 相关链接
- 常见问题：[Juewuy's Blog](https://juewuy.github.io/chang-jian-wen-ti/)
- 更新日志：[Release History](https://github.com/juewuy/ShellCrash/releases)
- 交流反馈：[Telegram 讨论组](https://t.me/ShellClash)

---

## :scroll: 许可协议

本项目采用[GNU通用公共许可证第3.0版](LICENSE.txt)授权。

---

## :airplane: 机场推荐

- [**大米**](https://1s.bigmeok.me/user#/register?code=2PuWY9I7)，群友力荐，流媒体解锁，月付推荐。
