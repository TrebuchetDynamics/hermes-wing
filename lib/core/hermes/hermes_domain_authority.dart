/// Wing Link owns installation, adoption, process lifecycle, pairing, and
/// transport bootstrap only. Hermes Agent is the sole authority for profiles,
/// providers, memory, skills, tasks, and configuration.
///
/// Legacy Wing Link profile/provider adapters remain temporarily compiled for
/// rollback compatibility, but no production Wing surface may call them and
/// the Wing Link server does not expose those routes.
const wingLinkDomainFallbacksEnabled = false;
