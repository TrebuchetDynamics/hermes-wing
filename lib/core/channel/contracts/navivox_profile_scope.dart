/// Shared default profile/server scope for gateway-backed channel state.
///
/// Keeping these identity defaults together prevents profile decoders, memory
/// requests, voice runs, and fallback contacts from drifting when a gateway does
/// not provide explicit scope metadata.
const navivoxDefaultGatewayServerId = 'navivox-gateway';
const navivoxDefaultProfileId = 'default';
const navivoxDefaultGatewayServerLabel = 'Gormes Gateway';
