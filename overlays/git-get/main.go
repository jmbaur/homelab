// Package main is the entrypoint to the git-get program.
package main

import (
	"errors"
	"fmt"
	"log"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/mitchellh/go-homedir"
)

func must(err error) {
	if err != nil {
		log.Fatal(err)
	}
}

func main() {
	// Not actually a standard xdg directory, but why not.
	projDir, ok := os.LookupEnv("PROJECTS_DIR")
	if !ok {
		projDir = "~/projects"
	}

	projDir, err := homedir.Expand(projDir)
	must(err)

	args := os.Args[1:]

	u := &url.URL{}
	urlFound := false
	for _, arg := range args {
		if m, err := url.ParseRequestURI(arg); err == nil {
			u = m
			urlFound = true
			break
		}
	}

	// TODO(jared): Clone URLs are not just remote paths, consider supporting
	// other clone URIs.
	if !urlFound {
		must(errors.New("did not find clone URL"))
	}

	dir := filepath.Join(projDir, strings.ToLower(u.Host), strings.ToLower(u.Path))

	cmd := exec.Command("git", "clone")
	cmd.Args = append(cmd.Args, args...)
	cmd.Args = append(cmd.Args, dir)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Env = os.Environ()
	fmt.Printf("Running '%s'\n", strings.Join(cmd.Args, " "))
	must(cmd.Run())
}
