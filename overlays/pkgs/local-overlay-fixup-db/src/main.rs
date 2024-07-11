use rusqlite::Connection;

const DB: &str = "/nix/var/nix/db/db.sqlite";

fn main() {
    if std::fs::metadata(DB).is_err() {
        return;
    }

    let conn = Connection::open(DB).expect("failed to open db");

    let mut stmt = conn
        .prepare("select path from ValidPaths")
        .expect("failed to prepare query for valid paths");

    let path_iter = stmt
        .query_map([], |row| Ok(row.get_unwrap::<usize, String>(0).to_string()))
        .expect("failed to query for valid paths");

    let invalid_paths = path_iter
        .filter_map(|path| {
            let path = path.ok()?;
            match std::fs::metadata(&path) {
                Ok(_) => None,
                Err(err) => match err.kind() {
                    std::io::ErrorKind::NotFound => Some(path),
                    _ => None,
                },
            }
        })
        .collect::<Vec<String>>();

    // TODO(jared): https://stackoverflow.com/questions/10012695/sql-statement-using-where-clause-with-multiple-values
    for path in invalid_paths {
        conn.execute("delete from ValidPaths where path = ?1", [&path])
            .expect("failed to delete path from valid paths");
        eprintln!("deleted {path} from valid_paths");
    }
}
