## v0.4.0

Improvements:

* 内置最新的 clangd 语言服务器(linux-x64, linux-arm64)
* 有条件地初始化 QMakeTools
* 修复 clangd 路径为空时的提示信息
* 去除插件端语义高亮实现
* 添加设置项 `clangd.useBuiltInClangdIfAvailable`,用于控制是否使用内置的 clangd 语言服务器

## v0.3.1

Improvements:

* 尝试从插件 `KylinIdeTeam.qmake-tools` 获取编译数据库目录。
* 和 vscode-clangd 0.1.34 同步更新。

Bug Fixes:

* 修复 showAST 字符串错误

## v0.3.0

* 从 CMake Tools 获取编译数据库目录

## v0.2.25

* 从上游同步更新
* 更新 .clang-format 配置，给予 LLVM 格式规范
* openvsx 插件市场的插件 name 更改为 kylin-debug, 和 vscode 插件市场保持一致

## v0.2.24

* clangd 版本低于11 时，使用 compile_flags.txt

## v0.2.23

* 添加 redhat.vscode-yaml 插件依赖，用于支持配置文件自动补全，校验
* 禁用 clangd 启动时的 shell 选项

## v0.2.22

* 添加命令可以在工作区创建 .clangd, .clang-tidy, .clang-format 文件

## v0.2.21

* 国际化功能不再引用已经弃用的 process.env.VSCODE_NLS_CONFIG
* 移除 .clangd 文件中的 Compiler 配置
* 插件激活时，默认不创建.clangd, .clang-tidy, .clang-format 文件
* 添加对 .clangd 和 .clang-tidy 文件变化的监控，并在更改时提示重启 clangd 服务器
* Allow "clangd.path" to point to a shell script
* 在 package.json 中将 .clangd、.clang-format 和 .clang-tidy 文件指定为 yaml 格式

## v0.2.20

* 打开 .clangd, .clang-tidy, .clang-format 文件时，将语言模式设置为 yaml
* 添加对 .clangd, .clang-tidy, .clang-format 文件的 yaml schema 校验支持，使编辑这些文件时可以自动补全
* 添加 redhat.vscode-yaml 插件依赖，用于支持配置文件自动补全，校验
* 添加配置项以控制是否在插件激活时创建 .clangd, .clang-tidy, .clang-format 文件
* 弃用设置项 `clangd.additionalIncludePaths`

## v0.2.19

* 将 所有 clangd 命令的类别更改为 Kylin Clangd
* 修复 fs.statSync 可能导致的崩溃
* 更新部分翻译字符串

## v0.2.18

* 向工作区中添加 .clangd, .clang-tidy 文件

## v0.2.17

* 集成上游更新
* 更新许可证，并添加 ThirdPartyNotices.txt 文件
* 输出通道重命名为 Kylin Clangd
* 将设置项中的 onConfigChanged 选项重命名为更合适的 onCompileDatabaseChanged
* 修复 config.ts 中的类型错误

## 0.2.14

* 修复首次使用，shfit+f1 快捷键不起作用的问题
* 添加 includeInsertion 配置项目，用于控制是否自动添加头文件

## 0.2.13

* 将 Shift + F1 的功能从 Qt Support 插件移动至本插件

## 0.2.12

* 添加命令 symbolInfo 可以返回光标处符号信息
* 修复当 clangd 的路径中带有空格时，插件激活失败的问题
* 打包时不忽略 LICENSE 文件

## 0.2.10

* 删除不必要的文件
* 当工作区中存在 clangd 配置文件的时候，直接使用，不再提示

## 0.2.8

* 增加readme中中文描述

## 0.2.7

* 修复shift-f1跳转提示安装插件入口

## 0.2.6

* 增加获取符号定位功能，以辅助实现shift-f1帮助文档跳转功能

## 0.2.5

* 更改displayName、readme等信息

## 0.2.4

* 修复clangd未安装提示

## 0.2.3

* 修改depends.json文件

## 0.2.2

* 增加设置默认-fPIC,设置库代码与位置无关
* 修改depends.json文件
* 添加检测clangd版本，并低于9时弹出警告信息


## 0.2.1

* 增加语义高亮
* 增加QT头文件路径，支持QT补全
* 添加其他头文件路径，支持其他头文件补全 
* 修复依赖安装入口

## 0.1.0

* 基于llvm-vs-code-extensions.vscode-clangd插件的commit log:c0375489682e331ad06c25b60df86e4f102a6407更改(高于0.1.23一个提交:修改CHANGELOG.md)
* 增加本地化语言，修改依赖提示
* 增加depends.json文件用于插件依赖管理
* 增加插件国内下载链接
