# App Icon & Splash Screen Assets

This directory holds the source images used by `flutter_launcher_icons` and
`flutter_native_splash` to generate platform-specific launcher icons and
native splash screens.

## Required Files

| File | Size | Purpose |
|------|------|---------|
| `app_icon.png` | 1024 x 1024 px | Main app icon (used for iOS, Android legacy, and splash) |
| `app_icon_foreground.png` | 1024 x 1024 px | Android adaptive icon foreground layer (must have transparent background and safe-zone padding — keep artwork within the inner 66% circle) |

Both files must be PNG with no transparency for `app_icon.png`. The foreground
layer (`app_icon_foreground.png`) should have a transparent background.

The adaptive icon background color is set to white (`#FFFFFF`) in
`pubspec.yaml`. Change `adaptive_icon_background` there if you want a
different background color, or replace it with an image path.

## Generating Icons

After placing the images in this directory, run:

```bash
cd mobile
dart run flutter_launcher_icons
```

This generates all required sizes for Android (`mipmap-*`) and iOS
(`AppIcon.appiconset`).

## Generating the Native Splash Screen

```bash
cd mobile
dart run flutter_native_splash:create
```

This generates platform-specific splash screen resources based on the
`flutter_native_splash` configuration in `pubspec.yaml`.

To restore the default Flutter splash screen at any time:

```bash
dart run flutter_native_splash:remove
```

## Configuration Reference

All icon and splash configuration lives in `pubspec.yaml` under the
`flutter_launcher_icons:` and `flutter_native_splash:` keys. See:

- https://pub.dev/packages/flutter_launcher_icons
- https://pub.dev/packages/flutter_native_splash
