{ config, pkgs, ... }:

{
  nixpkgs.overlays = [
    (import (builtins.fetchTarball {
      url =
        "https://github.com/nix-community/neovim-nightly-overlay/archive/master.tar.gz";
    }))
  ];

  home-manager.users.jared.programs.neovim = {
    enable = true;
    vimAlias = true;
    package = pkgs.neovim-nightly;
    extraPackages = with pkgs; [
      gcc
      haskell-language-server
      nodePackages.typescript-language-server
      nodePackages.bash-language-server
      gopls
      rnix-lsp
      pyright
    ];
    plugins = with pkgs.vimPlugins; [
      awesome-vim-colorschemes
      typescript-vim
      vim-nix
      vim-commentary
      vim-fugitive
      vim-surround
      vim-repeat
      vim-rsi
      nvim-treesitter
      nvim-treesitter-textobjects
      nvim-lspconfig
      telescope-nvim
      popup-nvim
      plenary-nvim
      nvim-autopairs
    ];
    extraConfig = ''
      function! MyHighlights() abort
        highlight Normal     ctermbg=NONE
        highlight NonText    ctermbg=NONE
      endfunction

      augroup MyColors
          autocmd!
          autocmd ColorScheme * call MyHighlights()
      augroup END

      color happy_hacking

      lua << EOF
      require'nvim-treesitter.configs'.setup {
        ensure_installed = "maintained",
        highlight = {
          enable = true,
        },
      }
      require('nvim-autopairs').setup()

      vim.opt.wrap = false
      vim.opt.expandtab = true
      vim.opt.shiftwidth = 2
      vim.opt.tabstop = 2
      vim.opt.showmatch = true
      vim.opt.ignorecase = true
      vim.opt.smartcase = true
      vim.opt.number = true
      vim.opt.relativenumber = true
      vim.opt.hidden = true
      vim.opt.undofile = true
      vim.opt.swapfile = false
      vim.opt.foldenable = false
      vim.opt.scrolloff = 5
      vim.opt.sidescrolloff = 5
      vim.opt.clipboard = 'unnamedplus'
      vim.opt.foldmethod = 'indent'

      vim.g.mapleader = ','

      local opts = { noremap = true, silent = true }

      vim.api.nvim_set_keymap("n", "<C-L>", "<cmd>noh<cr>", opts)
      vim.api.nvim_set_keymap("n", "<leader>ff", "<cmd>lua require('telescope.builtin').find_files()<cr>", opts)
      vim.api.nvim_set_keymap("n", "<leader>fg", "<cmd>lua require('telescope.builtin').live_grep()<cr>", opts)
      vim.api.nvim_set_keymap("n", "<leader>fb", "<cmd>lua require('telescope.builtin').buffers()<cr>", opts)
      vim.api.nvim_set_keymap("n", "<leader>fh", "<cmd>lua require('telescope.builtin').help_tags()<cr>", opts)

      local on_attach = function(client, bufnr)
        local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
        local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

        buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

        local opts = { noremap=true, silent=true }

        buf_set_keymap('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
        buf_set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
        buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
        buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
        buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
        buf_set_keymap('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
        buf_set_keymap('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
        buf_set_keymap('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
        buf_set_keymap('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
        buf_set_keymap('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
        buf_set_keymap('n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
        buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
        buf_set_keymap('n', '<space>e', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
        buf_set_keymap('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
        buf_set_keymap('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
        buf_set_keymap('n', '<space>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)
        buf_set_keymap("n", "<space>f", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)
      end

      local servers = { "gopls", "tsserver", "pyright", "bashls", "rnix", "hls" }
      for _, lsp in ipairs(servers) do
        require('lspconfig')[lsp].setup { on_attach = on_attach }
      end
      EOF
    '';
  };
}
