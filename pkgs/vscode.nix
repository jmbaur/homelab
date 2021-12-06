self: super: {
  vscode-with-extensions = super.vscode-with-extensions.override {
    vscodeExtensions = with super.vscode-extensions; [
      ms-vsliveshare.vsliveshare
      vscodevim.vim
    ];
  };
}
