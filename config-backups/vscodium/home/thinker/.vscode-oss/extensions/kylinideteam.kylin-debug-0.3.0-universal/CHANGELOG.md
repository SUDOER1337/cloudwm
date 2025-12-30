# 0.3.0

- 更新 min 版本号，以与废弃的 KylinIdeTeam.debug 插件区分

# 0.2.10

- 更改插件描述信息
- 解决 tslint 检查报 Use undefined instead of null 的问题
- 删除冗余代码
- openvsx 插件市场和 vscode 插件市场插件名称统一为 kylin-debug

# 0.2.9

- 添加中文翻译
- 使用 esbuild 打包扩展

# 0.2.8
- 解决std::deque<std::deque<int>>和std::mutex变量显示不正常问题
- 解决 std::regex 解析失败问题
- 忽略不必要的hover 错误
- 添加组合 launch 配置，同时启动 debug server 和扩展
- 添加第三方通知文件，包含版权和许可信息
- 修复 ssh 下 x11forward 不起作用的问题

# 0.2.6
- feat: windows gdb path set;
- feat: windows qt support;

# 0.2.5
- feat: support stl variable, such as vector、deque、map、set、unordered_set、bitset and so on;
- feat: merge win32 gdb check from upstream github;
- fix other parse error, such as repeats [num] times variable, get() variable;
- add two unit tests.
# 0.2.4  
- feat: fix get variable fail of static obj
- feat: fix parse variable fail of "No data fields" in QT
- feat: ignore "data-evaluate-expression" and "No symbol" error
- feat: fix get vector and tuple variable fail issue
- feat: fix get variable in main stack

# 0.2.3
- feat: set the default input and output of the program to the IDE's terminal;

# 0.2.2
- modified the README and LICENSE
- reduce the package size
# 0.2.1  
- add log message function;  
- solve the problem of parsing two-dimensional arrays failure;  

# 0.2.0  
- support qt variable;  
- fix the problem of step out fail from main();  

# 0.1.9  
- fix the problem of exception prompt when clicking step out in the function;  
- fix the problem of freezing when clicking step out in the for loop of the main function;  

# 0.1.8
- resolve the issue of being unable to parse other properties when a struct contains a character array;
- fix set variable fail issue;

# 0.1.7
- fix set variable fail issue;
- fix hitCount breakpoint does work bugs;

# 0.1.6
- modify readme;  

# 0.1.5
- Changed the icon and plugin name to avoid confusion with native-debug;  

# 0.1.4
- Set suppressFailure to prevent debugging from exiting due to exceptions;  

# 0.1.3
- Disabled asynchronous queries;
- Disabled warnings for failed queries;  

# 0.1.2
- Modified depends dependencies and added debugging terminal input functionality.  

# 0.1.1
- Temporarily disabled reverse debugging on x86 and Loongson platforms due to bugs in gdb.  

# 0.1.0
- This version is based on native-debug 0.26.0
- Fixed issues with viewing/setting registers;
- Fixed issues with setting variable values;
- Added assembly debugging functionality;
- Added reverse debugging interface buttons;
 
# 0.26.0

