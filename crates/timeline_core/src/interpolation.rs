use engine_api::types::Interpolation;

/// Evaluate an interpolated value at position `t` (0.0..=1.0) between `v0` and `v1`.
pub fn interpolate_f64(t: f64, v0: f64, v1: f64, mode: Interpolation) -> f64 {
    match mode {
        Interpolation::Hold => v0,
        Interpolation::Linear => v0 + (v1 - v0) * t,
        Interpolation::EaseIn => {
            let t2 = t * t;
            v0 + (v1 - v0) * t2
        }
        Interpolation::EaseOut => {
            let t2 = t * (2.0 - t);
            v0 + (v1 - v0) * t2
        }
        Interpolation::EaseInOut => {
            let t2 = t * t * (3.0 - 2.0 * t);
            v0 + (v1 - v0) * t2
        }
        // Bezier handled separately with tangents
        _ => v0 + (v1 - v0) * t,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn linear_midpoint() {
        let v = interpolate_f64(0.5, 0.0, 100.0, Interpolation::Linear);
        assert!((v - 50.0).abs() < 1e-9);
    }

    #[test]
    fn hold_returns_v0() {
        let v = interpolate_f64(0.9, 42.0, 100.0, Interpolation::Hold);
        assert!((v - 42.0).abs() < 1e-9);
    }
}
