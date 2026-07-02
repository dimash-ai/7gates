# Add a per-user display timezone to Focal

## What you can now do
Focal now has a **display timezone** of your own, independent of where each event was created. A timezone picker sits in the top toolbar (next to the language switcher):

- **Pick any timezone** from a searchable list — the dozen most common zones are offered up front, and you can search the full IANA list. Search works in both languages: typing `Москва` or `Tbilisi` (or their Cyrillic forms) finds the city.
- **See your choice everywhere** — once selected, your timezone persists across reloads. A one-tap **"use system timezone"** returns you to your computer's zone.
- **AI chat speaks your timezone** — when you ask the assistant to plan something, it now resolves "today"/"tomorrow" and schedules new events against your selected display timezone rather than the server's, so an event you ask for at the end of your day lands on the right date.

Times shown in the app follow your language convention: 24-hour for Russian, 12-hour (AM/PM) otherwise.

## Why
The reference Focal lets each user view a shared calendar in their own timezone while events keep their original zone. This restores that foundation: events stay stored as their own wall-clock time + zone, and conversion to your display zone happens only at view time — with correct daylight-saving handling (spring-forward gaps and fall-back overlaps included), matching the backend's conversion exactly.

## Scope
This slice lands the **foundation** and its first consumer (AI chat). Wiring the display-timezone conversion into the **Calendar grid**, **Events list**, and the **event editor** round-trip — and server-side conversion of AI event cards — are intentionally later slices and are **not** included here. With nothing wired to consume conversions yet beyond AI chat, existing calendar/event displays are unchanged.

## Verification
- `pnpm typecheck` — clean
- `pnpm lint` (Biome, 272 files) — clean
- `pnpm test:run` — 862 passed (75 files), incl. DST boundary fixtures matched to the backend, invalid-zone fallback, ru/en time formatting, the timezone selector (localized labels + transliteration search), and the AI-chat timezone wiring
- `pnpm build` — succeeds

## Risk
Low. Additive: a new provider, hook, selector, and pure conversion helpers. No schema or API changes. No migration. The only edits to existing files mount the provider/selector and pass the display zone into AI chat.

## Base
Branch `feat/focal-parity-timezone` → `feature/focal-migration`.
