let carapace_completer = {|spans|
    carapace $spans.0 nushell ...$spans | from json
}

$env.config.show_banner = false
$env.config.history = {
    file_format: sqlite
    max_size: 1_000_000
    sync_on_enter: true
    isolation: true
}
$env.config.completions = {
    external: {
        enable: true
        completer: $carapace_completer
    }
}
