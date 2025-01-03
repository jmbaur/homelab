local notify = require("mini.notify")
notify.setup({ lsp_progress = { enable = false } })
vim.notify = notify.make_notify()
