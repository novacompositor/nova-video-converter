use engine_api::types::RationalTime;

/// A timeline track holding layers/clips.
/// Phase 1 Q2 will implement full evaluation.
#[derive(Debug, Clone)]
pub struct TimelineTrack {
    pub name: String,
    pub duration: RationalTime,
}

impl Default for TimelineTrack {
    fn default() -> Self {
        Self {
            name: String::new(),
            duration: RationalTime::zero(24),
        }
    }
}

