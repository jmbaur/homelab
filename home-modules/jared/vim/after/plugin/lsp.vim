vim9script

var lsp_servers: list<dict<any>> = []
var format_on_save_patterns: list<string> = []

if executable("nil")
    add(lsp_servers, {
        name: "nil",
        filetype: ["nix"],
        path: "nil",
        args: [],
        initializationOptions: {
            formatting: {command: ["nixfmt"]},
            nix: {flake: {autoArchive: false}},
        },
    })
    add(format_on_save_patterns, "*.nix")
endif

if executable("rust-analyzer")
    add(lsp_servers, {
        name: "rust-analyzer",
        filetype: ["rust"],
        path: "rust-analyzer",
        args: [],
        syncInit: true,
        initializationOptions: {
            diagnostics: {disabled: ["unresolved-proc-macro"]},
            check: {command: executable("cargo-clippy") == 1 ? "clippy" : "check"},
        },
    })
    add(format_on_save_patterns, "*.rs")
endif

if executable("bash-language-server")
    add(lsp_servers, {
        name: "bashls",
        filetype: ["sh"],
        path: "bash-language-server",
        args: ["start"],
    })
    add(format_on_save_patterns, "*.sh")
    add(format_on_save_patterns, "*.bash")
endif

if executable("gopls")
    add(lsp_servers, {
        name: "gopls",
        filetype: ["go", "mod"],
        path: "gopls",
        args: ["serve"],
        initializationOptions: {gofumpt: true, staticcheck: true},
    })
    add(format_on_save_patterns, "*.go")
endif

if executable("pyright-langserver")
    add(lsp_servers, {
        name: "pyright",
        filetype: ["python"],
        path: "pyright-langserver",
        args: ["--stdio"],
    })
endif

if executable("ttags")
    add(lsp_servers, {
        name: "ttags",
        filetype: ["javascript"],
        path: "ttags",
        args: []
    })
endif

if executable("zls")
    add(lsp_servers, {
        name: "zls",
        filetype: ["zig", "zon"],
        path: "zls",
        args: []
    })
    add(format_on_save_patterns, "*.zig")
    add(format_on_save_patterns, "*.zon")
endif

def LspAttach()
    # Prevent buffers from shifting left and right as diagnostics come and go.
    set signcolumn=yes

    nmap <buffer><silent> <C-W><C-]> <C-W>gd
    nmap <buffer><silent> <C-]> gd
    nnoremap <buffer><silent> <C-W>gd <cmd>botright LspGotoDefinition<enter>
    nnoremap <buffer><silent> <C-k> <cmd>LspShowSignature<enter>
    nnoremap <buffer><silent> <leader>a <cmd>LspCodeAction<enter>
    nnoremap <buffer><silent> <leader>rn <cmd>LspRename<enter>
    nnoremap <buffer><silent> K <cmd>LspHover<enter>
    nnoremap <buffer><silent> [d <cmd>LspDiagPrevWrap<enter>
    nnoremap <buffer><silent> ]d <cmd>LspDiagNextWrap<enter>
    nnoremap <buffer><silent> gD <cmd>LspGotoDeclaration<enter>
    nnoremap <buffer><silent> gd <cmd>LspGotoDefinition<enter>
    nnoremap <buffer><silent> gr <cmd>LspShowReferences<enter>
    nnoremap <buffer><silent> gt <cmd>LspGotoTypeDef<enter>
enddef

autocmd User LspAttached LspAttach()

def LspFormat()
    if lsp#buffer#BufHasLspServer(bufnr())
        LspFormat
    endif
enddef

autocmd_add([{
    replace: true,
    group: "FormatOnSave",
    event: "BufWritePre",
    pattern: join(format_on_save_patterns, ","),
    cmd: "LspFormat()"
}])

g:LspOptionsSet({
    autoComplete: false,
    omniComplete: true,
})
g:LspAddServer(lsp_servers)
