vim9script

def! g:Run(arg: string)
    execute get(builtins, arg, NixRun(arg))
enddef

def NixShell(attr: string, command: string): string
    return printf("terminal ++close ++shell nix shell nixpkgs\\\#%s -c %s", attr, command)
enddef

def NixRun(attr: string): string
    return NixShell(attr, attr)
enddef

var builtins = {
    bash: NixRun("bash"),
    bc: NixRun("bc"),
    deno: NixRun("deno"),
    ghci: NixShell("ghc", "ghci"),
    lua: NixRun("lua"),
    nix: "terminal ++close ++shell nix repl --file \"<nixpkgs>\"",
    nodejs: NixShell("nodejs", "node"),
    python3: NixRun("python3"),
}

def RunComplete(
        arg_lead: string,
        cmdline: string,
        cursor_position: number,
        ): list<string>
    var candidates = []

    for key in keys(builtins)
        if match(key, arg_lead) == 0
            add(candidates, key)
        endif
    endfor

    return candidates
enddef

command! -nargs=? -complete=customlist,RunComplete Run vim9cmd g:Run(<q-args>)
