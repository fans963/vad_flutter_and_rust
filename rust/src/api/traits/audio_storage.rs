use crate::api::types::{audio::Audio, error::AppError};

pub trait AudioStorage {
    fn save(&self, key: String, storage_unit: Audio) -> Result<(), AppError>;
    fn load(&self, key: String) -> Result<Audio, AppError>;
    fn remove(&self, key: String) -> Result<(), AppError>;
}
