mod frb_generated; /* AUTO INJECTED BY flutter_rust_bridge. This line may not be accurate, and you can change it according to your needs. */
pub mod api;
use std::sync::atomic::AtomicBool; 

#[cfg(target_os = "android")]
fn init_logger() {
    android_logger::init_once(
        android_logger::Config::default()
            .with_max_level(log::LevelFilter::Debug)
            .with_tag("rust_vad"),
    );
}

#[cfg(all(target_arch = "wasm32", not(target_os = "android")))]
fn init_logger() {
    console_error_panic_hook::set_once();
    let _ = console_log::init_with_level(log::Level::Debug);
}

#[cfg(all(not(target_os = "android"), not(target_arch = "wasm32")))]
fn init_logger() {
    use std::sync::Once;
    static INIT: Once = Once::new();
    INIT.call_once(|| {
        env_logger::Builder::from_default_env()
            .filter_level(log::LevelFilter::Debug)
            .init();
    });
}

#[ctor::ctor]
fn init() {
    init_logger();
}
