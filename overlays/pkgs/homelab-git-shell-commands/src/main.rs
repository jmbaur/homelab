use std::path::PathBuf;

use git2::build::RepoBuilder;
use url::Url;

fn main() {
    let mut args = std::env::args();

    let mut argv0 = args.next().expect("missing argv0");

    loop {
        let argv0_path = PathBuf::from(argv0);
        let command = argv0_path.file_name().expect("missing argv0");

        match command.to_str().expect("failed to convert OsStr to str") {
            "homelab-git-shell-commands" => {
                argv0 = args.next().expect("missing argv0");
                continue;
            }
            "clone" => clone(args),
            command => {
                eprintln!("unknown command {}", command);
                std::process::exit(1);
            }
        }

        break;
    }
}

fn clone(mut args: std::env::Args) {
    let home = PathBuf::from(std::env::var("HOME").expect("$HOME not set"));

    let repo_url = args.next().expect("missing repository URL argument");

    let url = Url::parse(&repo_url).expect("invalid repository URL");

    let description =
        rprompt::prompt_reply("description: ").expect("failed to get repository description");

    let basename = url
        .path_segments()
        .expect("failed to get path segments for repository URL")
        .last()
        .expect("failed to create name for repository clone");

    let destination = home.join(&basename);

    let mut _repo = RepoBuilder::new()
        .bare(true)
        .clone(&repo_url, destination.as_path())
        .expect("failed to clone");

    std::fs::write(
        destination.join("description"),
        if !description.is_empty() {
            description.as_str()
        } else {
            basename
        },
    )
    .expect("failed to write description");
}
