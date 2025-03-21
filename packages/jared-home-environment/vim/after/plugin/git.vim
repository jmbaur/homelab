vim9script

def ConstructUrl(
        args: dict<any>,
        base_url_fmt: string,
        line1_fmt: string,
        line2_fmt: string,
        remote_url: string,
        rev: string,
        file: string,
        ): string
    var url = printf(base_url_fmt, remote_url, rev, file)

    if args.range == 0
        return url
    endif

    url = url .. printf(line1_fmt, args.line1)

    if args.line1 != args.line2
        url = url .. printf(line2_fmt, args.line2)
    endif

    return url
enddef

def GithubUrl(args: dict<any>, remote_url: string, rev: string, file: string): string
    return ConstructUrl(args, "%s/blob/%s/%s", "#L%s", "-L%s", remote_url, rev, file)
enddef

def GitlabUrl(args: dict<any>, remote_url: string, rev: string, file: string): string
    return ConstructUrl(args, "%s/-/blob/%s/%s", "#L%s", "-%s", remote_url, rev, file)
enddef

def GiteaUrl(args: dict<any>, remote_url: string, rev: string, file: string): string
    return ConstructUrl(args, "%s/src/commit/%s/%s", "#L%s", "-L%s", remote_url, rev, file)
enddef

def SourcehutUrl(args: dict<any>, remote_url: string, rev: string, file: string): string
    return ConstructUrl(args, "%s/tree/%s/item/%s", "#L%s", "-%s", remote_url, rev, file)
enddef

var forges = {
    github: GithubUrl,
    gitlab: GitlabUrl,
    gitea: GiteaUrl,
}

def DetectForge(remote_url: string): string
    var headers = split(system("curl --silent --head " .. shellescape(remote_url)), "\r\n")
    for header in headers
        if match(header, "^x-github-request-id: .*$") == 0
            return "github"
        elseif match(header, "^x-gitlab-meta: .*$") == 0
            return "gitlab"
        elseif match(header, "^set-cookie: .*i_like_gitea.*$") == 0
            return "gitea"
        endif
    endfor

    throw "Forge type not detected"
enddef

# TODO(jared): Make this work with tags
def! g:Permalink(range: number, line1: number, line2: number, bang: any)
    var args = {
        range: range,
        line1: line1,
        line2: line2,
    }

    var current_file = expand("%")

    var repo_dir = trim(system("git -C " .. shellescape(fnamemodify(current_file, ":p:h")) .. " rev-parse --show-toplevel"))

    var GitCommand = (command) => trim(system("git -C " .. shellescape(repo_dir) .. " " .. command))

    var git_file = GitCommand("ls-files " .. shellescape(current_file))
    if v:shell_error > 0
        throw "could not find git file"
    endif

    var is_clean = GitCommand("diff HEAD") == ""
    if !is_clean
        throw "working tree is dirty, cannot get permalink"
    endif

    var remote_refspecs = filter(
        map(split(
            GitCommand("branch --points-at HEAD --remotes"),
            "\n",
        ), (_, val) => trim(val)),
        (_, val) => match(val, ".*\/HEAD -> .*") != 0
    )
    if len(remote_refspecs) == 0
        throw "no remote branches found that point at HEAD"
    endif

    var remote = substitute(remote_refspecs[0], "\/.*", "", "")

    var remote_url = GitCommand("remote get-url " .. shellescape(remote))

    remote_url = substitute(remote_url, "git+ssh://.*@", "https://", "")

    var url = ""
    var ForgeFn = null_function

    if match(remote_url, "^https://github.com/.*$") == 0
        ForgeFn = GithubUrl
    elseif match(remote_url, "^https://gitlab.com/.*$") == 0
        ForgeFn = GitlabUrl
    elseif match(remote_url, "^https://git.sr.ht/.*$") == 0
        ForgeFn = SourcehutUrl
    else
        var forge = GitCommand("config get " .. shellescape(printf("remote.%s.forge-type", remote)))
        if forge == ""
            # no forge type set, try and detect it
            forge = DetectForge(remote_url)
            GitCommand("config set " .. shellescape(printf("remote.%s.forge-type ", remote)) .. shellescape(forge))
        endif

        ForgeFn = get(forges, forge)
    endif

    if !ForgeFn
        throw "Unknown forge type"
    endif

    url = ForgeFn(args, remote_url, GitCommand("rev-parse HEAD"), git_file)

    if bang
        setreg("@", url)
        g:Osc52Copy([url])
    endif

    echo url
enddef

command! -bang -range Permalink vim9cmd g:Permalink(<range>, <line1>, <line2>, <bang>0)
