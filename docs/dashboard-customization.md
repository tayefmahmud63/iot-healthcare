# Dashboard Customization

You can now manage every dashboard card directly from the `Settings` tab without touching code.

## Add New Widgets
- Tap **Add widget** → fill in the form.
- Pick a widget type (`Value card`, `Gauge`, or `Live chart`).
- Enter the exact Firebase Realtime Database key (under `metrics/<key>`). Keys are used as-is, so double-check spelling to match your database.
- Choose an icon, accent color, units/labels, and (for gauges) radial vs. linear style.

## Edit or Delete
- Tap the ⋮ menu on any item to edit it.
- For built-in widgets you can adjust the Firebase field name, labels, and units (the original definition is preserved as a reset option).
- Custom widgets can also be deleted entirely.

## Organize and Toggle
- Drag rows to reorder them; the layout updates instantly.
- Use the switch to turn any card on or off without deleting it.
- Changes persist per user/device via `SharedPreferences`.

## Reset
- Use **Reset** to restore the factory defaults, remove all custom widgets, clear overrides, and enable everything again.

## Firebase Shape Expectations
- **Value cards** expect `metrics/<key>` documents shaped like `{ value: "...", unit: "...", timestamp: "..." }`, but they gracefully fall back to primitive values.
- **Gauges** expect `value` (numeric) plus `unit`; `temperature` is still read for backwards compatibility but new data should write to `value`.
- **Live charts** stream the `value` and optional `timestamp` from the selected key.

If a new metric is missing in Firebase, creation will be blocked until the key exists, preventing typos and runtime errors.


