PowerShell-based automation for building, validating, and documenting Windows kiosk images, including system manifests and automated tests.

> This project uses an unactivated Windows 11 Pro VM for lab and automation purposes, consistent with enterprise image build workflows.

## Build Artifacts
Each run produces:
- `build/build.log` — timestamped actions performed during image build
- `build/manifest.json` — JSON manifest of system inventory and build outcome

## Image Build
The `build/` directory contains the PowerShell-based image build orchestrator
and sample artifacts produced during a Windows kiosk image build, including
timestamped logs and a JSON system manifest.
