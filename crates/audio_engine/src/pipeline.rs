/// Placeholder audio pipeline.
/// Phase 1 Q2 will integrate CPAL/rodio for full audio I/O.
#[derive(Debug, Default)]
pub struct AudioPipeline {
    pub sample_rate: u32,
}

impl AudioPipeline {
    pub fn new(sample_rate: u32) -> Self { Self { sample_rate } }
}
