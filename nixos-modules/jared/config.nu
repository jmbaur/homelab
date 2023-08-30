$env.config = {
    shell_integration: true
    show_banner: false
    cursor_shape: {
        emacs: block # block, underscore, line, blink_block, blink_underscore, blink_line (line is the default)
        vi_insert: block # block, underscore, line , blink_block, blink_underscore, blink_line (block is the default)
        vi_normal: underscore # block, underscore, line, blink_block, blink_underscore, blink_line (underscore is the default)
    }
    hooks: {
        pre_prompt: [{ ||
            let direnv = (direnv export json | from json)
            let direnv = if ($direnv | length) == 1 { $direnv } else { {} }
            $direnv | load-env
        }]
  }
}
