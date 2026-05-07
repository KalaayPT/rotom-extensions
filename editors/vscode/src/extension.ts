import * as fs from 'fs';
import * as path from 'path';
import {
  ExtensionContext,
  workspace,
  window,
  commands,
  Uri,
  Position,
  Range,
  Location,
} from 'vscode';
import {
  LanguageClient,
  LanguageClientOptions,
  ServerOptions,
  TransportKind,
} from 'vscode-languageclient/node';

let client: LanguageClient | undefined;

function resolveServerPath(_context: ExtensionContext): string | undefined {
  const config = workspace.getConfiguration('rotom');
  const userPath = config.get<string>('lsp.path');
  if (userPath) {
    if (fs.existsSync(userPath)) {
      return userPath;
    }
    void window.showWarningMessage(
      `Configured rotom.lsp.path does not exist: ${userPath}`
    );
  }
  return 'rotom-lsp';
}

function resolveDebugServerPath(context: ExtensionContext): string | undefined {
  const config = workspace.getConfiguration('rotom');
  const userPath = config.get<string>('lsp.path');
  if (userPath && fs.existsSync(userPath)) {
    return userPath;
  }

  const bundled = path.join(context.extensionPath, 'bin', 'rotom-lsp');
  if (fs.existsSync(bundled)) {
    return bundled;
  }

  if (workspace.workspaceFolders && workspace.workspaceFolders.length > 0) {
    const wsRoot = workspace.workspaceFolders[0].uri.fsPath;

    const debugBuild = path.join(wsRoot, 'target', 'debug', 'rotom-lsp');
    if (fs.existsSync(debugBuild)) {
      return debugBuild;
    }

    const releaseBuild = path.join(wsRoot, 'target', 'release', 'rotom-lsp');
    if (fs.existsSync(releaseBuild)) {
      return releaseBuild;
    }
  }

  return 'rotom-lsp';
}

export function activate(context: ExtensionContext) {
  const serverCommand =
    context.extensionMode === 1 // DevelopmentExtensionMode
      ? resolveDebugServerPath(context)
      : resolveServerPath(context);

  if (!serverCommand) {
    void window.showErrorMessage(
      'Could not find rotom-lsp binary. Build it with `cargo build -p rotom-lsp` or set `rotom.lsp.path` in VS Code settings.'
    );
    return;
  }

  const serverOptions: ServerOptions = {
    run: { command: serverCommand, transport: TransportKind.stdio },
    debug: { command: serverCommand, transport: TransportKind.stdio },
  };

  const clientOptions: LanguageClientOptions = {
    documentSelector: [{ scheme: 'file', language: 'rotom' }],
    synchronize: {
      fileEvents: workspace.createFileSystemWatcher('**/*.rotom'),
    },
    middleware: {
      provideCodeLenses: (document, token, next) => {
        const result = next(document, token);
        if (!result) {
          return result;
        }
        return Promise.resolve(result).then((codeLenses) => {
          if (!codeLenses) {
            return codeLenses;
          }
          for (const lens of codeLenses) {
            if (lens.command && lens.command.command === 'editor.action.showReferences') {
              lens.command.command = 'rotom.showReferences';
            }
          }
          return codeLenses;
        });
      },
    },
  };

  client = new LanguageClient(
    'rotomLanguageServer',
    'Rotom Language Server',
    serverOptions,
    clientOptions
  );

  client.start();

  // Register a no-op command for non-actionable CodeLens clicks.
  context.subscriptions.push(
    commands.registerCommand('rotom.noop', () => {
      // Intentionally empty — CodeLens title is purely informational.
    })
  );

  // Register command to show references from a CodeLens click.
  context.subscriptions.push(
    commands.registerCommand(
      'rotom.showReferences',
      (
        uriStr: string,
        pos: { line: number; character: number },
        refs: Array<{
          uri: string;
          range: {
            start: { line: number; character: number };
            end: { line: number; character: number };
          };
        }>
      ) => {
        const uri = Uri.parse(uriStr);
        const position = new Position(pos.line, pos.character);
        const locations = refs.map(
          (ref) =>
            new Location(
              Uri.parse(ref.uri),
              new Range(
                new Position(ref.range.start.line, ref.range.start.character),
                new Position(ref.range.end.line, ref.range.end.character)
              )
            )
        );
        void commands.executeCommand(
          'editor.action.showReferences',
          uri,
          position,
          locations
        );
      }
    )
  );
}

export function deactivate(): Thenable<void> | undefined {
  return client?.stop();
}
