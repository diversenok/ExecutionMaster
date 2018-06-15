## JustRun

This program is not included in Execution Master. It just runs processes bypassing IFEO. See [the discussion](https://github.com/diversenok/ExecutionMaster/issues/2).

#### Release: 

**[JustRun-v2.zip](https://github.com/diversenok/ExecutionMaster/files/2105466/JustRun-v2.zip)**

#### There are four slightly different versions of the same program:
 - x64 GUI = 64-bit & Graphical subsystem
 - x64 CUI = 64-bit & Console subsystem
 - x86 GUI = 32-bit & Graphical subsystem
 - x86 CUI = 32-bit & Console subsystem

#### And there are several things you should take into account:
 - x86 (aka 32-bit) version **can't** run 64-bit programs on 64-bit systems. Use x64 version in this case.
 - The difference between CUI (Console subsystem) and GUI (Graphical subsystem) programs is very thin. However, you can notice it when running programs from the command line: console applications don't usually wait for GUI applications and don't share a console with them.
 - GUI version doesn't spawn a console, but CUI does.

#### Other hints:

By default, **JustRun** waits for the newly created process until it closes and then exits with the same exit code. It is necessary if the caller needs the exit code value or the wait itself. You can override this behavior by specifying `/nowait` key as the first parameter. In this case, **JustRun** exits immediately after creating a new process. Note that in all situations it tries to replace the parent process of the newly created process with the caller process.

#### Usage example:

	JustRun.exe /nowait "C:\Windows\notepad.exe" "%USERPROFILE%\Documents\Test.txt"