/// Placeholder render graph.
/// Phase 1 Q2 will implement the full node-based GPU/CPU pipeline.
#[derive(Debug, Default)]
pub struct RenderGraph {
    pub node_count: usize,
}

impl RenderGraph {
    pub fn new() -> Self { Self::default() }
}
