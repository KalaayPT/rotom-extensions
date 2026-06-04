# Rotom for Zed

Zed does not currently let this extension associate JSON files by glob path from `config.toml`. Because Rotom text archives are regular `.json` files, archive CodeLens support is not enabled by default.

To enable reference counts for archive JSON, add this to your project or user Zed `settings.json`:

```json
{
  "file_types": {
    "Rotom Text Archive": ["**/textArchives/**", "**/res/text/**"]
  }
}
```

Do not attach `rotom-lsp` to Zed's built-in `JSON` language globally; that can interfere with normal JSON support.
