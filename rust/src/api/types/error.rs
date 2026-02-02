use thiserror::Error;

#[derive(Error, Debug, Clone)]
pub enum AppError {
    #[error("IO error: {0}")]
    Io(String),

    #[error("Format error: {0}")]
    Format(String),

    #[error("Decode error: {0}")]
    Decode(String),

    #[error("Storage error: {0}")]
    Storage(String),

    #[error("Cache error: {0}")]
    Cache(String),

    #[error("Not found: {0}")]
    NotFound(String),

    #[error("Generic error: {0}")]
    Generic(String),

    #[error("Processing error: {0}")]
    ProcessingError(String),
}

impl From<std::io::Error> for AppError {
    fn from(err: std::io::Error) -> Self {
        AppError::Io(err.to_string())
    }
}
