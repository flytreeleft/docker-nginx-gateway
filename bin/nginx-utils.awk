BEGIN {
    cmd = "cat '" source_file "'"

    content_lines_index = 0
    current_block_index = 0
    while ( ( cmd | getline ) > 0 ) {
        line = $0

        content_lines_index += 1
        content_lines[content_lines_index] = line

        if ( match(line, /^[^#]+\{/) ) {
            current_block_index += 1
        }
        else if ( match(line, /^[[:space:]]*\}/) ) {
            current_block_index += 1
        }
        else if ( match(line, /^[[:space:]]*listen[[:space:]]+.+;/) ) {
            listen_directive_block_indexes[content_lines_index] = current_block_index
        }
        else if ( match(line, /^[[:space:]]*include[[:space:]]+.+;/) ) {
            include_file = line
            gsub(/^[[:space:]]*include[[:space:]]+|[[:space:]]*;.*$/, " ", include_file)

            file = include_files_in_block[current_block_index]
            if ( file ) {
                include_files_in_block[current_block_index] = file " " include_file
            } else {
                include_files_in_block[current_block_index] = include_file
            }
        }
    }
    close(cmd)

    for ( i = 1; i <= content_lines_index; i++ ) {
        line = content_lines[i]
        listen_directive_block_index = listen_directive_block_indexes[i]

        if ( ! ( listen_directive_block_index > 0 ) ) {
            print line
            continue
        }

        listen_directive = line
        if ( ! match(listen_directive, /[[:space:]]+ssl.*;|;[[:space:]]+#[[:space:]]+ssl enabled/) ) {
            print listen_directive
            continue
        }

        include_files = include_files_in_block[listen_directive_block_index]

        is_ssl_exists = ssl_listen_enable_blocks[listen_directive_block_index] == "true"
        if ( ! is_ssl_exists && include_files ) {
            # The function 'is_server_ssl_existing_in' is defined in /usr/bin/nginx-utils.sh
            ## https://unix.stackexchange.com/questions/72935/using-bash-shell-function-inside-awk#answer-417232
            cmd = "bash -c 'is_server_ssl_existing_in " include_files "'"
            cmd | getline ssl_exists_checking
            close(cmd)

            if ( ssl_exists_checking == "true" ) {
                is_ssl_exists = 1 == 1
            }
        }

        if ( is_ssl_exists ) {
            ssl_listen_enable_blocks[listen_directive_block_index] = "true"

            if ( ! match(listen_directive, /[[:space:]]+ssl.*;/) ) {
                gsub(/[[:space:]]*;/, " ssl;", listen_directive)
            }
        } else {
            if ( match(listen_directive, /[[:space:]]+ssl.*;/) ) {
                gsub(/[[:space:]]+ssl/, "", listen_directive)
            }
        }
        gsub(/;.*/, "; # ssl enabled", listen_directive)

        print listen_directive
    }
}
