## Execution Master

**Execution Master** is a utility for Windows that allows you to gain more
control over running any specified program regardless of who and how tried to
run it. You can assign one of the several standard actions for it:

 - **Ask** user to confirm program execution;
 - **Deny** program execution (2 modes: notify user and not);
 - **Drop** administrative privileges of specified program;
 - Request **elevation** for the program at every launch;
 - Force system **not to sleep** / **display to be on** while the selected program works;
 - **Execute** another program instead of specified.

![](https://habrastorage.org/web/2f2/7d8/3af/2f27d83af36747068f3e9a5e9d857b39.png)

The latest version also contains shell extension:

![](https://habrastorage.org/webt/59/e2/37/59e237990d931309633594.png)

## Downloads

See [releases](https://github.com/diversenok/ExecutionMaster/releases) page

 - **ExecutionMaster.exe** — GUI tool for configuration;
 - **emc.exe** — console tool for configuration;
 - **Actions** folder with actions executables described above.

**Note:** if you have x64 (aka 64-bit) version of Windows use x64 version of the program.
Not all actions of x86 (aka 32-bit) Execution Master will work correctly on Windows x64.

The program was tested on Windows 7, 8 and 10.

Key        | Value
---------- | -----
Author     | © diversenok
Email      | diversenok@gmail.com (English and Russian are suitable)
Compiled   | Delphi XE8
Version    | 0.10.14.0
Date       | Oct 14, 2017

Probably, you should be able to compile it without any problems starting from
Delphi XE2.

## How it works

This software uses internal Windows mechanism that is called **Image File
Execution Options** to intercept process creation and automatically launch a
debugger for the specified program. These small utilities from *Actions* folder
are designed to be set as such debuggers so they can perform some special activity
before approving the creation of the original process.

------------------------------------------------------------------------------

    Copyright (C) 2017 diversenok

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.