use crate::api::types::{audio::Audio, error::AppError};

pub trait AudioDecoder {
    fn decode(&self, format: String, data: Vec<u8>) -> Result<Audio, AppError>;
}
