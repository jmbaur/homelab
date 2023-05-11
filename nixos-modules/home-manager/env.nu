let-env PROMPT_COMMAND_RIGHT = { || "" }

let-env config = {
  edit_mode: emacs
  show_banner: false
  table: {
    mode: rounded
  }
  cursor_shape: {
    vi_insert: underscore
    vi_normal: block
    emacs: block
  }
}
