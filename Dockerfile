############################
# Stage 1: builder
############################
FROM alpine:latest AS builder

ARG TARGETPLATFORM
ARG TZ=Asia/Shanghai
ARG S6_OVERLAY_V=v3.2.1.0
ARG SHELLCRASH_VERSION=latest

RUN apk add --no-cache curl tzdata

# 时区
RUN ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime && \
    echo "${TZ}" > /etc/timezone

WORKDIR /build

#从 GitHub Release 下载脚本相关文件
RUN set -eux; \
    if [ "$SHELLCRASH_VERSION" = latest ]; then \
      release_url="https://github.com/orangeboyChen/ShellCrash/releases/latest/download/ShellCrash.tar.gz"; \
    else \
      release_url="https://github.com/orangeboyChen/ShellCrash/releases/download/v${SHELLCRASH_VERSION#v}/ShellCrash.tar.gz"; \
    fi; \
    downloaded=false; \
    for proxy in https://gh-proxy.org/ https://v4.gh-proxy.org/ https://v6.gh-proxy.org/ https://cdn.gh-proxy.org/ https://axisnow.gh-proxy.org/; do \
      retry=1; \
      while [ "$retry" -le 3 ]; do \
        rm -f /tmp/ShellCrash.tar.gz; \
        if curl --connect-timeout 10 -fsSL "${proxy}${release_url}" -o /tmp/ShellCrash.tar.gz; then downloaded=true; break 2; fi; \
        retry=$((retry + 1)); \
      done; \
    done; \
    "$downloaded" && test -s /tmp/ShellCrash.tar.gz; \
    mkdir -p /tmp/SC_tmp; \
    tar -zxf /tmp/ShellCrash.tar.gz -C /tmp/SC_tmp; \
    export systype=container; \
    export CRASHDIR=/etc/ShellCrash; \
    /bin/sh /tmp/SC_tmp/init.sh
	
#获取 update 分支内核及 s6 文件
RUN set -eux; \
	case "$TARGETPLATFORM" in \
      linux/amd64)  K=amd64 S=x86_64;; \
      linux/arm64)  K=arm64 S=aarch64;; \
      linux/arm/v7) K=armv7 S=arm;; \
      linux/386)    K=386 S=i486;; \
      *) echo "unsupported $TARGETPLATFORM" && exit 1 ;; \
    esac; \
    source_base="https://github.com/orangeboyChen/ShellCrash/raw/update"; \
    download_asset() { \
      asset_name="$1"; \
      target_path="$2"; \
      downloaded=false; \
      for proxy in https://gh-proxy.org/ https://v4.gh-proxy.org/ https://v6.gh-proxy.org/ https://cdn.gh-proxy.org/ https://axisnow.gh-proxy.org/; do \
        retry=1; \
        while [ "$retry" -le 3 ]; do \
          rm -f "$target_path"; \
          if curl --connect-timeout 10 -fsSL "${proxy}${source_base}/${asset_name}" -o "$target_path"; then downloaded=true; break 2; fi; \
          retry=$((retry + 1)); \
        done; \
      done; \
      "$downloaded" && test -s "$target_path"; \
    }; \
    download_asset "sc-bin-meta-clash-linux-${K}.tar.gz" /tmp/CrashCore.tar.gz; \
    curl -fsSL "https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_V}/s6-overlay-${S}.tar.xz" -o /tmp/s6_arch.tar.xz; \
    curl -fsSL "https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_V}/s6-overlay-noarch.tar.xz" -o /tmp/s6_noarch.tar.xz && ls -l /tmp

#安装 update 分支面板文件
RUN set -eux; \
    mkdir -p /etc/ShellCrash/ruleset /etc/ShellCrash/ui; \
    source_base="https://github.com/orangeboyChen/ShellCrash/raw/update"; \
    download_asset() { \
      asset_name="$1"; \
      target_path="$2"; \
      downloaded=false; \
      for proxy in https://gh-proxy.org/ https://v4.gh-proxy.org/ https://v6.gh-proxy.org/ https://cdn.gh-proxy.org/ https://axisnow.gh-proxy.org/; do \
        retry=1; \
        while [ "$retry" -le 3 ]; do \
          rm -f "$target_path"; \
          if curl --connect-timeout 10 -fsSL "${proxy}${source_base}/${asset_name}" -o "$target_path"; then downloaded=true; break 2; fi; \
          retry=$((retry + 1)); \
        done; \
      done; \
      "$downloaded" && test -s "$target_path"; \
    }; \
    download_asset bin/geodata/mrs.tar.gz /tmp/mrs.tar.gz; \
    download_asset bin/dashboard/zashboard.tar.gz /tmp/zashboard.tar.gz; \
    tar -zxf /tmp/mrs.tar.gz -C /etc/ShellCrash/ruleset; \
    tar -zxf /tmp/zashboard.tar.gz -C /etc/ShellCrash/ui
	  
############################
# Stage 2: runtime
############################
FROM alpine:latest

ARG TZ=Asia/Shanghai

LABEL org.opencontainers.image.source="https://github.com/orangeboyChen/ShellCrash"
#安装依赖
RUN apk add --no-cache \
    wget \
    ca-certificates \
    tzdata \
    nftables \
    iproute2

RUN ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime && \
    echo "${TZ}" > /etc/timezone

#复制文件
COPY --from=builder /etc/ShellCrash /etc/ShellCrash
COPY --from=builder /tmp/CrashCore.tar.gz /etc/ShellCrash/CrashCore.tar.gz
COPY --from=builder /etc/profile /etc/profile
COPY --from=builder /usr/bin/crash /usr/bin/crash

#安装s6
COPY --from=builder /tmp/s6_arch.tar.xz /tmp/s6_arch.tar.xz
COPY --from=builder /tmp/s6_noarch.tar.xz /tmp/s6_noarch.tar.xz
RUN tar -xJf /tmp/s6_noarch.tar.xz -C / && rm -rf /tmp/s6_noarch.tar.xz
RUN tar -xJf /tmp/s6_arch.tar.xz -C / && rm -rf /tmp/s6_arch.tar.xz
COPY docker/s6-rc.d /etc/s6-overlay/s6-rc.d
COPY docker/s6-overlay/scripts/sync-autostart /etc/s6-overlay/scripts/sync-autostart
RUN chmod +x /etc/s6-overlay/scripts/sync-autostart
ENV S6_CMD_WAIT_FOR_SERVICES=1
ENV S6_STAGE2_HOOK=/etc/s6-overlay/scripts/sync-autostart

ENTRYPOINT ["/init"]
