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

def GithubUrl(
		args: dict<any>,
		remote_url: string,
		rev: string,
		file: string,
		): string
	return ConstructUrl(
        args,
		"%s/blob/%s/%s",
		"#L%s",
		"-L%s",
		remote_url,
		rev,
		file,
	)
enddef

def GitlabUrl(
		args: dict<any>,
		remote_url: string,
		rev: string,
		file: string,
		): string
	return ConstructUrl(
        args,
        "%s/-/blob/%s/%s",
		"#L%s",
		"-%s",
		remote_url,
		rev,
		file,
	)
enddef

def SourcehutUrl(
		args: dict<any>,
		remote_url: string,
		rev: string,
		file: string,
		): string
	return ConstructUrl(
        args,
        "%s/tree/%s/item/%s",
		"#L%s",
		"-%s",
		remote_url,
		rev,
		file,
	)
enddef

def g:Permalink(range: number, line1: number, line2: number, bang: any)
	var args = {
		range: range,
		line1: line1,
		line2: line2,
	}

	var current_file = expand("%")

	var repo_dir = trim(system("git -C " .. shellescape(fnamemodify(current_file, ":p:h")) .. " rev-parse --show-toplevel"))

	var rev = trim(system("git -C " .. shellescape(repo_dir) .. " rev-parse HEAD"))

	var branch = trim(system("git -C " .. shellescape(repo_dir) .. " branch --show-current"))

	if branch == ""
		echo "detached HEAD, cannot get permalink"
		return
	endif

	var remote = trim(system("git -C " .. shellescape(repo_dir) .. " config branch." .. shellescape(branch) .. ".remote"))

	var git_file = trim(system("git -C " .. shellescape(repo_dir) .. " ls-files " .. shellescape(current_file)))

	var remote_url = trim(system("git -C " .. shellescape(repo_dir) .. " remote get-url " .. shellescape(remote)))

	remote_url = substitute(remote_url, "git+ssh://", "https://", "")

	var url = ""
	if match(remote_url, "https://github.com/.*") == 0
		url = GithubUrl(args, remote_url, rev, git_file)
	elseif match(remote_url, "https://gitlab.com/.*") == 0
		url = GitlabUrl(args, remote_url, rev, git_file)
	elseif match(remote_url, "https://git.sr.ht/.*") == 0
		url = SourcehutUrl(args, remote_url, rev, git_file)
	else
		echo "TODO: auto-detect forge"
        return
	endif

    if bang
        g:Osc52Copy([url])
    endif

	echo url
enddef

command! -bang -range Permalink vim9cmd g:Permalink(<range>, <line1>, <line2>, <bang>0)
