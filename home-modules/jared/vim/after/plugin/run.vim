vim9script

def g:Run(arg: string)
    execute get(builtins, arg, NixRun(arg))
enddef

def NixShell(attr: string, command: string): string
    return printf("terminal ++close ++shell nix shell nixpkgs\\\#%s -c %s", attr, command)
enddef

def NixRun(attr: string): string
    return NixShell(attr, attr)
enddef

var builtins = {
    nix: "terminal ++close ++shell nix repl --file \"<nixpkgs>\"",
    python3: NixRun("python3"),
    bash: NixRun("bash"),
    lua: NixRun("lua"),
    nodejs: NixShell("nodejs", "node"),
    deno: NixRun("deno"),
    bc: NixRun("bc"),
    ghci: NixShell("ghc", "ghci"),
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
