# iOS Testing

## Fast Local Check

Run this before sending a build to a phone:

```bash
scripts/test_fast.sh
```

This runs:

- `flutter analyze`
- `flutter test`

## Real iPhone Smoke Test

List devices:

```bash
flutter devices
```

Run the iOS smoke test on a connected iPhone:

```bash
scripts/test_ios_smoke.sh 00008030-001A41513A88C02E
```

The smoke test starts from a signed-out first-launch state and verifies:

- Splash routes to onboarding.
- Skipping onboarding persists `onboarding_done`.
- Login screen appears.
- Create-account navigation works.
- Protected routes redirect signed-out users back to login.

## Notes

The iOS smoke script uses `flutter drive` with `--publish-port` because real iOS devices can require that path for reliable integration-test attachment.
