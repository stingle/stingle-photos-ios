# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Maintaining this file (read first)

**Keep CLAUDE.md current as you work.** Whenever you make or discover something a future session would need to know, update the relevant section in the *same* change. That includes: a new build/run/verify step or gotcha; a dependency added or a version bump; a new cross-cutting pattern (e.g. the async bridges, the tab-bar accessory overlay); a renamed/added subsystem; or a non-obvious constraint you had to learn the hard way. Favor durable "big picture + gotchas that save time" over exhaustive file listings, and delete anything that becomes wrong. Treat this as part of done, not an afterthought.

## Overview

Stingle Photos is an end-to-end encrypted photo/video backup app for iOS. Media is encrypted client-side with libsodium before it ever leaves the device; the server only stores ciphertext. Most app logic lives in a shared framework (`StingleRoot`) consumed by both the main app and the share extension.

## Build, Run & Test

There is no Podfile or `Package.swift`; dependencies are resolved via Xcode-managed Swift Package Manager, pinned to released versions (Alamofire 5.12, keychain-swift 24, swift-sodium 0.11 — previously tracked `master`). Open `Stingle.xcodeproj` directly — there is no `.xcworkspace`.

Targets build with `IPHONEOS_DEPLOYMENT_TARGET = 16.0`, `SWIFT_VERSION = 5.10`, and `SWIFT_STRICT_CONCURRENCY = targeted` (clean). It builds against the current iOS SDK, so behavior follows the latest UIKit/AVFoundation even though the floor is iOS 16.

This repo requires the full Xcode toolchain. `xcodebuild` from the command line needs Xcode selected first (`sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`); the machine may default to CommandLineTools, which cannot build it.

### Deploying to verify (important gotcha)
A command-line `xcodebuild ... -derivedDataPath build` only proves the code **compiles** — it writes to `./build` and does **not** update what the user runs from Xcode. The user installs via **Xcode ⌘R**, which uses Xcode's *own* DerivedData. So "my build succeeded" ≠ "the app on the device changed." If reported changes don't appear (a recurring trap here): the build is stale — **Quit Xcode fully (⌘Q), reopen, Clean Build Folder (⇧⌘K), ⌘R.** Also confirm the running app's logs reflect your edits before chasing a "bug" — it's often just a stale build.

To run on a simulator yourself for verification:
```
xcodebuild -project Stingle.xcodeproj -scheme StingleDev -configuration Debug-Dev -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath build build
xcrun simctl install "iPhone 17" build/Build/Products/Debug-Dev-iphonesimulator/Stingle.app
xcrun simctl launch "iPhone 17" org.stingle.photos.dev   # dev bundle id
xcrun simctl io "iPhone 17" screenshot /tmp/shot.png
```
The simulator typically has a saved locked account (`test1@fenritz.com`); real login/sync/upload need credentials to runtime-verify, and the gallery's StoreKit plans need either App Store Connect or the local `Stingle/Resources/Config/Storage.storekit` (already wired into the `StingleDev` scheme).

Targets and schemes:
- **Stingle** (`com.apple.product-type.application`) — the main app. Schemes: `StingleDev`, `StingleProd`.
- **StingleShare** (`app-extension`) — share-sheet extension for importing media. Schemes: `StingleShareDev`, `StingleShareProd`.
- **StingleRoot** (`framework`) — shared core (crypto, DB, network, managers, models, data sources). Scheme: `StingleRoot`. Most non-UI code lives here.

Build configurations are split by environment: `Debug-Dev`, `Debug-Prod`, `Release-Dev`, `Release-Prod`. Dev vs. Prod is driven by xcconfig files in `Stingle/Resources/Config/` (`Development.xcconfig`, `Production.xcconfig`), which set bundle IDs, app name, API URL, and `BUILD_TYPE`. These values are read at runtime through `STEnvironment` (via Info.plist keys like `BUILD_TYPE`, `BASE_API_URL`, `APP_BUNDLE_ID`). Use the `*Dev` schemes for development against the dev backend.

There is no test target in this project; do not assume a `test` action exists.

## Architecture

