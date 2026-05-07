use zed_extension_api::{self as zed, Command, Extension, LanguageServerId, Result, Worktree};

struct RotomExtension;

impl Extension for RotomExtension {
    fn new() -> Self {
        Self
    }

    fn language_server_command(
        &mut self,
        _language_server_id: &LanguageServerId,
        worktree: &Worktree,
    ) -> Result<Command> {
        let command = worktree
            .which("rotom-lsp")
            .ok_or_else(|| "rotom-lsp not found on PATH".to_string())?;

        Ok(Command {
            command,
            args: vec![],
            env: vec![],
        })
    }
}

zed::register_extension!(RotomExtension);
