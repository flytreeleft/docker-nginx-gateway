get_include_files_from() {
    local source="$1"

    for file in $(sed -E '/^\s*include /!d; s/^\s*include\s+([^ ;]+)\s*;/\1/g;' "$source"); do
        ls -1 $file 2>/dev/null
    done | sort | uniq
}

get_include_files_deeply_from() {
    local source="$1"

    for file in $(get_include_files_from "$source"); do
        echo "$file"

        get_include_files_deeply_from "$file"
    done | sort | uniq
}

get_server_names_from() {
    local source="$1"

    if [[ -d "$source" ]]; then
        source_content="$(cat "$source"/*.conf)"
    else
        source_content="$(cat "$source")"
    fi
    # https://stackoverflow.com/questions/32400933/how-can-i-list-all-vhosts-in-nginx#answer-46230868
    echo "$source_content" \
        | sed -r -e 's/[ \t]*$//' -e 's/^[ \t]*//' -e 's/^#.*$//' -e 's/[ \t]*#.*$//' -e '/^$/d' \
        | sed -e ':a;N;$!ba;s/\([^;\{\}]\)\n/\1 /g' \
        | grep -E 'server_name[ \t]' | grep -v '\$' | grep '\.' \
        | sed -r -e 's/(\S)[ \t]+(\S)/\1\n\2/g' -e 's/[\t ]//g' -e 's/;//' -e 's/server_name//' \
        | sed -e '/^$/d' -e 's/^\*\.//g' | sort | uniq
}

is_server_ssl_existing_in() {
    local ssl_files=( $(
        grep -Eh '^\s*(ssl_certificate|ssl_certificate_key|ssl_trusted_certificate)\s+/' "$@" \
            | sed -E 's/^\s*(ssl_certificate|ssl_certificate_key|ssl_trusted_certificate)\s+([^ ;]+).*;/\2/g;' \
            | sort | uniq
    ) )

    if [[ "${#ssl_files[@]}" = "0" ]]; then
        return
    fi

    for file in "${ssl_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            return
        fi
    done
    echo "true"
}

check_log_files_for() {
    local source="$1"

    echo "Check log files for '$source'"
    local files=( "$source" )
    files+=( $(get_include_files_deeply_from "$source") )

    for log in $(grep -Eh '^\s*(error_log|access_log)\s+/' "${files[@]}" \
                    | sed -E 's/^\s*(error_log|access_log)\s+([^ ;]+).*;/\2/g;' \
                    | sort | uniq); do
        if [[ -f "$log" ]]; then
            echo "  - '$log' exists."
            continue
        fi

        local log_dir="$(dirname "$log")"
        if [[ "x$(echo "$log_dir" | grep '\$')" != "x" ]]; then
            echo "  - '$log_dir' is ignored."
            continue
        fi

        mkdir -p "$log_dir"

        if [[ "x$(echo "$log" | grep '\$')" != "x" ]]; then
            echo "  - '$log' is ignored."
            continue
        fi
        echo "  - '$log' is creating..."
        touch "$log" && chown nginx "$log" && chmod go-rwx "$log"
    done
}

update_server_ssl_for() {
    local source="$1"

    # export bash function to awk scripts
    export -f is_server_ssl_existing_in

    echo "Check ssl configuration for '$source'"
    local files=( "$source" )
    files+=( $(get_include_files_deeply_from "$source") )

    for conf in $(grep -El '^\s*server\s+\{' "${files[@]}" | sort | uniq); do
        local updated_conf_content="$(awk -v source_file="$conf" -f /usr/bin/nginx-utils.awk)"

        if [[ "$(cat "$conf")" != "$updated_conf_content" ]]; then
            echo "  - '$conf' is updating ..."
            echo "$updated_conf_content" > "$conf"
        else
            echo "  - '$conf' is ignored."
        fi
    done
}

update_host_config_for() {
    local source="$1"

    check_log_files_for "$source"
    update_server_ssl_for "$source"
}

# update_host_config_for /etc/nginx/nginx.conf
# update_server_ssl_for /etc/nginx/nginx.conf
