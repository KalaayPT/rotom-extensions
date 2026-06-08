import * as fs from 'fs';
import * as path from 'path';
import { execSync } from 'child_process';
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

function resolveServerPath(context: ExtensionContext): string | null {
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

  const executable = process.platform === 'win32' ? 'rotom-lsp.exe' : 'rotom-lsp';
  const bundled = path.join(context.extensionPath, 'bin', executable);
  if (fs.existsSync(bundled)) {
    return bundled;
  }

  for (const folder of workspace.workspaceFolders ?? []) {
    const wsRoot = folder.uri.fsPath;
    for (const profile of ['debug', 'release']) {
      const candidate = path.join(wsRoot, 'target', profile, executable);
      if (fs.existsSync(candidate)) {
        return candidate;
      }
    }
  }

  // VS Code may not inherit the user's shell PATH (common with fish/nix).
  // Ask the login shell as a last resort.
  try {
    const shell = process.env.SHELL ?? '/bin/sh';
    const resolved = execSync(`${shell} -lc "which ${executable}"`, { encoding: 'utf8' }).trim();
    if (resolved && fs.existsSync(resolved)) {
      return resolved;
    }
  } catch { /* not found via shell either */ }

  return null;
}

export function activate(context: ExtensionContext) {
  const serverCommand = resolveServerPath(context);
  if (!serverCommand) {
    return;
  }

  const serverOptions: ServerOptions = {
    run: { command: serverCommand, transport: TransportKind.stdio },
    debug: { command: serverCommand, transport: TransportKind.stdio },
  };

  const clientOptions: LanguageClientOptions = {
    documentSelector: [
      { scheme: 'file', language: 'rotom' },
      { scheme: 'file', language: 'json', pattern: '**/textArchives/**' },
      { scheme: 'file', language: 'json', pattern: '**/res/text/**' },
    ],
    synchronize: {
      fileEvents: [
        workspace.createFileSystemWatcher('**/*.rotom'),
        workspace.createFileSystemWatcher('**/textArchives/**/*.json'),
        workspace.createFileSystemWatcher('**/res/text/**/*.json'),
      ],
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
