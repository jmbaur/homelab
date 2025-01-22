use base64::{prelude::BASE64_STANDARD, Engine};
use libsodium_sys::{
    crypto_sign_BYTES, crypto_sign_detached, crypto_sign_verify_detached, sodium_init,
};

pub fn main() {
    let mut args = std::env::args();

    let argv0 = args.next().unwrap_or_else(|| String::from("nix-key"));

    let Some(action) = args.next() else {
        usage(&argv0);
        std::process::exit(1);
    };

    match action.as_str() {
        "sign" => sign(&argv0, args),
        "verify" => verify(&argv0, args),
        _ => {
            eprintln!("unknown action {}", action);
            std::process::exit(1);
        }
    }
}

fn usage(argv0: &str) {
    let argv0 = std::fs::canonicalize(argv0).unwrap_or_else(|_| std::path::PathBuf::from(argv0));
    let argv0 = argv0
        .file_name()
        .unwrap_or_else(|| argv0.as_os_str())
        .to_string_lossy();

    eprintln!(
        r#"usage:
    {0} sign <data-file> <signing-key-file>
    {0} verify <data-file> <detached-signature-file> <verifying-key-file>...
        "#,
        argv0
    );
}

fn sign(argv0: &str, mut args: std::env::Args) {
    _ = unsafe { sodium_init() };

    let Some(data_file) = args.next() else {
        usage(argv0);
        std::process::exit(1);
    };
    let Some(key_file) = args.next() else {
        usage(argv0);
        std::process::exit(1);
    };
    let key = std::fs::read_to_string(key_file).expect("failed to read signing key file");
    let (key_name, key_base64) = key.split_once(":").expect("invalid signing key");
    let key_data = BASE64_STANDARD
        .decode(key_base64)
        .expect("failed to decode signing key");
    let data = std::fs::read_to_string(data_file).expect("failed to read data file");
    let data_ = data.as_bytes();

    let mut signature: [u8; crypto_sign_BYTES as _] = unsafe { std::mem::zeroed() };

    let mut signature_len: u64 = 0;
    let result = unsafe {
        crypto_sign_detached(
            signature.as_mut_ptr(),
            &mut signature_len,
            data_.as_ptr(),
            data_.len() as _,
            key_data.as_ptr(),
        )
    };

    if signature_len != crypto_sign_BYTES as _ {
        panic!("generated invalid signature");
    }

    if result != 0 {
        panic!("failed to sign data");
    }

    print!("{}:{}", key_name, BASE64_STANDARD.encode(signature));
}

fn verify(argv0: &str, mut args: std::env::Args) {
    _ = unsafe { sodium_init() };

    let Some(data_file) = args.next() else {
        usage(argv0);
        std::process::exit(1);
    };
    let Some(signature_file) = args.next() else {
        usage(argv0);
        std::process::exit(1);
    };

    let mut keys = Vec::new();
    while let Some(key) = args.next() {
        let (key_name, key_base64) = key.split_once(":").expect("invalid verifying key");
        let key_data = BASE64_STANDARD
            .decode(key_base64)
            .expect("failed to decode verifying key");
        keys.push((key_name.to_string(), key_data));
    }

    let data = std::fs::read_to_string(data_file).expect("failed to read data file");
    let data_ = data.as_bytes();
    let signature = std::fs::read_to_string(signature_file).expect("failed to read signature file");
    let (signature_key_name, signature_base64) =
        signature.split_once(":").expect("invalid signature");
    let signature_data = BASE64_STANDARD
        .decode(signature_base64)
        .expect("failed to decode signature");

    let key_data = keys
        .iter()
        .find_map(|(key_name, key_data)| {
            if key_name == signature_key_name {
                Some(key_data)
            } else {
                None
            }
        })
        .expect("could not find verifying key for signature");

    std::process::exit(
        unsafe {
            crypto_sign_verify_detached(
                signature_data.as_ptr(),
                data_.as_ptr(),
                data_.len() as _,
                key_data.as_ptr(),
            )
        }
        .abs(),
    );
}
