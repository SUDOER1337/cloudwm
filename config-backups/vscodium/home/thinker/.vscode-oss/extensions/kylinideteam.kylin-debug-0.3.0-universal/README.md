# Kylin Native Debug
[中文描述](#kylin-native-debug-插件)

Kylin Native Debug extension is fork of code-debug(Native Debug), mainly for Linux kind OS and GDB debug. Although this extension can be used for LLDB, we did little test on LLDB. Modifications to Native Debug:
  - Fix can not input issue in linux;
  - Fix issues with viewing/setting registers;
  - Fix issues with setting variable values;
  - Add assembly debugging functionality;
  - Add reverse debugging interface buttons;
  - Add logging message functionality;
  - Fix issue with parsing two-dimensional arrays;
  - Fix issue with parsing QT variable;
  - Better support for c++, such stl vector, set, etc.;
  - Fix the breakpoint bug related to hit count


### Usage

![Image with red circle around a gear and a red arrow pointing at GDB and LLDB](https://github.com/WebFreak001/code-debug/raw/HEAD/images/tutorial1.png)

Or if you already have an existing debugger in your project setup you can click "Create Configuration" or use the auto completion instead:

![Visual studio code debugger launch.json auto completion showing alternative way to create debuggers](https://github.com/WebFreak001/code-debug/raw/HEAD/images/tutorial1-alt.png)

Open your project and click the debug button in your sidebar. At the top right press
the little gear icon and select GDB or LLDB. It will automatically generate the configuration
you need.

*Note: for LLDB you need to have `lldb-mi` in your PATH*

If you are on OS X you can add `lldb-mi` to your path using
`ln -s /Applications/Xcode.app/Contents/Developer/usr/bin/lldb-mi /usr/local/bin/lldb-mi` if you have Xcode.

![Default config with a red circle around the target](https://github.com/WebFreak001/code-debug/raw/HEAD/images/tutorial2.png)

Now you need to change `target` to the application you want to debug relative
to the cwd. (Which is the workspace root by default)

Additionally you can set `terminal` if you want to run the program in a separate terminal with
support for input. On Windows set it to an empty string (`""`) to enable this feature. On linux
set it to an empty string (`""`) to use the default terminal emulator specified with `x-terminal-emulator`
or specify a custom one. Note that it must support the `-e` argument.

Before debugging you need to compile your application first, then you can run it using
the green start button in the debug sidebar. For this you could use the `preLaunchTask`
argument vscode allows you to do. Debugging multithreaded applications is currently not
implemented. Adding breakpoints while the program runs will not interrupt it immediately.
For that you need to pause & resume the program once first. However adding breakpoints
while its paused works as expected.

Extending variables is very limited as it does not support child values of variables.
Watching expressions works partially but the result does not get properly parsed and
it shows the raw output of the command. It will run `data-evaluate-expression`
to check for variables.

While running you will get a console where you can manually type GDB/LLDB commands or MI
commands prepended with a hyphen `-`. The console shows all output separated
in `stdout` for the application, `stderr` for errors and `log` for log messages.

Some exceptions/signals like segmentation faults will be catched and displayed but
it does not support for example most D exceptions.

Support exists for stopping at the entry point of the application.  This is controlled
through the `stopAtEntry` setting.  This value may be either a boolean or a string.  In
the case of a boolean value of `false` (the default), this setting is disabled.  In the
case of a boolean value of `true`, if this is a launch configuration and the debugger
supports the `start` (or `exec-run --start` MI feature, more specifically), than this
will be used to run to the entry point of the application.  Note that this appears to
work fine for GDB, but LLDB doesn't necessarily seem to adhere to this, even though it may
indicate that it supports this feature.  The alternative configuration option for the
`stopAtEntry` setting is to specify a string where the string represents the entry point
itself.  In this situation a temporary breakpoint will be set at the specified entry point
and a normal run will occur for a launch configuration.  This (setting a temporary
breakpoint) is also the behavior that occurs when the debugger does not support the
`start` feature and the `stopAtEntry` was set to `true`.  In that case the entry point will
default to "main".  Thus, the most portable way to use this configuration is to explicitly
specify the entry point of the application.  In the case of an attach configuration, similar
behavior will occur, however since there is no equivalent of the `start` command for
attaching, a boolean value of `true` for the `stopAtEntry` setting in a launch configuration
will automatically default to an entry point of "main", while a string value for this
setting will be interpreted as the entry point, causing a temporary breakpoint to be set at
that location prior to continuing execution.  Note that stopping at the entry point for the
attach configuration assumes that the entry point has not yet been entered at the time of
attach, otherwise this will have no affect.

#### Attaching to existing processes

Attaching to existing processes currently only works by specifying the PID in the
`launch.json` and setting `request` to `"attach"`. You also need to specify the executable
path for the debugger to find the debug symbols.

```
"request": "attach",
"executable": "./bin/executable",
"target": "4285"
```

This will attach to PID 4285 which should already run. GDB will pause the program on entering and LLDB will keep it running.

#### Using `gdbserver` for remote debugging (GDB only)

You can also connect to a gdbserver instance and debug using that. For that modify the
`launch.json` by setting `request` to `"attach"` and `remote` to `true` and specifing the
port and optionally hostname in `target`.

```
"request": "attach",
"executable": "./bin/executable",
"target": ":2345",
"cwd": "${workspaceRoot}",
"remote": true
```

This will attach to the running process managed by gdbserver on localhost:2345. You might
need to hit the start button in the debug bar at the top first to start the program.

Control over whether the debugger should continue executing on connect can be configured
by setting `stopAtConnect`.  The default value is `false` so that execution will continue
after connecting.

#### Using ssh for debugging on remote

Debugging using ssh automatically converts all paths between client & server and also optionally
redirects X11 output from the server to the client.  
Simply add a `ssh` object in your `launch` request.

```
"request": "launch",
"target": "./executable",
"cwd": "${workspaceRoot}",
"ssh": {
	"forwardX11": true,
	"host": "192.168.178.57",
	"cwd": "/home/remoteUser/project/",
	"keyfile": "/path/to/.ssh/key", // OR
	"password": "password123",
	"user": "remoteUser",
	"bootstrap": "source /home/remoteUser/some-env"
}
```

`ssh.sourceFileMap` will be used to trim off local paths and map them to the server. This is
required for basically everything except watched variables or user commands to work.

For backward compatibility you can also use `cwd` and `ssh.cwd` for the mapping, this is only used
if the newer `ssh.sourceFileMap` is not configured.

For X11 forwarding to work you first need to enable it in your Display Manager and allow the
connections. To allow connections you can either add an entry for applications or run `xhost +`
in the console while you are debugging and turn it off again when you are done using `xhost -`.

Because some builds requires one or more environment files to be sourced before running any
command, you can use the `ssh.bootstrap` option to add some extra commands which will be prepended
to the debugger call (using `&&` to join both).

#### Extra Debugger Arguments

Additional arguments can be supplied to the debugger if needed.  These will be added when
the debugger executable (e.g., gdb, lldb-mi, etc.) is launched.  Extra debugger arguments
are supplied via the `debugger_args` setting.  Note that the behavior of escaping these
options depends on the environment in which the debugger is started.  For non-SSH
debugging, the options are passed directly to the application and therefore no escaping is
necessary (other than what is necessary for the JSON configuration). However, as a result
of the options being passed directly to the application, care must be taken to place
switches and switch values as separate entities in `debugger_args`, if they would normally
be separated by a space.   For example, supplying the option and value
`-iex "set $foo = \"bar\""` would consist of the following `debugger_args`:
```json
"debugger_args" : ["-iex", "set $foo = \"bar\""]
```
If `=` is used to associate switches with their values, than the switch and value should
be placed together instead.  In fact, the following example shows 4 different ways in
which to specify the same switch and value, using both short and long format, as well as
switch values supplied as a separate parameter or supplied via the `=`:
- ```json
  "debugger_args" : ["-iex", "set $foo = \"bar\""]
  ```
- ```json
  "debugger_args" : ["-iex=set $foo = \"bar\""]
  ```
- ```json
  "debugger_args" : ["--init-eval-command", "set $foo = \"bar\""]
  ```
- ```json
  "debugger_args" : ["--init-eval-command=set $foo = \"bar\""]
  ```
Where escaping is really necessary is when running the debugger over SSH.  In this case,
the options are not passed directly to the application, but are instead combined with the
application name, joined together with any other options, and sent to the remote system to
be parsed and executed.  Thus, depending on the remote system, different escaping may be
necessary.  The following shows how the same command as above needs to be escaped
differently based on whether the remote system is a POSIX or a Windows system.
- SSH to Linux machine:
  ```json
  "debugger_args": ["-iex", "'set $foo = \"bar\"'"]
  ```
- SSH to Windows machine:
  ```json
  "debugger_args": ["-iex", "\"set $foo = \\\"bar\\\"\""]
  ```
You may need to experiment to find the correct escaping necessary for the command to be
sent to the debugger as you intended.

# Kylin Native Debug 插件
[English Description](#kylin-native-debug)

- 主要用于类Linux系统上的gdb调试
- 在原Native Debug（WebFreak001/code-debug）基础上做了增改，如下。虽然原插件支持LLDB，但本插件的目标主要在gdb，对lldb未做测试
  - Fix can not input issue in linux;
  - Fix issues with viewing/setting registers;
  - Fix issues with setting variable values;
  - Add assembly debugging functionality;
  - Add reverse debugging interface buttons;
  - Add logging message functionality;
  - Fix issue with parsing two-dimensional arrays;
  - Fix issue with parsing QT variable;
  - Better support for c++, such stl vector, set, etc.;
  - Fix the breakpoint bug related to hit count

## 问题反馈
- https://gitee.com/openkylin/native-debug/issues
- https://gitee.com/openkylin/extensions-repo/issues

## 致谢
- 主要基于开源代码[WebFreak001/code-debug](https://github.com/WebFreak001/code-debug) 0.26.0 修改
- 部分功能使用了[Marus/cortex-debug](https://github.com/Marus/cortex-debug)中的代码

## 安装
- 安装在[Kylin-IDE/Kylin-Code](https://gitee.com/openkylin/extensions-repo/blob/master/user-guide/files/%E7%AE%80%E4%BB%8B.md)上，或VSCode、Code-OSS、VSCodium上
- 软件依赖：操作系统上需要安装好gdb
- 主要目标平台：X86、飞腾、LoongArch；其余平台，例如申威、mips也能够支持。插件主要为js和ts代码，故支持平台范围较广，但其余平台未详细测试

## 内存查看
- shift + ctrl + P，打开命令面板，输入并选择Examine memory location
- 输入地址，例如0xffffc988a6b8，然后按下回车，即可查看该地址附近的内存内容

## 常用关键字说明
主要说明重要关键字和本插件特性关键字
- type：使用gdb时设置为gdb。lldb未测试
- configurations：调试配置列表，注意，可添加多个调试配置，启动哪个调试配置可以在调试启动按钮（绿色三角按钮）后方的下拉框中选择，下拉框中显示名称为name字段
- name：当前调试配置的名称，因为configurations可以有多个，到底运行哪个需要根据此字段区分，会显示在调试启动按钮后方的下拉框中供选择
- request：launch或attach。launch表示使用调试模式启动程序，attach表示调试一个已经运行的进程
- target：要调试的程序路径。注意本插件为target，而不是program；target必须为程序路径，而不能包含程序运行参数，运行参数需要添加到arguments字段中
- arguments：程序运行参数。注意，本插件此参数只能为string类型，而不能为数组
- valuesFormatting：显示变量的形式。disable表示直接展示；parseText表示将调试器输出内容按结构解析；prettyPrinters表示启动调试器用户自定义的输出格式（如有）
- gdbpath：gdb路径。如果gdb程序并未在标准路径中或PATH环境变量中，可以用此参数直接指定gdb路径
- stopAtEntry：启动调试后是否先停在程序入口
- env：环境变量，对象类型，大括号内使用key:value形式表示环境变量和值
- debugger_args：添加调试器（gdb）运行参数。例如，有时需要重新指定程序代码，需要向gdb传递`--directory`参数，如下。需要注意转移字符，关于转移字符在此字段的用法请看英文readme的说明
  ```json
  "debugger_args": [
      "--directory=${workspaceRoot}/src"
  ],
  ```

## Attach调试已运行程序
- 此时，打开的通常是可执行程序和代码所在的目录；request字段填写attach；executable字段填写程序路径，以便gdb找到调试符号；target此时应填写已运行进程的PID
- 例子：attach到221073，它的二进制文件是${workspaceFolder}/client，它的源码在当前目录的src文件夹下，attach后暂停运行（stopAtConnect）
  ```json
  {
      "type": "gdb",
      "request": "attach",
      "name": "Attach to client",
      "target": "221073",
      "executable": "./client",
      "cwd": "${workspaceFolder}",
      "valuesFormatting": "parseText",
      "stopAtConnect": true,
      "debugger_args": [
          "--directory=${workspaceFolder}/src"
      ],
  },
  ```

## 使用gdbserver做远程调试
- 此时，打开的通常是本地可执行程序和代码所在的目录；request字段填写attach；remote字段填写true，表示是利用gdbserver进行远程调试；executable字段填写程序路径，以便gdb找到调试符号；target此时应填写gdbserver的IP和端口。注意，本插件request需要填attach，有些插件gdbserver模式需要填launch，注意此处差异
- 例子：attach模式，目标是192.168.1.12:35687上的gdbserver，它的二进制程序是当前目录下的test，它的源码在本地的当前目录的xxx目录下，attach后暂停（stopAtConnect）
  ```json
  {
      "type": "gdb",
      "request": "attach",
      "name": "gdbserver",
      "target": "192.168.1.12:35687",
      "executable": "./test",
      "cwd": "${workspaceFolder}",
      "remote": true,
      "valuesFormatting": "parseText",
      "stopAtConnect": true,
      "debugger_args": [
          "--directory=${workspaceFolder}/xxx"
      ],
  },
  ```

## 利用ssh做远程调试
- 不推荐用此插件做远程调试，如需远程调试，建议使用Kylin remote development插件（Kylin-IDE远程开发插件版），或使用kylin-ide-web-client(Kylin-IDE远程开发WebIDE版)
  * Kylin remote development插件
    - 下载地址：openVSX插件市场中搜索安装，或[直接下载](https://gitee.com/mcy-kylin/remote-dev/releases)
    - 帮助文档：[链接](https://gitee.com/openkylin/extensions-repo/blob/master/user-guide/files/%E8%BF%9C%E7%A8%8B%E5%BC%80%E5%8F%91.md)
  * kylin-ide-web-client
    - 下载地址：[链接](https://gitee.com/leven08/kylin-ide-web-client/releases)
    - 帮助文档：[链接](https://gitee.com/openkylin/extensions-repo/blob/master/user-guide/files/%E8%BF%9C%E7%A8%8B%E5%BC%80%E5%8F%91WebIDE%E7%89%88.md)

- 重要参数说明
  * target：ssh对端上的程序路径，这里的相对路径是相对于ssh.cwd(见下文)来说的
  * arguments：程序运行的参数，字符串类型
- ssh对象中的配置用ssh.xxx表示，主要参数说明如下
  * ssh.host：ssh目标（对端）IP，类似ssh命令参数
  * ssh.port：ssh目标（对端）端口，类似ssh命令参数，默认为22。注意此参数填写不需要加引号，直接填数字即可
  * ssh.user：ssh对端用户名，类似ssh命令参数
  * ssh.cwd：ssh对端的程序所在路径
  * ssh.keyfile：本地ssh私钥的绝对路径（通常是/home/xxx/.ssh/id_xxx）。注意，仅设置此参数不能正常工作，需要把本地公钥内容（通常是~/.ssh/id_xxx.pub文件中的内容）手动添加到ssh对端的authorized_keys中，用于自动登录
  * ssh.password：密码登录。不推荐，因为需要把密码明文填写在这里
  * ssh.forwardX11：如果调试的是图形程序，可以使用X11转发来看到图形界面
    - true表示使用X11图形转发，false表示不使用X11图形转发
    - 要使用X11图形转发，远端的sshd服务需要开启此功能，开启方法
      * `vim /etc/ssh/sshd_config`，将`X11Forwarding yes`前的注释去掉
    - 不需要再配置x11host和x11port，配置后也不会生效，此处已修改为使用本地unixsocket进行连接
  * ssh.sourceFileMap：将远端代码映射到本地。值为对象类型，里面写为key:value形式，其中key是远端机器上的代码路径，value是本地代码路径。注意，远端机器上的程序应使用远端代码构建，并且构建出程序后最好不要移动该程序位置
  * ssh.bootstrap：运行gdb前的处理，可以在远端执行一个脚本来做一些处理，通常是设置环境变量
  * 例子，本地mike用户远程调试kylin@192.168.1.2:/home/kylin/test/src/client，client是直接在src目录下编译构建的。ssh连接使用的是公钥方式而非密码方式
    ```json
    {
        "type": "gdb",
        "request": "launch",
        "name": "SSH debug",
        // 远端程序相对路径，相对于ssh.cwd，即绝对路径为/home/kylin/test/src/client
        "target": "./src/client",
        // 远端程序参数
        "arguments": "-h xxxx -p yyyy -s /tmp/test.sock",
        // 本地工作目录
        "cwd": "${workspaceRoot}",
        // ssh对象
        "ssh": {
            // 远端机器IP
            "host": "192.168.1.2",
            // 远端机器ssh端口
            "port": 22,
            // 远端机器ssh用户名
            "user": "kylin",
            // 本地
            "keyfile": "/home/mike/.ssh/id_rsa",
            // 远端工作目录
            "cwd": "/home/kylin/test/",
            // 代码映射
            "sourceFileMap": {
                "/home/kylin/test/src":"/home/mike/code/src-mike"
            },
            // 开启X11转发
            "forwardX11": true,
            // ssh连接后，执行一个echo命令
            "bootstrap": "echo 'this is a bootstrap'"
        },
        "valuesFormatting": "parseText",
    }
    ```
