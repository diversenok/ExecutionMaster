**Execution Master** is a program for Windows that allows you to configure any
program launch using several standard actions:

 - **Ask** user to confirm program execution;
 - **Deny** program execution (2 modes: notify user and not);
 - **Drop** administrative privileges of specified program;
 - Request **elevation** for the program at every launch;
 - Force system **not to sleep** / **display to be on** while selected prorgam works;
 - **Execute** another program instead of specified.

![](https://habrastorage.org/web/2f2/7d8/3af/2f27d83af36747068f3e9a5e9d857b39.png)

### Release content:

See [releases](https://github.com/diversenok/ExecutionMaster/releases) page

 - **ExecutionMaster.exe** — GUI tool for configuration;
 - **emc.exe** — console tool for configuration;
 - **Actions** folder with actions executables described above.

**Note:** if you have x64 version of Windows use x64 version of program.
Not all actions of x86 Execution Master will work correctly on Windows x64.

Program was tested on Windows 7, 8 and 10.

Key        | Value
---------- | -----
Author     | © diversenok
Email      | diversenok@gmail.com
Compiled   | Delphi XE8
Version    | 0.8.15.3
Date       | Aug 25, 2017

Probably, you should be able to compile it without any problems starting from
Delphi XE2.

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