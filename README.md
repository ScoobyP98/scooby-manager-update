# Scooby Manager updates

Canonical update manifest: https://scoobyp98.github.io/scooby-manager-update/scooby-manager/version.json

The repository homepage redirects to https://scoobymenu.cc/. Release manifests
and downloads live under `scooby-manager/`; packages and matching relink archives
live under `scooby-manager/packages/`.

The root `version.json` remains an identical compatibility mirror because
already built package01.18 checks that URL. Both manifests point to the same
nested package download. Keep this mirror when publishing future releases.

Enable GitHub Pages in this repository's **Settings → Pages**, using **Deploy
from a branch → main → /(root)**. The `.nojekyll` file keeps the JSON and package
downloads unchanged. The app checks its configured manifest address over HTTPS.

## Publish a release

1. Run `build.bat` with the `scooby-ps4` checkout next to this repository. The build
   prompts for the app and PS4 package versions and writes the PKG under
   `Apps/Scooby-Manager/out` in the source checkout. Set `SCOOBY_MANAGER_ROOT`
   to the app folder if it is elsewhere. Use `build.bat -NonInteractive` to keep
   the current versions without a prompt.
2. Run `Publish-Release.ps1` from this repository after the build:

   ```powershell
   pwsh -File .\Publish-Release.ps1 -AppRoot ..\scooby-ps4\Apps\Scooby-Manager -Notes 'What changed'
   ```

3. Commit and push the generated manifest, package and matching relink archive.
   Wait for GitHub Pages to finish publishing before announcing the update.

The publisher uses the validated build receipt and checks the actual PKG title,
content ID, version, complete byte count and SHA-256. Do not change the version
number in the published JSON without building the corresponding package.
It copies and hash-checks both immutable artifacts first, then atomically writes
`scooby-manager/version.json` last, followed by its byte-identical root mirror.
A failed copy leaves both existing manifests unchanged.

`-ForceUpdate` removes the **Later** option for that offered release.
`-MinimumVersion 1.1.0` requires an update for older app versions. These values
never bypass the package checks or automatically uninstall the current app.
An unavailable feed does not lock out offline use.

The manifest fields are `schema`, `version`, `pkg_version`, `title_id`,
`content_id`, `package_url`, `sha256`, `bytes`, `force_update`,
`minimum_version`, and optional `notes`.

The matching `*-relink.zip` includes the LGPL media library sources, notices,
app objects and relinking instructions for the distributed package.
