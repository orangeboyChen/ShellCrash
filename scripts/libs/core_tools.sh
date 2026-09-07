

[ -n "$(find --help 2>&1 | grep -o size)" ] && find_para=' -size +2000'             #find命令兼容

#根据环境权衡决定是否把裸二进制存于$BINDIR(rom)——省RAM，前提是rom装得下
#$1=裸二进制字节数。仅当$TMPDIR在内存(tmpfs)时裸存才省RAM；
#再按$BINDIR文件系统估算裸二进制落盘体积(透明压缩fs约2:1)，需留有余量($raw_margin,默认8M)
store_raw_worth_it(){
    case "$(df -T "$TMPDIR" 2>/dev/null | awk 'END{print $2}')" in tmpfs|ramfs) ;; *) return 1 ;; esac
    rom_free=$(df -k "$BINDIR" 2>/dev/null | awk 'END{print $4}')          #KB
    [ -z "$rom_free" ] && return 1
    case "$(df -T "$BINDIR" 2>/dev/null | awk 'END{print $2}')" in
        squashfs|ubifs|overlay|overlayfs) est=$(( ${1:-0}/1024/2 )) ;;    #透明压缩，约2:1
        *) est=$(( ${1:-0}/1024 )) ;;                                     #无压缩，全量
    esac
    [ $(( rom_free - est )) -gt "${raw_margin:-8192}" ] && return 0 || return 1
}

