import * as path from 'path';
import { ExtensionContext, workspace } from 'vscode';
import {
  LanguageClient,
  LanguageClientOptions,
  ServerOptions,
  TransportKind,
} from 'vscode-languageclient/node';

let client: LanguageClient | undefined;

export function activate(context: ExtensionContext) {
  // TODO: locate rotom-lsp binary (bundled or on PATH)
  const serverCommand = 'rotom-lsp';

  const serverOptions: ServerOptions = {
    run: { command: serverCommand, transport: TransportKind.stdio },
    debug: { command: serverCommand, transport: TransportKind.stdio },
  };

  const clientOptions: LanguageClientOptions = {
    documentSelector: [{ scheme: 'file', language: 'rotom' }],
    synchronize: {
      fileEvents: workspace.createFileSystemWatcher('**/*.rotom'),
    },
  };

  client = new LanguageClient(
    'rotomLanguageServer',
    'Rotom Language Server',
    serverOptions,
    clientOptions
  );

  client.start();
}

export function deactivate(): Thenable<void> | undefined {
  return client?.stop();
}