### App / extension / framework split
- The main app and share extension share an **app group** (`group.<bundleId>.sharing`, see `STEnvironment.groupAppFileSharingBundleId`) for the encrypted file store, UserDefaults, and keychain. Both targets link `StingleRoot`.
- `STEnvironment.current.appIsExtension` distinguishes runtime context (detected by `.appex` bundle suffix). Be careful with code paths that differ between app and extension.

### STApplication — the composition root
`STApplication.shared` (in `StingleRoot/.../Services/Application/`) is the singleton that wires everything together and owns the long-lived services: `crypto`, `dataBase`, `syncManager`, `uploader`, `downloaderManager`, `autoImporter`, `appLockUnlocker`, and a per-user `fileSystem`. Logout/delete-account flows that must tear down all state live here (`logoutCashe`/`deleteAccountCashe`). When adding a new global service, register it here.

### Crypto (`Uitils/Crypto/STCrypto*.swift`)
libsodium-based (swift-sodium / Clibsodium). Implements Stingle's custom encrypted file format — magic bytes `SP` for media files and `SPK` for key files, chunked XChaCha20-Poly1305 (`__data__` context), versioned headers, and KDF difficulty levels. Keys derive from the user's password + a mnemonic backup phrase. `STCrypto` is split across extensions by concern: `+Header`, `+PrivateKey`, `+Album`, `+Common`, `+Additional`. Format constants (lengths, versions, file-type tags) live in `STCrypto.Constants`. Do not change format constants without understanding on-disk/wire compatibility.

### Persistence (`Manager/DB/`, `Models/DB/`)
Core Data, model name `StingleModel` (`.xcdatamodeld` in `StingleRoot/Resources/DBModel/`, with a migration mapping model present). `STDataBase` exposes typed **providers** — `userProvider`, `dbInfoProvider`, and `SyncProvider`s for gallery, albums, albumFiles, trash, and contacts. Each library entity has a Core Data class (`STCD*`) and a plain model (`STLibrary.*`) bridged via `CDConvertable`/`ICDSynchConvertable`. Sync diffs are modeled as `SyncInfo` sets (inserts/updates/upgrade/deletes).

### Sync
`STSyncManager` reconciles local Core Data with the server. The server is authoritative for the encrypted catalog; the client pulls deltas keyed off `STDBInfo` timestamps and applies them through the sync providers. Sync runs on unlock and is gated by `appLockUnlocker`.

### Network (`Network/`)
Layered: `Request/` (typed `IRequest` definitions per domain — Auth, Album, File, Sync, Upload, etc.) → `Dispatcher/` (`STNetworkDispatcher` + `STNetworkSession`, Alamofire-backed, with request encoding) → `Worker/` (high-level domain operations like `STSyncWorker`, `STUploadWorker`, `STContactWorker`) → `Response/` (`IResponse`/`STResponse`). `Operations/` (`STOperationManager` + queues) drives concurrent background work for uploads/downloads.

### Concurrency / async-await (cross-cutting)
The codebase was historically all completion-handler callbacks. The worker layer now also exposes `async throws` siblings (in `STWorker` and each worker) that **bridge the existing callback methods via `withCheckedThrowingContinuation`** — both styles coexist so migration is incremental. View models call the async API inside `Task { @MainActor [weak self] in ... }`, which preserves the original "callbacks fire on main" semantics (the operation layer doesn't hop threads; Alamofire's default queue is `.main`).

**Continuation hazard:** a bridged callback method *must* invoke success XOR failure exactly once. A path that fires both ⇒ `continuation.resume` twice ⇒ **crash**; a path that fires neither ⇒ leaked continuation/hang. The operation layer nils its closures in `setFinished` (so post-success cancel is safe), and `STOperation.setCancel` fires a `.cancelled` failure on ready-cancel so awaiters don't leak. When you bridge or edit a callback worker method, verify every branch resolves exactly once.

