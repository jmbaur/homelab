// git-shell-commands is a multi-call binary for simple git-shell(1) commands
package main

import (
	"errors"
	"flag"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"strings"

	git "github.com/libgit2/git2go/v34"
)

var progname string

var commands = map[string]func() error{
	"list":   list,
	"create": create,
	"delete": remove,
}

func normalizeRepoPath(repoName string) (string, error) {
	dir, err := os.Getwd()
	if err != nil {
		return "", err
	}

	if strings.HasSuffix(repoName, ".git") {
		return filepath.Join(dir, repoName), nil
	}

	return filepath.Join(dir, fmt.Sprintf("%s.git", repoName)), nil
}

func list() error {
	cwd, err := os.Getwd()
	if err != nil {
		return err
	}

	return fs.WalkDir(os.DirFS(cwd), ".", func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}

		if !d.IsDir() {
			return nil
		}

		repo, err := git.OpenRepository(filepath.Join(cwd, path))
		if err != nil {
			// we are not at a repo yet, continue recursing
			return nil
		}

		if repo.IsBare() {
			fmt.Println(path)
		}

		// we just saw a repo, don't recurse into it
		return fs.SkipDir
	})
}

func create() error {
	isPrivate := flag.Bool("private", false, "Create an unexported repository")
	flag.Parse()

	repoName := flag.Arg(0)
	if repoName == "" {
		return errors.New("no repository name provided")
	}

	repoPath, err := normalizeRepoPath(repoName)
	if err != nil {
		return err
	}

	fmt.Printf("repository description: ")
	var description string
	if _, err := fmt.Scanln(&description); err != nil {
		return err
	}

	repo, err := git.InitRepository(repoPath, true)
	if err != nil {
		return err
	}

	repoPath = repo.Path()

	if !*isPrivate {
		f, err := os.Create(filepath.Join(repoPath, "git-daemon-export-ok"))
		if err != nil {
			if err := os.RemoveAll(repoPath); err != nil {
				return err
			}
			return err
		}
		if err := f.Close(); err != nil {
			return err
		}
	}

	descFile, err := os.OpenFile(filepath.Join(repoPath, "description"), os.O_RDWR|os.O_TRUNC|os.O_CREATE, 0o644)
	if err != nil {
		return err
	}
	if _, err := descFile.WriteString(description); err != nil {
		return err
	}
	if err := descFile.Close(); err != nil {
		return err
	}

	if *isPrivate {
		fmt.Printf("created unexported repository at %s\n", repoPath)
	} else {
		fmt.Printf("created exported repository at %s\n", repoPath)
	}

	return nil
}

func remove() error {
	flag.Parse()

	repoName := flag.Arg(0)
	if repoName == "" {
		return errors.New("no repository name provided")
	}

	repoPath, err := normalizeRepoPath(repoName)
	if err != nil {
		return err
	}

	if err := os.RemoveAll(repoPath); err != nil {
		return err
	}

	fmt.Printf("deleted repository at %s\n", repoPath)

	return nil
}

func help(commandList []string) func() error {
	return func() error {
		fmt.Printf("available commands: %s\n", strings.Join(commandList, " "))
		return nil
	}
}

func main() {
	commandList := []string{"help"}
	for k := range commands {
		commandList = append(commandList, k)
	}
	commands["help"] = help(commandList)

	// Allow the program to be a multi-call binary
	var command string
	base := filepath.Base(os.Args[0])
	if base == progname || progname == "" {
		if len(os.Args) > 1 {
			command = os.Args[1]
		} else {
			command = "help"
		}
	} else {
		command = base
	}

	cmdFn, ok := commands[command]
	if !ok {
		fmt.Printf("command %s not found\n", command)
		os.Exit(1)
	}

	if err := cmdFn(); err != nil {
		fmt.Printf("%s failed: %v\n", command, err)
		os.Exit(2)
	}
}
