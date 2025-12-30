# free-csharp-vscode

The debugger included in the official C# extension is [proprietary](https://aka.ms/VSCode-DotNet-DbgLicense) and is licensed to only work with Microsoft versions of vscode. This extension replaces it with Samsung's [MIT-licensed](https://github.com/Samsung/netcoredbg/blob/master/LICENSE) alternative, [NetCoreDbg](https://github.com/Samsung/netcoredbg).

## Installation

### Get the VSIX file

- #### Prebuilt binaries
    - This extension is published at [Open VSX](https://open-vsx.org/extension/muhammad-sammy/csharp).

    - Download the vsix file from the [latest release](https://github.com/muhammadsammy/free-vscode-csharp/releases/latest) assests.

    - Download the extension vsix from [latest commit CI](https://github.com/muhammadsammy/free-vscode-csharp/actions/workflows/ci.yml).

- #### Build from source

    ```bash
    git clone https://github.com/muhammadsammy/free-vscode-csharp.git

    cd free-vscode-csharp

    # Make sure you have NodeJS (https://nodejs.org) installed.

    npm install

    npm run vscode:prepublish

    npx gulp 'vsix:release:neutral'

    ```

### Install the extension
Open the editor then run `Extensions: Install from VSIX` from the command pallete and select the `csharp-VERSION_NUMBER.vsix` file.
