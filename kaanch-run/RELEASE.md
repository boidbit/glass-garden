# Releasing Glass Run on Google Play

The workflow **Glass Run Play release** (`.github/workflows/kaanch-run-release.yml`) builds a signed Android App Bundle (`.aab`), the only format Play takes for new apps. It uses Godot 4.7.2 so the bundle targets API 36, which Play requires for new apps and updates since 31 August 2026. The everyday APK workflow (**Kaanch Run APK**) is unchanged and still uses Godot 4.3.

## One-time setup

### 1. Make the upload key (once, keep it forever)

```
keytool -genkeypair -v -keystore upload.keystore -alias glassrun-upload -keyalg RSA -keysize 2048 -validity 10000
```

Back up `upload.keystore` and its password somewhere safe (not in the repo). Turn on **Play App Signing** when you create the app in Play Console: Google keeps the real app-signing key, and this is only your *upload* key, so a lost upload key can be reset through Play support.

### 2. Add the secrets

GitHub repo → **Settings → Secrets and variables → Actions → New repository secret**:

| Secret | Value |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | the keystore, base64: PowerShell `[Convert]::ToBase64String([IO.File]::ReadAllBytes("upload.keystore")) \| Set-Clipboard` |
| `ANDROID_KEY_ALIAS` | `glassrun-upload` (the `-alias` above) |
| `ANDROID_KEYSTORE_PASSWORD` | the password you chose (use the same for the keystore and the key) |
| `PLAY_SERVICE_ACCOUNT_JSON` | *(only for automatic upload)* the service account's JSON key, whole file |

### 3. Create the app in Play Console

Create the app with package name `com.boidbit.glassrun`, fill in the store listing, content rating and data safety. Play's API can't create an app, and the **first bundle has to be uploaded by hand** (Release → Testing → Internal testing → Create release → upload the `.aab` from the workflow run). After that the workflow can upload by itself.

### 4. (Optional) let the workflow upload

Play Console → **Setup → API access** → link a Google Cloud project → create a service account → give it access to the app (release permissions) → create a JSON key, and put it in `PLAY_SERVICE_ACCOUNT_JSON`.

## Releasing

- **By hand:** Actions → *Glass Run Play release* → Run workflow. Set the version name; tick *publish_to_play* to upload (track `internal`, status `draft` by default).
- **By tag:** `git tag run-v1.0 && git push origin run-v1.0` builds version `1.0` and uploads it to the internal track.

The bundle is always kept as the run's **GlassRun-aab** artifact. The version code is the run number, so it goes up with every run, as Play needs.

## If it breaks

- *Missing secret*: the first step says which.
- *Godot export failed*: the run's summary shows the Godot/Gradle messages. This workflow has not been run against Godot 4.7.2 before, so expect to fix a thing or two on the first run (SDK/NDK versions are at the top of the workflow).
- *Game behaves differently*: the game was made on Godot 4.3 and is built here with 4.7.2. Play the release build on a phone before promoting it past internal testing.
