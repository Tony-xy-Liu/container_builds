# redroid — Android-in-Docker with Google Play (GApps)

A GPU-accelerated Android container used as a **real Google Play Services host**.
Primary consumer: `virtual-auth` — it runs the genuine Duo Mobile app here so the
app receives a real instant FCM push (the "doorbell"), which then pokes the
virtual-auth daemon to approve. Secondary future use: game dailies (e.g. Arknights
via MAA).

Unlike the other recipes here, this is not a conda/quay image: it overlays Google
Play onto the official upstream `redroid/redroid` base via
[`ayasa520/redroid-script`](https://github.com/ayasa520/redroid-script), which
injects **MindTheGapps** into the image with a plain `COPY` (no AOSP rebuild).

## Why Android 12 + MindTheGapps

Current Duo Mobile (4.115) has `minSdk 31` → needs **Android 12**. The common
`redroid-script` GApps path (OpenGApps) tops out at Android 11, so we use the
**MindTheGapps** path (`-mtg`), which the upstream script supports for 12/13/14.
We build `12.0.0_64only` (Duo ships x86_64 native libs, so no ARM translation /
libndk is needed; 64-only is lighter).

## Build (on the docker host, e.g. mira)

```bash
./build.sh                 # defaults to 12.0.0_64only + MindTheGapps
./build.sh 13.0.0          # other versions the script supports
```

Produces image `redroid/redroid:<ver>_mindthegapps`.

Host prerequisites: Docker; `python3` with `requests` + `tqdm`
(`sudo apt install python3-requests python3-tqdm`); the `binder_linux` kernel
module; an Intel/AMD render node at `/dev/dri/renderD128` for GPU accel.

## Run

```bash
./run.sh                   # privileged container, binderfs, GPU host accel, ADB:5555
adb connect localhost:5555
```

Data persists in `~/redroid/data`. First boot: sign in to Google in Play (needs UI
— use scrcpy over an SSH tunnel). If Play reports "device not certified", register
the GSF ID at <https://google.com/android/uncertified>.

## Gotchas

- **Play Integrity:** redroid is an emulator and fails hardware-backed
  attestation. Whether Duo will enroll + receive FCM here is the open feasibility
  question (Gate 1) the virtual-auth spike is testing.
- **Magisk + PlayIntegrityFix do NOT help on x86_64 redroid.** PIF (v4.6-inject-s)
  ships only `zygisk/arm64-v8a.so` + `armeabi-v7a.so` — **no x86_64 lib**, so its
  Zygisk injection can't load into the x86_64 GMS process (Houdini translates apps,
  not injected system libs). Only PIF's build-prop spoof could run → caps at BASIC
  integrity. Magisk-in-container also fights back: `--install-module` returns
  "Incomplete Magisk install" and `/data/adb` is permission-denied even to `su 0`
  (Magisk Delta self-hiding). DEVICE integrity would need TrickyStore + a live
  keybox (an arms race); STRONG is impossible (no TEE). Conclusion: don't chase the
  integrity arms race on this x86_64 host — measure whether Duo's push even needs it
  (FCM *delivery* ≠ App Check) with a real enrollment first.
- Verify GL accel uses the render node (`dumpsys SurfaceFlinger | grep -i gles`
  should show the Intel/Mesa renderer, not swiftshader) or the UI crawls.
- A healthy GMS (Play Store loads, account adds) must be confirmed before touching
  Duo — a broken GApps install silently breaks FCM (redroid issue #240).
- Never bake the Duo APK, Google creds, or any enrollment into the image — those
  live only in the persisted `/data`.
