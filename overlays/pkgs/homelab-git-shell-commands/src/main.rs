use std::os::unix::fs::PermissionsExt;
use std::{env::Args, fs::Permissions, path::PathBuf};

use git2::{Repository, RepositoryInitOptions};

const CARGO_PKG_NAME: &str = env!("CARGO_PKG_NAME");
static COMMANDS: &[(&str, fn(Args))] = &[("help", help), ("create", create), ("list", list)];

fn help(mut _args: Args) {
    eprintln!("Possible commands:");

    for (command, _) in COMMANDS {
        eprintln!("\t{command}");
    }
}

fn create(mut args: Args) {
    let all_repo_dir = PathBuf::from(std::env::var("HOME").expect("failed to get $HOME"));

    let name = match args.next() {
        Some(name) => name,
        None => rprompt::prompt_reply("name: ").expect("failed to get repository name"),
    };

    let description =
        rprompt::prompt_reply("description: ").expect("failed to get repository description");

    let mut init_opts = RepositoryInitOptions::new();

    init_opts
        .bare(true)
        .mkpath(true)
        .no_reinit(true)
        .no_dotgit_dir(true)
        .description(&description)
        .initial_head("refs/heads/main");

    let repo_dir = all_repo_dir.join(name);

    let repo =
        Repository::init_opts(repo_dir.as_path(), &init_opts).expect("failed to init repository");

    let post_receive = repo_dir.join("hooks/post-receive");
    std::fs::write(
        post_receive.as_path(),
        "#!/bin/sh\nnats pub ci \"$(readlink --canonicalize $GIT_DIR) $(cat /dev/stdin)\"",
    )
    .expect("failed to write post-receive hook");
    let post_receive_file = std::fs::OpenOptions::new()
        .open(post_receive.as_path())
        .expect("failed to open post-receive file");
    post_receive_file
        .set_permissions(Permissions::from_mode(0o700))
        .expect("failed to mark post-receive as executable");

    let setup_mirror = rprompt::prompt_reply("setup mirror [y/N]: ")
        .expect("")
        .to_uppercase()
        .starts_with("Y");

    if setup_mirror {
        let _remote = repo
            .remote(
                "mirror",
                rprompt::prompt_reply("mirror url: ")
                    .expect("failed to get mirror url")
                    .as_str(),
            )
            .expect("failed to add remote");

        let mut config = repo.config().expect("failed to get repo config");

        config
            .set_bool("remote.mirror.mirror", true)
            .expect("failed to update repo config");
    }
}

fn list(mut _args: Args) {
    let read_dir = std::fs::read_dir(std::env::var("HOME").expect("failed to get $HOME"))
        .expect("failed to open repo directory");

    for entry in read_dir {
        let entry = entry.expect("failed to get entry");
        if let Ok(_repo) = Repository::open(entry.path()) {
            println!(
                "{}",
                entry
                    .file_name()
                    .to_str()
                    .expect("failed to convert OsStr to &str")
            );
        }
    }
}

fn main() {
    let mut args = std::env::args();

    let mut argv0 = args.next().expect("missing argv0");

    loop {
        let argv0_path = PathBuf::from(argv0);
        let command = argv0_path.file_name().expect("missing argv0");

        match command.to_str().expect("failed to convert OsStr to str") {
            CARGO_PKG_NAME => {
                argv0 = args.next().expect("missing argv0");
                continue;
            }
            command => {
                for (cmd, function) in COMMANDS {
                    if cmd == &command {
                        return function(args);
                    }
                }

                eprintln!("unknown command");
                std::process::exit(1);
            }
        }
    }
}