### File transfer & storage
- `Manager/FileUploader/` — `STFileUploader` + per-file `STFileUploaderOperation`; encrypts and uploads.
- `Manager/FileDownloader/` — `STDownloaderManager` with a `Cache/` layer for decrypted thumbnails/originals.
- `Manager/FileSystem/STFileSystem` — per-user on-disk layout under the user's `homeFolder`; handles migration, logout cleanup, free-disk checks (`STConstants.minFreeDiskUnits`).
- `Importer/` — `STImporter` and `STFileAutoImporter` (`AutoImporter`) ingest from the photo library / share extension, including background auto-import.

### UI (`Stingle/`)
- UIKit, organized by feature under `Stingle/Scense/` (Gallery, Home, Welcome, Settings, Shear/share, ImageEditor). Storyboards + xibs are used alongside code.
- Screens follow an **MVVM** convention: `ST<Feature>VC` (view controller) paired with `ST<Feature>VM` (view model), e.g. `STGalleryVC` / `STGalleryVM`.
- Collection-based screens bind to Core Data through `STViewDataSource` / `STCollectionViewDataSource` (in `StingleRoot/.../DataSource/`), which wrap `NSDiffableDataSource` snapshots fed by the DB providers. Reusable views/controls live in `Stingle/Common/UI/`.

### App lock
`Manager/AppLockUnlocker/` + `STBiometricAuthServices` implement passcode/biometric locking. Locking pauses sync and clears in-memory key material; unlocking re-triggers sync and DB reload (`STApplication.appDidLocked`). The biometric credential is an encrypted password in app-group UserDefaults with its key in the keychain (`STKeyChainService`). Two non-obvious rules learned here: (1) that keychain item must use `accessibleAfterFirstUnlockThisDeviceOnly` (not the `WhenUnlocked` default) or Face ID fails after a long device lock and falls back to the password dialog; (2) decide whether to *offer* biometrics from `isBiometricConfigured` (UserDefaults-backed, reliable) rather than a read-and-validate that can fail transiently, and defer the auto-attempt until `protectedDataDidBecomeAvailable`.

### Video playback (`Uitils/Player/`)
`STPlayer` wraps `AVPlayer`; `STAssetResourceLoader` is an `AVAssetResourceLoaderDelegate` that decrypts the chunked stream on the fly (local file or network range-request reader). Each chunk decrypts independently (per-chunk key derived from the chunk number), so the asset **does** support random access — `contentInformationRequest.isByteRangeAccessSupported` must be `true` for scrubbing to work at all. Seeking is coalesced ("chase time") with a tolerance so a drag doesn't flood `AVPlayer`. Video viewers (`Items/Video/STVideoViewerVC`) autoplay when they become the current page (`fileViewer(activateContent:)` from `STFileViewerVC.didChangeFileViewer`) and pause off-screen.

### Tab-bar action accessory (UI gotcha)
The custom `STTabBar` shows an action bar (`STFilesActionTabBarAccessoryView`) for selection mode and the file viewer via its `accessoryView` setter. It is attached as a **sibling on top of the tab bar with the tab bar's `isUserInteractionEnabled` disabled** — *not* as a child (a child gets its taps stolen by the tab bar's nested, re-created buttons). Because it's a sibling, `tabBar.alpha` no longer hides it, so anything that hides the bar (e.g. the viewer's full-screen mode) must fade `accessoryView` explicitly.

## Conventions

- Type prefix `ST` for app types, `STCD` for Core Data managed objects, `I`-prefixed names for protocols (`IRequest`, `IResponse`, `ICDConvertable`).
- Shared, testable, non-UI logic belongs in **StingleRoot** (so the share extension can use it). UI and scenes belong in **Stingle**. The `Stingle/Resources/RootClasses/` folder holds app-target entry points (`AppDelegate`, `SceneDelegate`).
- Note the directory spelling quirks that already exist in the tree: `Scense` (scenes) and `Uitils` (utils). Match existing paths rather than "correcting" them.
- Backend base URL is overridable at runtime via `STApplication.setAppServer(url:)` (stored in the app-group UserDefaults), supporting self-hosted servers.

## Security

This is a security-sensitive, end-to-end-encrypted product. Vulnerabilities are reported privately (see `SECURITY.md`, security@stingle.org). Treat the crypto file format, key management, and the app-group keychain/storage as high-risk surfaces.
