. "$CRASHDIR"/libs/web_get.sh

release_asset_name() {
    case "$1" in
        ShellCrash.tar.gz|version) printf '%s' "$1" ;;
        *) printf 'sc-%s' "$(printf '%s' "$1" | tr '/' '-')" ;;
    esac
}

get_bin() { #下载 GitHub Release 资产
    asset_name=$(release_asset_name "$2")
    if echo "$release_type" | grep -qE '^[vV]?[0-9]'; then
        release_tag=$(echo "$release_type" | sed 's/^[vV]//')
        bin_url="https://github.com/orangeboyChen/ShellCrash/releases/download/v${release_tag}/${asset_name}"
    else
        bin_url="https://github.com/orangeboyChen/ShellCrash/releases/latest/download/${asset_name}"
    fi

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