* vscode dependency was increased from 1.28 to 1.55 along with the debug-adapter protocol to get rid of some outdated dependencies (@GitMensch)
* SSH2 module updated from deprecated 0.8.9 to current 1.6.0 (@GitMensch),
  allowing connections with more modern key algorithms, improved error handling (including user messages passed on) and other improvements.  
  See [SSH2 Update Notices](https://github.com/mscdex/ssh2/issues/935) for more details.
* Path Substitutions working with attach+ssh configuration [#293](https://github.com/WebFreak001/code-debug/issues/293) (@brownts)
* Path Substitutions working with LLDB [#295](https://github.com/WebFreak001/code-debug/issues/295) (@brownts)
* Path Substitutions working with Windows-Style paths [#294](https://github.com/WebFreak001/code-debug/issues/294) (@brownts)
* Breakpoints may be deleted when not recognized correctly [#259](https://github.com/WebFreak001/code-debug/issues/259) fixing [#230](https://github.com/WebFreak001/code-debug/issues/230) (@kvinwang)
* New `stopAtConnect` configuration [#299](https://github.com/WebFreak001/code-debug/issues/299), [#302](https://github.com/WebFreak001/code-debug/issues/302) (@brownts)
* New `stopAtEntry` configuration to run debugger to application's entry point [#306](https://github.com/WebFreak001/code-debug/issues/306) (@brownts)
* New `ssh.sourceFileMap` configuration to allow multiple substitutions between local and ssh-remote and separate ssh working directory [#298](https://github.com/WebFreak001/code-debug/issues/298) (@GitMensch)
* fix path translation for SSH to Win32 and for extended-remote without executable (attach to process) [#323](https://github.com/WebFreak001/code-debug/issues/323) (@GitMensch)
* fix for race conditions on startup where breakpoints were not hit [#304](https://github.com/WebFreak001/code-debug/issues/304) (@brownts)
* prevent "Not implemented stop reason (assuming exception)" in many cases [#316](https://github.com/WebFreak001/code-debug/issues/316) (@GitMensch),
  initial recognition of watchpoints
* fix additional race conditions with setting breakpoints [#313](https://github.com/WebFreak001/code-debug/issues/313) (@brownts)
* fix stack frame expansion in editor via use of the `startFrame` parameter [#312](https://github.com/WebFreak001/code-debug/issues/312) (@brownts)
* allow specification of port/x11port via variable (as numeric string) [#265](https://github.com/WebFreak001/code-debug/issues/265) (@GitMensch)
* Extra debugger arguments now work in all configurations [#316](https://github.com/WebFreak001/code-debug/issues/316), [#338](https://github.com/WebFreak001/code-debug/issues/338) fixing [#206](https://github.com/WebFreak001/code-debug/issues/206) (@GitMensch, @brownts)
* Attaching to local PID now performs initialization prior to attaching [#341](https://github.com/WebFreak001/code-debug/issues/341) fixing [#329](https://github.com/WebFreak001/code-debug/issues/329) (@brownts)

# 0.25.1

* Remove the need for extra trust for debugging workspaces per guidance "for debug extensions" as noted in the [Workspace Trust Extension Guide](https://github.com/microsoft/vscode/issues/120251#issuecomment-825832603) (@GitMensch)
* Fix simple value formatting list parsing with empty string as first argument (@nomtats)
* don't abort if `set target-async` or `cd` fails in attach (brings in line with existing behavior from launch)

# 0.25.0

(released May 2020)

* Add support for path substitutions (`{"fromPath": "toPath"}`) for GDB and LLDB (@karljs)
* Support up to 65535 threads instead of 256 threads (@ColdenCullen)
* Improve thread names on embedded GDB, makes not all threads always have the same name (with @anshulrouthu)

# 0.24.0

* Added zig as supported language.
* Fix example Debug Microcontroller template
* Implement "Jump to Cursor" to skip instructions
* Fix memory dump for theia

# 0.23.1

Fixes:
* Breakpoints in SSH in other working directories properly resolved
* Undefined/null paths don't crash stacktrace
* Added kotlin to language list

# 0.23.0

(released March 2019)

* Normalize file paths in stack trace (fixes duplicate opening of files)
* New Examine memory Location UI
* Breakpoints in SSH on windows fixed (@HaronK)
* Project code improvements (@simark)
* Initial configurations contain valueFormatting now (@Yanpas)

# 0.22.0

(released March 2018)

* Support for using SSH agent
* Support multi-threading (@LeszekSwirski)
* Fixed GDB expansion logic with floats (Marcel Ball)
* Fixed attach to PID template (@gentoo90)

# 0.21.0 / 0.21.1 / 0.21.2

(0.21.2 is pushed without changes to hopefully fix vscode installation)

* Several fixes to variable pretty printers by @gentoo90
* Enabled breakpoints for crystal (@faustinoaq)

# 0.20.0

Added support for pretty printers in variable list (by @gentoo90), enable
with `"valuesFormatting": "prettyPrinters"` if you have a pretty printer
to get potentially improved display of variables.
