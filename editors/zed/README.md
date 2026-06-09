# Rotom for Zed

Not currently released through Zed yet, I will add a link once it is. If you still want to use it, you can clone/download the repo and go to `Extensions` -> `Install Dev Extension` and point it to this zed folder.

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
