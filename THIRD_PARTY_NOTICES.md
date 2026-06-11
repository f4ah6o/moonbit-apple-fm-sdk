# Third-Party Notices

This repository vendors code from `python-apple-fm-sdk` and its
`foundation-models-c` subdirectory in order to build the MoonBit SDK without a
checkout-level dependency on a sibling repository.

## Vendored component

- Component: `vendor/foundation-models-c`
- Source project: `python-apple-fm-sdk`
- Upstream path: `foundation-models-c`
- Upstream license text: `third_party/licenses/python-apple-fm-sdk-LICENSE.md`

## Copyright and modifications

The vendored `foundation-models-c` sources retain their original Apple
copyright headers.

This checkout includes local modifications to the vendored bindings to support
the structured streaming functions consumed by the MoonBit FFI:

- `FMLanguageModelSessionStreamResponseWithSchema`
- `FMLanguageModelSessionStructuredResponseStreamIterate`

No generated build artifacts from the vendored project are tracked in git.
