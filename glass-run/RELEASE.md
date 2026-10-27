# Releasing Glass Run on Google Play

The workflow **Glass Run Play release** (`.github/workflows/glass-run-release.yml`) builds a signed Android App Bundle (`.aab`), the only format Play takes for new apps (it won't take an APK). It uses Godot 4.7.2 so the bundle targets API 36, which Play requires for new apps and updates since 31 August 2026. The everyday APK workflow (**Glass Run APK**) is unchanged and still uses Godot 4.3.

## Releasing

1. GitHub → **Actions** → **Glass Run Play release** → **Run workflow**.
2. *Version name* is what players see (e.g. `1.01`, `1.02`). *Version code* is a separate whole number that Play uses to order uploads; it cannot be 1.01. Leave it empty and it is the run number plus 10, which goes up every run (the 10 carries on the count from before the workflow file was renamed, which started its run numbers again from 1), or type a whole number higher than your last Play upload (Play refuses one it has seen before).
3. When it is green, open the run and download **GlassRun-release** from *Artifacts*. The zip has two files, both signed with your upload key:
   - `GlassRun-<name>-code<code>.aab` — upload this in Play Console → your app → **Release** → Internal testing → **Create new release**.
   - `GlassRun-<name>-code<code>.apk` — install this on a phone to try the game first. It cannot update an install that came from Play (Play re-signs with its own key).

The store listing icon is `store/app-icon-512.png` (512×512, upload it under *Store listing → App icon*).

## One-time setup (already done)

- Upload key: `upload.keystore`, alias `glassrun-upload`, kept outside the repo (back it up). Turn on **Play App Signing** when you create the app in Play Console; Google keeps the real signing key and a lost upload key can be reset through Play support.
- GitHub secrets: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEY_ALIAS`, `ANDROID_KEYSTORE_PASSWORD`.
- Play Console: create the app with package name `com.boidbit.glassrun`, then fill in the store listing, content rating and data safety.

## If it breaks

- *Missing secret*: the first step says which.
- *Godot export failed*: the run's summary shows the Godot/Gradle messages. SDK/NDK versions are at the top of the workflow.
- *Game behaves differently*: the game was made on Godot 4.3 and is built here with 4.7.2. Play the release build on a phone before promoting it past internal testing.