core_unzip() { #$1:需要解压的文件 $2:目标文件名
    if echo "$1" |grep -q 'tar.gz$' ;then
        [ "$BINDIR" = "$TMPDIR" ] && rm -rf "$TMPDIR"/CrashCore #小闪存模式防止空间不足
        [ -n "$(tar --help 2>&1 | grep -o 'no-same-owner')" ] && tar_para='--no-same-owner' #tar命令兼容
        mkdir -p "$TMPDIR"/core_tmp
        tar -zxf "$1" ${tar_para} -C "$TMPDIR"/core_tmp/
        for file in $(find "$TMPDIR"/core_tmp $find_para 2>/dev/null); do
            [ -f "$file" ] && [ -n "$(echo $file | sed 's#.*/##' | grep -iE '(CrashCore|sing|meta|mihomo|clash|pre)')" ] && mv -f "$file" "$TMPDIR"/"$2"
        done
        rm -rf "$TMPDIR"/core_tmp
    elif echo "$1" |grep -q '.gz$' ;then
        gunzip -c "$1" > "$TMPDIR"/"$2"
    elif echo "$1" |grep -q '.raw$' ;then
        ln -sf "$1" "$TMPDIR"/"$2"
    elif echo "$1" |grep -q '.upx$' ;then
        ln -sf "$1" "$TMPDIR"/"$2"
    else
        mv -f "$1" "$TMPDIR"/"$2"
    fi
    chmod +x "$TMPDIR"/"$2"
}
core_find(){
    if [ ! -f "$TMPDIR"/CrashCore ];then
        [ -n "$(find "$CRASHDIR"/CrashCore.* $find_para 2>/dev/null)" ] && [ "$CRASHDIR" != "$BINDIR" ] &&
            mv -f "$CRASHDIR"/CrashCore.* "$BINDIR"/
        core_dir=$(find "$BINDIR"/CrashCore.* $find_para 2>/dev/null | head -n 1)
        [ -n "$core_dir" ] && core_unzip "$core_dir" CrashCore
    fi
}
core_check(){
    [ "$core_upgrade_channel" = '' ] && [ -n "$(pidof CrashCore)" ] && "$CRASHDIR"/start.sh stop #停止内核服务防止内存不足
    core_unzip "$1" core_new
    sbcheck=$(echo "$crashcore" | grep 'singbox')
    v=''
    if [ -n "$sbcheck" ] && "$TMPDIR"/core_new -h 2>&1 | grep -q 'sing-box'; then
        v=$("$TMPDIR"/core_new version 2>/dev/null | grep version | awk '{print $3}')
        COMMAND='"$TMPDIR/CrashCore run -D $BINDIR -C $TMPDIR/jsons"'
    elif [ -z "$sbcheck" ] && "$TMPDIR"/core_new -h 2>&1 | grep -q '\-t';then
        v=$("$TMPDIR"/core_new -v 2>/dev/null | head -n 1 | sed 's/ linux.*//;s/.* //')
        COMMAND='"$TMPDIR/CrashCore -d $BINDIR -f $TMPDIR/config.yaml"'
    fi
    if [ -z "$v" ]; then
        rm -rf "$1" "$TMPDIR"/core_new
        return 2
    else
        rm -f "$BINDIR"/CrashCore.tar.gz "$BINDIR"/CrashCore.gz "$BINDIR"/CrashCore.upx "$BINDIR"/CrashCore.raw
        if [ "$zip_type" = 'upx' ];then
            mv -f "$1" "$BINDIR/CrashCore.upx"
            rm -f "$TMPDIR"/core_new
            ln -sf "$BINDIR/CrashCore.upx" "$TMPDIR/CrashCore"
        elif store_raw_worth_it "$(wc -c < "$TMPDIR/core_new")" ;then
            rm -f "$1"
            mv -f "$TMPDIR/core_new" "$BINDIR/CrashCore.raw"
            ln -sf "$BINDIR/CrashCore.raw" "$TMPDIR/CrashCore"
        elif [ -z "$zip_type" ];then
            gzip -c "$TMPDIR/core_new" > "$BINDIR/CrashCore.gz"
            mv -f "$TMPDIR/core_new" "$TMPDIR/CrashCore"
        else
            mv -f "$1" "$BINDIR/CrashCore.$zip_type"
            mv -f "$TMPDIR/core_new" "$TMPDIR/CrashCore"
        fi
        core_v="$v"
        setconfig COMMAND "$COMMAND" "$CRASHDIR"/configs/command.env && . "$CRASHDIR"/configs/command.env
        setconfig crashcore "$crashcore"
        setconfig core_v "$core_v"
        setconfig custcorelink "$custcorelink"
        return 0
    fi
}
core_resolve_link(){
    case "$crashcore" in
        singboxr)
            project='orangeboyChen/sing-box-reF1nd'
            ;;
        singbox)
            project='SagerNet/sing-box'
            ;;
        meta|clashpre)
            if [ "$core_upgrade_channel" = alpha ] || [ "$crashcore" = clashpre -a "$core_upgrade_channel" = auto ]; then
                project='vernesong/mihomo'
            else
                project='MetaCubeX/mihomo'
            fi
            ;;
        *)
            return 1
            ;;
    esac
    case "$core_upgrade_channel" in
        release)
            if [ "$crashcore" = singboxr ]; then
                api_url="https://api.github.com/repos/${project}/releases?per_page=20"
                release_filter='stable'
            else
                api_url="https://api.github.com/repos/${project}/releases/latest"
                release_filter=''
            fi
            ;;
        auto)
            if [ "$crashcore" = singboxr ]; then
                api_url="https://api.github.com/repos/${project}/releases?per_page=1"
                release_filter='first'
            else
                api_url="https://api.github.com/repos/${project}/releases/latest"
                release_filter=''
            fi
            ;;
        alpha)
            api_url="https://api.github.com/repos/${project}/releases?per_page=1"
            release_filter='prerelease'
            ;;
        *)
            return 1
            ;;
    esac
    webget "$TMPDIR/github_core_api" "$api_url" echooff || return 1
    if [ "$release_filter" = prerelease ]; then
        grep -qE '"prerelease"[[:space:]]*:[[:space:]]*true' "$TMPDIR/github_core_api" || {
            rm -f "$TMPDIR/github_core_api"
            return 1
        }
        core_release=$(cat "$TMPDIR/github_core_api")
    elif [ "$release_filter" = stable ]; then
        grep -qE '"prerelease"[[:space:]]*:[[:space:]]*false' "$TMPDIR/github_core_api" || {
            rm -f "$TMPDIR/github_core_api"
            return 1
        }
        core_release=$(cat "$TMPDIR/github_core_api")
    elif [ "$release_filter" = first ]; then
        core_release=$(cat "$TMPDIR/github_core_api")
    else
        core_release=$(cat "$TMPDIR/github_core_api")
    fi
    core_link=$(printf '%s\n' "$core_release" | grep -oE 'https://[^" ]+linux-[^" ]+\.(tar\.gz|gz|upx)' |
        grep "linux-${cpucore}" | head -n 1)
    rm -f "$TMPDIR/github_core_api"
    unset core_release release_filter
    [ -n "$core_link" ] || return 1
    custcorelink="$core_link"
    case "$core_link" in
        *.tar.gz) zip_type='tar.gz' ;;
        *.upx) zip_type='upx' ;;
        *) zip_type='gz' ;;
    esac
    return 0
}
core_webget(){
    . "$CRASHDIR"/libs/web_get_bin.sh
    . "$CRASHDIR"/libs/check_target.sh
    if [ -n "$core_upgrade_channel" ]; then
        [ -n "$cpucore" ] || {
            . "$CRASHDIR"/libs/check_cpucore.sh
            check_cpucore
        }
        core_saved_custcorelink="$custcorelink"
        core_dynamic_link=1
        core_resolve_link || return 1
    fi
    if [ -z "$custcorelink" ];then
        [ -z "$zip_type" ] && zip_type='tar.gz'
        #若环境适合裸存(见store_raw_worth_it，按典型核心~45M估算)，避免下载upx，改取tar.gz的裸二进制
        [ "$zip_type" = 'upx' ] && store_raw_worth_it 47185920 && zip_type='tar.gz'
        get_bin "$TMPDIR/Coretmp.$zip_type" "bin/$crashcore/${target}-linux-${cpucore}.$zip_type"
    else
        case "$custcorelink" in
            *.tar.gz) zip_type="tar.gz" ;;
            *.gz)     zip_type="gz" ;;
            *.upx)    zip_type="upx" ;;
        esac
        [ -n "$zip_type" ] && webget "$TMPDIR/Coretmp.$zip_type" "$custcorelink"
    fi
    #校验内核
    if [ "$?" = 0 ];then
        if [ "$core_dynamic_link" = 1 ]; then
            custcorelink="$core_saved_custcorelink"
            core_check "$TMPDIR/Coretmp.$zip_type"
            core_result=$?
            custcorelink="$core_saved_custcorelink"
            unset core_saved_custcorelink core_dynamic_link
            return "$core_result"
        else
            core_check "$TMPDIR/Coretmp.$zip_type"
        fi
    else
        rm -f "$TMPDIR/Coretmp.$zip_type"
        return 1
    fi
}
