use zed_extension_api::{Command, Extension, LanguageServerId, Result, Worktree};

struct RotomExtension;

impl Extension for RotomExtension {
    fn new() -> Self {
        Self
    }

    fn language_server_command(
        &mut self,
        _language_server_id: &LanguageServerId,
        _worktree: &Worktree,
    ) -> Result<Command> {
        Ok(Command {
            command: "rotom-lsp".to_string(),
            args: vec![],
            env: vec![],
        })
    }
}

zed_extension_api::register_extension!(RotomExtension);
