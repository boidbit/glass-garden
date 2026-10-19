# Releasing Glass Run on Google Play

The workflow **Glass Run Play release** (`.github/workflows/kaanch-run-release.yml`) builds a signed Android App Bundle (`.aab`), the only format Play takes for new apps (it won't take an APK). It uses Godot 4.7.2 so the bundle targets API 36, which Play requires for new apps and updates since 31 August 2026. The everyday APK workflow (**Kaanch Run APK**) is unchanged and still uses Godot 4.3.

## Releasing

1. GitHub → **Actions** → **Glass Run Play release** → **Run workflow** → **Run workflow**. There is nothing to fill in.
2. When it is green, open the run and download **GlassRun-aab** from *Artifacts* (a zip with the `.aab` inside).
3. Play Console → your app → **Release** → pick a track (Internal testing first) → **Create new release** → upload the `.aab`.

The version code is the run number, so every run's bundle is newer than the last, as Play needs.

## One-time setup (already done)

- Upload key: `upload.keystore`, alias `glassrun-upload`, kept outside the repo (back it up). Turn on **Play App Signing** when you create the app in Play Console; Google keeps the real signing key and a lost upload key can be reset through Play support.
- GitHub secrets: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEY_ALIAS`, `ANDROID_KEYSTORE_PASSWORD`.
- Play Console: create the app with package name `com.boidbit.glassrun`, then fill in the store listing, content rating and data safety.

## If it breaks

- *Missing secret*: the first step says which.
- *Godot export failed*: the run's summary shows the Godot/Gradle messages. SDK/NDK versions are at the top of the workflow.
- *Game behaves differently*: the game was made on Godot 4.3 and is built here with 4.7.2. Play the release build on a phone before promoting it past internal testing.
