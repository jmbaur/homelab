use std::io::Write;

pub fn main() -> std::io::Result<()> {
    let mut args = std::env::args();
    _ = args.next().unwrap();
    let cmd = args.next().unwrap();
    let cmd_args: Vec<String> = args.collect();

    let mut map = std::collections::HashMap::new();

    for line in std::io::stdin().lines() {
        let Ok(line) = line else {
            break;
        };

        let Some((num, content)) = line.split_once("\t") else {
            break;
        };

        _ = map.insert(num.to_owned(), content.to_owned());
    }

    let mut cmd_input = String::new();
    for val in map.values() {
        cmd_input.push_str(val);
        cmd_input.push('\n');
    }

    let mut child = std::process::Command::new(cmd)
        .args(cmd_args)
        .stdin(std::process::Stdio::piped())
        .stdout(std::process::Stdio::piped())
        .spawn()?;

    let child_stdin = child.stdin.as_mut().unwrap();
    child_stdin.write_all(cmd_input.as_bytes()).unwrap();

    let output = child.wait_with_output()?;

    if !output.status.success() {
        std::process::exit(output.status.code().unwrap_or(1));
    }

    let output = String::from_utf8(output.stdout).unwrap();

    let selection = output.lines().next().unwrap();

    let found = 'f: {
        for (key, value) in map {
            if selection == &value {
                println!("{key}\t{value}");
                break 'f true;
            }
        }
        break 'f false;
    };

    std::process::exit(if found { 0 } else { 1 });
}
