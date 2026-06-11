# Third-Party Notices

This repository vendors code from `ringo-fm-bridge` in order to build the MoonBit SDK without a
checkout-level dependency on a sibling repository.

## Vendored component

- Component: `vendor/foundation-models-c`
- Source project: `ringo-fm-bridge`
- Upstream path: `Sources/FoundationModelsCBindings`
- Upstream license text: `vendor/foundation-models-c/LICENSE.md`

## Copyright and modifications

The vendored `foundation-models-c` sources retain their upstream
copyright headers.

This checkout includes local modifications to the vendored bindings to support
the structured streaming functions consumed by the MoonBit FFI:

- `FMLanguageModelSessionStreamResponseWithSchema`
- `FMLanguageModelSessionStructuredResponseStreamIterate`

No generated build artifacts from the vendored project are tracked in git.
