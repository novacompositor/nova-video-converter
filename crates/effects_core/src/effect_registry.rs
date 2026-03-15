/// Registry for effect types.
/// Phase 1 Q3 will populate with built-in effects.
#[derive(Debug, Default)]
pub struct EffectRegistry {
    types: Vec<String>,
}

impl EffectRegistry {
    pub fn new() -> Self { Self::default() }

    pub fn register(&mut self, effect_type: impl Into<String>) {
        self.types.push(effect_type.into());
    }

    pub fn contains(&self, effect_type: &str) -> bool {
        self.types.iter().any(|t| t == effect_type)
    }

    pub fn all_types(&self) -> &[String] {
        &self.types
    }
}
