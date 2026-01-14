use dashmap::DashMap;

use crate::api::{
    traits::audio_storage::AudioStorage,
    types::{audio::Audio, error::AppError},
};

pub struct KvAudioStorage {
    dashmap: DashMap<String, Audio>,
}

impl KvAudioStorage {
    pub fn new() -> Self {
        Self {
            dashmap: DashMap::new(),
        }
    }
}

impl AudioStorage for KvAudioStorage {
    fn load(&self, key: String) -> Result<Audio, AppError> {
        self.dashmap
            .get(&key)
            .map(|v| v.clone())
            .ok_or_else(|| AppError::NotFound(format!("Audio key not found: {}", key)))
    }

    fn remove(&self, key: String) -> Result<(), AppError> {
        if self.dashmap.remove(&key).is_some() {
            Ok(())
        } else {
            Err(AppError::NotFound(format!("Audio key not found for removal: {}", key)))
        }
    }

    fn save(&self, key: String, storage_unit: Audio) -> Result<(), AppError> {
        self.dashmap.insert(key, storage_unit);
        Ok(())
    }
}
