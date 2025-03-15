vim9script

var lsp_servers: list<dict<any>> = []

if executable("nil")
	add(lsp_servers, {
		name: "nil",
		filetype: ["nix"],
		path: "nil",
		args: [],
		initializationOptions: {formatting: {command: ["nixfmt"]}},
	})
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
endif

if executable("bash-language-server")
	add(lsp_servers, {
		name: "bashls",
		filetype: ["sh"],
		path: "bash-language-server",
		args: ["start"],
	})
endif

if executable("gopls")
	add(lsp_servers, {
		name: "gopls",
		filetype: ["go", "mod"],
		path: "gopls",
		args: ["serve"],
		initializationOptions: {gofumpt: true, staticcheck: true},
	})
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
endif

def! LspAttach()
	set signcolumn=yes
	nnoremap <buffer><silent> <C-]> <cmd>LspGotoDefinition<enter>
	nnoremap <buffer><silent> K <cmd>LspHover<enter>
	nnoremap <buffer><silent> [d <cmd>LspDiagPrevWrap<enter>
	nnoremap <buffer><silent> ]d <cmd>LspDiagNextWrap<enter>
	nnoremap <buffer><silent> gd <cmd>LspGotoDefinition<enter>
	nnoremap <buffer><silent><leader> r <cmd>LspShowReferences<enter>
	nnoremap <buffer><silent><leader> rn <cmd>LspRename<enter>
enddef

autocmd User LspAttached LspAttach()

g:LspOptionsSet({
	autoComplete: false,
	showDiagOnStatusLine: true,
       	omniComplete: true,
})
g:LspAddServer(lsp_servers)
