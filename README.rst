Pin testing
...........

:Stable release:  unreleased

:Status:  alpha

:Maintainer:  https://github.com/henkmuller

:Description:  Testing of pin connectivity


This repo contains an application to test the connectivity of a device by driving values on it and checling the response. By measuring capacitance, it also measures how long the PCB traces are and it may be possible to detect dry joints.

Key Features
============

* Creates a file with expected values, measuring a number of "good" boards
* Compares boards with the known good boards.

To Do
=====

* Build in the possibility to disable pins from being tested (those pins that drive actuators)
* Test for shorts between pins.

Firmware Overview
=================

One module in the app implements the measurements and storage. It uses the same principle as the capacitive sensing module, but it works on a lower level to detect stuck at ones and stuck at zeroes.

Known Issues
============

* None

Required Repositories
================

* xcommon git\@github.com:xcore/xcommon.git

Support
=======

Feel free to suggest patches.
