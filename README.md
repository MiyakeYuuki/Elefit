![Elefit logo](https://github.com/MiyakeYuuki/Elefit/blob/myspace_tomo/images/Elefit_icon.png "Elefit icon")

# What's elefit
Elefit is a device used for DNA analysis preparation. It has a compact body, so easy to move.

# File Description
## ◆ "controller_app" folder
### elefit_arduino_nano_gui.pde
This is a GUI program for the PC to conrtrol Elefit.

![PC app](https://github.com/MiyakeYuuki/Elefit/blob/myspace_tomo/images/pc_app.png "PC app")

### Elefit_remote_controller.apk
This is an app for the Smartphone (Android) to conrtrol Elefit.

<img src = "https://github.com/MiyakeYuuki/Elefit/blob/myspace_tomo/images/smatphone_app.jpg" width="300px">

### Elefit_remote_controller.aia
The app's project file. (MIT App Inventor 2)

## ◆ "elefit_microcontroller_program" folder
### elefit_microcontroller_program.ino
This is a program for microcontroller (Bluno Nano V1.4). 

## Software Installation (If you use the smartphone controller)
1. Download and install a PC software 「[Arduino IDE](https://www.arduino.cc/en/software)」
2. Open Arduino IDE.
3. Connect your PC and Elefit using USB (Micro-B) cable.
4. Select board and COM port. (Board name: Arduino nano)
5. Upload sketch (Sketch file name: elefit_microcontroller_program.ino).
6. Download and install the app. (App file name: Elefit_remote_controller.apk).

## Software Installation (If you use the PC controller)
1. Download and install a PC software 「[Processing](https://processing.org/)」 and 「[Arduino IDE](https://www.arduino.cc/en/software)」
2. Open Arduino IDE.
2. Connect your PC and Elefit using USB (Micro-B) cable.
3. Select board and COM port. (Board name: Arduino nano)
4. Upload sketch (Sketch file name: elefit_microcontroller_program.ino).
5. Open Processing.
6. Open sketch (Sketch file name: elefit_arduino_nano_gui.pde).
7. Install library 「controlP5」.
8. Press a run botton and open GUI.