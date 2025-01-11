const std = @import("std");

const C = @cImport({
    @cInclude("sqlite3.h");
});

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var database: ?*C.sqlite3 = null;
    defer {
        _ = C.sqlite3_close_v2(database);
    }

    switch (C.sqlite3_open_v2("/nix/var/nix/db/db.sqlite", &database, C.SQLITE_OPEN_READONLY, "unix")) {
        C.SQLITE_OK => {},
        else => |ret| {
            std.log.err("sqlite3_open_v2: {d}", .{ret});
            std.process.exit(1);
        },
    }

    if (database == null) {
        std.process.exit(1);
    }

    var query_statement: ?*C.sqlite3_stmt = null;
    defer {
        _ = C.sqlite3_finalize(query_statement);
    }

    switch (C.sqlite3_prepare_v3(database,
        \\select path from ValidPaths
    , -1, 0, &query_statement, null)) {
        C.SQLITE_OK => {},
        else => |ret| {
            std.log.err("sqlite3_prepare_v3: {d}", .{ret});
            std.process.exit(1);
        },
    }

    var all_paths = std.ArrayList([]const u8).init(allocator);
    defer all_paths.deinit();

    while (true) {
        switch (C.sqlite3_step(query_statement)) {
            C.SQLITE_ROW => {
                if (C.sqlite3_column_type(query_statement, 0) != C.SQLITE_TEXT) {
                    break;
                }

                const len = C.sqlite3_column_bytes(query_statement, 0);
                const text = C.sqlite3_column_text(query_statement, 0);
                const path = text[0..@intCast(len)];
                std.fs.cwd().access(path, .{}) catch |err| switch (err) {
                    error.FileNotFound => try all_paths.append(try allocator.dupe(u8, path)),
                    else => continue,
                };
            },
            C.SQLITE_DONE => break,
            else => |ret| {
                std.log.err("sqlite3_step: {d}", .{ret});
                break;
            },
        }
    }

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
    var delete_statement: ?*C.sqlite3_stmt = null;
    defer {
        _ = C.sqlite3_finalize(delete_statement);
    }

    switch (C.sqlite3_prepare_v3(database,
        \\delete from Refs where (referrer, reference) in
        \\  (select r.referrer, r.reference from Refs as r
        \\    inner join ValidPaths as v
        \\    on r.referrer = v.id or r.reference = v.id
        \\    where v.path = ?1)
        \\;
        \\delete from ValidPaths where path = ?1
    , -1, 0, &delete_statement, null)) {
        C.SQLITE_OK => {},
        else => |ret| {
            std.log.err("sqlite3_prepare_v3: {d}", .{ret});
            std.process.exit(1);
        },
    }

    for (all_paths.items) |path| {
        switch (C.sqlite3_bind_text(delete_statement, 1, path.ptr, @intCast(path.len), null)) {
            C.SQLITE_OK => {},
            else => |ret| {
                std.log.err("sqlite3_bind_text: {d}", .{ret});
                std.process.exit(1);
            },
        }

        switch (C.sqlite3_step(delete_statement)) {
            else => |ret| {
                std.debug.print("sqlite3_step: {d}\n", .{ret});
            },
        }

        switch (C.sqlite3_reset(delete_statement)) {
            else => |ret| {
                std.debug.print("sqlite3_reset: {d}\n", .{ret});
            },
        }

        std.log.info("deleted {s} from nix db", .{path});
    }
}
