use crate::schema::NovaProject;

/// Schema validation errors.
#[derive(Debug, thiserror::Error)]
pub enum ValidationError {
    #[error("Duplicate composition ID: {0}")]
    DuplicateCompositionId(String),
    #[error("Duplicate asset ID: {0}")]
    DuplicateAssetId(String),
    #[error("Duplicate layer ID in composition {comp}: {layer}")]
    DuplicateLayerId { comp: String, layer: String },
    #[error("Layer references unknown parent: {0}")]
    UnknownParentLayer(String),
    #[error("Active composition ID not found: {0}")]
    ActiveCompositionNotFound(String),
    #[error("Asset URI is empty for asset: {0}")]
    EmptyAssetUri(String),
    #[error("Composition duration is zero or negative")]
    InvalidCompositionDuration,
}

/// Validate semantic correctness of a `NovaProject`.
/// Returns a list of all validation errors found (not just the first).
pub fn validate(project: &NovaProject) -> Vec<ValidationError> {
    let mut errors = Vec::new();

    // Check unique composition IDs
    let mut comp_ids = std::collections::HashSet::new();
    for comp in &project.compositions {
        if !comp_ids.insert(comp.id) {
            errors.push(ValidationError::DuplicateCompositionId(comp.id.to_string()));
        }

        // Check unique layer IDs within composition
        let mut layer_ids = std::collections::HashSet::new();
        for layer in &comp.layers {
            if !layer_ids.insert(layer.id) {
                errors.push(ValidationError::DuplicateLayerId {
                    comp: comp.id.to_string(),
                    layer: layer.id.to_string(),
                });
            }
        }

        // Check parent references
        for layer in &comp.layers {
            if let Some(pid) = layer.parent_id {
                if !comp.layers.iter().any(|l| l.id == pid) {
                    errors.push(ValidationError::UnknownParentLayer(pid.to_string()));
                }
            }
        }

        // Check duration is positive
        if comp.duration.value <= 0 {
            errors.push(ValidationError::InvalidCompositionDuration);
        }
    }

    // Check unique asset IDs
    let mut asset_ids = std::collections::HashSet::new();
    for asset in &project.assets {
        if !asset_ids.insert(asset.id) {
            errors.push(ValidationError::DuplicateAssetId(asset.id.to_string()));
        }
        if asset.uri.is_empty() {
            errors.push(ValidationError::EmptyAssetUri(asset.id.to_string()));
        }
    }

    // Check active composition
    if let Some(active_id) = project.active_composition_id {
        if !comp_ids.contains(&active_id) {
            errors.push(ValidationError::ActiveCompositionNotFound(active_id.to_string()));
        }
    }

    errors
}

/// Returns `true` if the project is fully valid.
pub fn is_valid(project: &NovaProject) -> bool {
    validate(project).is_empty()
}
