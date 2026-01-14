use std::sync::Arc;

pub struct File {
    pub file_path: String,
    pub bytes: Arc<Vec<u8>>,
}
