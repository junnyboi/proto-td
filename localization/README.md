# Protos Localization

`en-US.json` is the development-default product catalog. Player-visible text uses a stable key plus an exact English fallback through the `I18n` autoload.

## Current product locale

- `en-US` — default and currently the only product-pinned locale.

## Contract

- Locale state is presentation-only and never enters simulation, save, state hash, replay, or telemetry state.
- Missing or blank catalog entries return the caller-provided English fallback.
- Every added product locale must have exact key and named-placeholder parity with `en-US` plus font, glyph, and layout evidence.
- `I18n.supported_locales()` and `I18n.set_locale()` are the Settings-selector seam. A selector becomes player-facing when a second product locale is pinned; this batch does not add a one-choice control to the title's sole-action flow.
