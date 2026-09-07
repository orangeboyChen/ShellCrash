. "$CRASHDIR"/libs/web_get.sh

get_bin() { #下载项目文件；脚本包来自 Release，其余资源按原分支按需下载
    case "$2" in
        ShellCrash.tar.gz|version)
            if echo "$release_type" | grep -qE '^[vV]?[0-9]'; then
                release_tag=$(echo "$release_type" | sed 's/^[vV]//')
                bin_url="https://github.com/orangeboyChen/ShellCrash/releases/download/v${release_tag}/$2"
            else
                bin_url="https://github.com/orangeboyChen/ShellCrash/releases/latest/download/$2"
            fi
            ;;
        bin/*)
            bin_url="https://github.com/orangeboyChen/ShellCrash/raw/bin/${2#bin/}"
            ;;
        public/*|rules/*|tools/*)
            bin_url="https://github.com/orangeboyChen/ShellCrash/raw/dev/$2"
            ;;
        *)
            return 1
            ;;
    esac

    for proxy in \
        https://gh-proxy.org/ \
        https://v4.gh-proxy.org/ \
        https://v6.gh-proxy.org/ \
        https://cdn.gh-proxy.org/ \
        https://axisnow.gh-proxy.org/; do
        retry=1
        while [ "$retry" -le 3 ]; do
            webget "$1" "${proxy}${bin_url}" "$3" "$4" "$5" "$6" single && return 0
            rm -f "$1"
            retry=$((retry + 1))
        done
    done
    return 1
}
