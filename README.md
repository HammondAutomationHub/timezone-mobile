# TimeZoneMobile

A web-only world clock. Search for a city or country, pin it, and see the local time plus how far it is from this device. Clocks refresh every second. Daylight saving follows the IANA data shipped with the `timezone` package (tzdata 2026e), so California moves between PST and PDT on its own. A few older zone names now share another zone’s rules — Kuala Lumpur follows Singapore’s clock, for example — and those places stay as separate pins.

Nothing is sent to a server. There is no account. Pinned places and their text colors are stored in the browser’s local storage.

## Run locally

Install [Flutter](https://docs.flutter.dev/install), then:

```bash
flutter pub get
flutter run -d chrome
```

`flutter run -d web-server` works too. Edge is a fine target on Windows.

## Build

```bash
flutter build web --release --no-web-resources-cdn --base-href "/timezone-mobile/"
```

`--no-web-resources-cdn` copies CanvasKit into `build/web` instead of loading it from a Google CDN. The installed app can then start from the service-worker cache with no network. The base href matches this project site: [https://hammondautomationhub.github.io/timezone-mobile/](https://hammondautomationhub.github.io/timezone-mobile/).

The output directory is `build/web`.

## Deploy to GitHub Pages

Source lives on `main` in [HammondAutomationHub/timezone-mobile](https://github.com/HammondAutomationHub/timezone-mobile). `.github/workflows/pages.yml` builds the web app and publishes `build/web`.

1. In the repository, open **Settings → Pages → Build and deployment**.
2. Set **Source** to **GitHub Actions**.
3. Push to `main`. The workflow deploys the site.
4. Open [https://hammondautomationhub.github.io/timezone-mobile/](https://hammondautomationhub.github.io/timezone-mobile/) once while online. The service worker caches the app as it loads. Later visits work offline, including from an installed icon.

### Install

- **Android:** Chrome menu → Add to Home screen / Install app.
- **iOS:** Safari Share → Add to Home Screen. It can then sit on the Home Screen or in the Dock.
- **Desktop:** Chrome or Edge will offer to install TimeZoneMobile as its own window.

## What the screen shows

- Your device’s clock, so the comparison has a reference.
- Each pinned place’s local time, date, zone abbreviation, and GMT offset.
- The gap from your clock, such as `2h behind you` or `Same time as you`.
- A color shift when that place is outside 9:00 AM–5:00 PM local. The chip reads Before 9 AM, Business hours, or After 5 PM.
- A text color for the place name and clock. It starts as neutral gray. Tap the dot on a card to change it.
- On a first launch with nothing saved: California, Malaysia, Japan, Indonesia, and Singapore. Tap one to pin it.
- A short offline line when the browser reports no network. The clocks keep ticking from the device.

## Offline cache

`web/sw.js` is a small service worker. It precaches the app shell and then saves same-origin responses as they load, preferring the network when it is available and the cache when it is not.

`web/flutter_bootstrap.js` registers that worker. Flutter 3.47’s generated `flutter_service_worker.js` only unregisters older Flutter caches, so this project does not rely on it.

The time zone database is compiled into the app, so daylight-saving rules are available offline after the first successful load.

## Storage

`shared_preferences` writes the key `timezone_mobile.saved_zones.v1` to `localStorage` on web. Each entry is an IANA id, the label you picked, a subtitle, and a color. Clearing site data removes the list.
