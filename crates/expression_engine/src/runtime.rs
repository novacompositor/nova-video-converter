/// Placeholder expression runtime.
/// Phase 2 will implement the full AE-like DSL parser and evaluator.
#[derive(Debug, Default)]
pub struct ExpressionRuntime;

impl ExpressionRuntime {
    pub fn new() -> Self { Self }
    pub fn eval(&self, _expr: &str) -> Result<f64, String> {
        Err("Expression engine not yet implemented".to_string())
    }
}
