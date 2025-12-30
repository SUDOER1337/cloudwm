# Project-Notes

## Todo
<!-- TODO -->
Adjust tree view button positions (Delete, Preview and Rename)

<!-- TODO -->
Add right click menu commands for rename, edit, preview and delete

Add this to Readme.MD [Features] after snippets are added.
- Snippets support for `Tags`. [See Documentaion](https://code.visualstudio.com/docs/editor/userdefinedsnippets) for details.

## Allow Quick Suggestions in comments
add to settings.json
```
  "editor.quickSuggestions": {
    "comments": true
  },
```

## Hide local notes folder
Type “files:exclude” into the search field then head to the “Files: Exclude” section that appears as the search result. (If you want to make changes for just a single project, select the “Workspace” tab instead of the “User” tab).

Click on the “Add Pattern” button and declare the file types or folders you want to hide. For example: **.lock, **.txt, node_modules, etc.

## textMateRules
The solution was to remove the textMateRules section from my settings.json file. With it in there my package.json files textMateRules were not being implemented. This means I will need to set my tbscript colors in the package.json file as well. My Kickass colors will have to be added to Paul Hockers extension.

    "textMateRules": [
      {
        "scope": "keyword",
        "settings": {
          "foreground": "#e2df19"
        }
      },
      {
        "scope": "keyword.operator",
        "settings": {
          "foreground": "#ca5734"
        }
      },
      {
        "scope": "keyword.control",
        "settings": {
          "foreground": "#fd9013"
        }
      },
      {
        "scope": "keyword.other.macros",
        "settings": {
          "foreground": "#e49287"
        }
      },
      {
        "scope": "keyword.other.macrosdebug",
        "settings": {
          "foreground": "#f16653"
        }
      },
      {
        "scope": "keyword.other.pseudocommands",
        "settings": {
          "foreground": "#f5ad41"
        }
      },
      {
        "scope": "keyword.tbscript",
        "settings": {
          "foreground": "#d5ec80"
        }
      },
      {
        "scope": "keyword.system.tbscript",
        "settings": {
          "foreground": "#2de7d8"
        }
      },
      {
        "scope": "keyword.strings.tbscript",
        "settings": {
          "foreground": "#afa1e9"
        }
      },
      {
        "scope": "keyword.terminal.tbscript",
        "settings": {
          "foreground": "#627cd3"
        }
      },
      {
        "scope": "keyword.disk.tbscript",
        "settings": {
          "foreground": "#b56df8"
        }
      },
      {
        "scope": "keyword.other.gui.tbscript",
        "settings": {
          "foreground": "#bf3be7"
        }
      },
      {
        "scope": "keyword.other.members.tbscript",
        "settings": {
          "foreground": "#18a3ff"
        }
      },
      {
        "scope": "constant.character.escaped.dbl.tbscript",
        "settings": {
          "foreground": "#f57df5"
        }
      },
      {
        "scope": "constant.character.escaped.single.tbscript",
        "settings": {
          "foreground": "#eb73eb"
        }
      },
      {
        "scope": "constant.numeric.tbscript",
        "settings": {
          "foreground": "#1ccbd1"
        }
      },
      {
        "scope": "constant.numeric.hexidecimal.tbscript",
        "settings": {
          "foreground": "#3ee2ab"
        }
      }
    ]


```
    // This works
    var config = vscode.workspace.getConfiguration("editor");
    config.update("fontSize", 24, 1);

    // This works but it removes all other existing entries under tokenColorCustomizations
    //    var editorConfig = vscode.workspace.getConfiguration("editor");
    var textMateRulesLength = vscode.workspace.getConfiguration("editor").get('tokenColorCustomizations.textMateRules').length;
    var textMateRules = vscode.workspace.getConfiguration('editor').get('tokenColorCustomizations.textMateRules');
    textMateRules[textMateRulesLength] = { 'scope': 'jjj', 'settings': { 'foreground': '#ffffff', 'fontStyle': 'bold' } };
    textMateRules[textMateRulesLength + 1] = { 'scope': 'kkk', 'settings': { 'foreground': '#010101', 'fontStyle': '' } };
    vscode.workspace.getConfiguration('editor').update('tokenColorCustomizations', { textMateRules }, 1);

    console.log(textMateRules);
```
