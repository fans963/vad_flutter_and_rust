use crate::api::types::error::AppError;

pub trait FormatGetter {
    fn get_format(&self, file_path: String) -> Result<String, AppError>;
}

pub struct SimpleFormatGetter {}
impl FormatGetter for SimpleFormatGetter {
    fn get_format(&self, file_path: String) -> Result<String, AppError> {
        if let Some(ext) = file_path.rfind('.').map(|i| &file_path[i + 1..]) {
            Ok(ext.to_lowercase())
        } else {
            Err(AppError::Format("No file extension found".to_string()))
        }
    }
}
