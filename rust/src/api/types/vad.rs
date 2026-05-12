use flutter_rust_bridge::frb;

#[derive(Clone, Debug)]
pub struct VadParamDef {
    pub key: String,
    pub label: String,
    pub kind: String,
    pub value: f32,
    pub min: f32,
    pub max: f32,
    pub step: f32,
}

#[frb(ignore)]
impl VadParamDef {
    pub fn float(key: &str, label: &str, value: f32, min: f32, max: f32, step: f32) -> Self {
        Self { key: key.into(), label: label.into(), kind: "float".into(), value, min, max, step }
    }
    pub fn int(key: &str, label: &str, value: i32, min: i32, max: i32) -> Self {
        Self { key: key.into(), label: label.into(), kind: "int".into(), value: value as f32, min: min as f32, max: max as f32, step: 1.0 }
    }
    pub fn bool_(key: &str, label: &str, value: bool) -> Self {
        let v = if value { 1.0 } else { 0.0 };
        Self { key: key.into(), label: label.into(), kind: "bool".into(), value: v, min: 0.0, max: 1.0, step: 1.0 }
    }
}

#[derive(Clone, Debug)]
pub struct VadResult {
    pub confidence: Vec<f32>,
    pub frame_size: u32,
}
