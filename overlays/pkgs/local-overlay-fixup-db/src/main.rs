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

    // As of 2024-07-12:
    //
    // sqlite> .schema Refs
    // CREATE TABLE Refs (
    //     referrer  integer not null,
    //     reference integer not null,
    //     primary key (referrer, reference),
    //     foreign key (referrer) references ValidPaths(id) on delete cascade,
    //     foreign key (reference) references ValidPaths(id) on delete restrict
    // );
    // CREATE INDEX IndexReferrer on Refs(referrer);
    // CREATE INDEX IndexReference on Refs(reference);
    //
    // sqlite> .schema ValidPaths
    // CREATE TABLE ValidPaths (
    // id               integer primary key autoincrement not null,
    // path             text unique not null,
    // hash             text not null, -- base16 representation
    // registrationTime integer not null,
    // deriver          text,
    // narSize          integer,
    // ultimate         integer, -- null implies "false"
    // sigs             text, -- space-separated
    // ca               text -- if not null, an assertion that the path is content-addressed; see ValidPathInfo
    // );
    // CREATE TRIGGER DeleteSelfRefs before delete on ValidPaths
    // begin
    // delete from Refs where referrer = old.id and reference = old.id;
    // end;

    // The readonly nix database does not have any entries in the DerivationOutputs table, so we
    // don't have to worry about deleting any rows from there.
    //
    // TODO(jared): https://stackoverflow.com/questions/10012695/sql-statement-using-where-clause-with-multiple-values
    for path in invalid_paths {
        conn.execute(
            "delete from Refs r inner join ValidPaths v on r.referrer = v.id or r.reference = v.id where v.path = ?1",
            [&path],
        )
        .expect("failed to delete dangling path from nix db");
        eprintln!("deleted {path} from nix db");
    }
}
