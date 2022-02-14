"""
Last Updated: 2020.08.13

This is the imaging software for pi-croscope, developed by Kuan-Lin Chen, with the following functions:
    1. Preview Mode: for real-time imaging, take a photo at the end of preview.
    2. Time Lapase Mode: for autonomous time-lapse imaging.
    3. Filter mode is mainly for debugging and would be removed in future version.

Developer Notes:
    1. Set the camera framerate to 1 before closing the camera to prevent bug that disable closing the camera.
    2. GPIO pins with pin number larger than 25 would cause error for raspberry pi module B and should be avoided.
    3. Thinking of fixing unstable filter movement, recommeded duty cycle 40%...?

"""

import os
import picamera
import datetime
import keyboard
import RPi.GPIO as gpio
from time import sleep
from fractions import Fraction

# GPIO Pins
# Pin number > 25 causes error for pi module B and should be avoided.
gpio_relay = 18
slider_FW = 11; slider_BW = 13; slider_JOG = 15

def setup_gpio_pin_out():
    """
    This function is for setting up the gpio pins for LED and sliders control.
    Note:
        1. Always run this function in the beginning of the script.

    **Parameter**
        No parameters.

    **Return**
        Returns nothing.

    """

    # Set up gpio for LED
    gpio.setup(gpio_relay, gpio.OUT)

    # Set up gpio for sliders
    gpio.setup(slider_FW, gpio.OUT); gpio.setup(slider_BW, gpio.OUT); gpio.setup(slider_JOG, gpio.OUT)

def relay_switch(ON = False):
    """
    This function turns on and off the LED.
    LED is connected to the relay and has pin number 18 of the pi GPIO board.
    If the function is not working, check if the pin number is corresponding to the connected LED.

    **Parameters**
        ON *Boolyn*
            default : False
            turns on the LED if ON == True.
    **Return**
        Does not return anything.
    """
    if ON:
        gpio.output(gpio_relay, gpio.HIGH)
    else:
        gpio.output(gpio_relay, gpio.LOW)

def reset_slider():
    gpio.output(slider_BW, gpio.LOW); sleep(3)
    gpio.output(slider_BW, gpio.HIGH); sleep(0.5)

def slider_forward():
    gpio.output(slider_JOG, gpio.LOW); sleep(0.3)
    gpio.output(slider_FW, gpio.LOW); sleep(1.5)
    gpio.output(slider_FW, gpio.HIGH); sleep(0.3)
    gpio.output(slider_JOG, gpio.HIGH); sleep(0.5)

def slider_backward():
    gpio.output(slider_JOG, gpio.LOW); sleep(0.3)
    gpio.output(slider_BW, gpio.LOW); sleep(1.5)
    gpio.output(slider_BW, gpio.HIGH); sleep(0.3)
    gpio.output(slider_JOG, gpio.HIGH); sleep(0.5)

def slider_mode(steps = 1):

    if steps == 1:
        reset_slider()
    elif steps == 2:
        reset_slider()
        slider_forward()
    elif steps == 3:
        reset_slider()
        slider_forward()
        slider_forward()
    elif steps == 4:
        reset_slider()
        slider_forward()
        slider_forward()
        slider_forward()
    else:
        reset_slider()
        gpio.cleanup()
        gpio.setmode(gpio.BOARD)
        setup_gpio_pin_out()
        reset_slider()

def preview_mode(filename):
    """
    This function serves as the preview mode of the software. In the preview mode, the user would first be asked to input a filename, as, in the end, the system would save a final figure in the "Preview Pics" folder.

    """
    step = int(raw_input("Enter 1 for bright field, 2 for rhodamine filer, 3 for FAM filter\n"))

    slider_mode(steps = step)

    with picamera.PiCamera(resolution = (2560, 1920), framerate = Fraction(1, 2)) as camera:
        # framerate = n means taking n pics in 1 sec
        # camera.iso = 800
        camera.shutter_speed = 2000000
        camera.image_effect = 'denoise'
        # camera.exposure_mode = "night"
        # camera.exposure_mode = "off"
        camera.exposure_mode = "auto"
        if step == 1:
            camera.framerate = 2
            camera.shutter_speed = 200

        print("""
              Preview Mode Selected:
              Press a to set the exposure time to desired value
              Press s to set maximum exposure time
              Press d for maximum exposure time
              Press q to quit""")

        relay_switch(ON = True)
        camera.start_preview(fullscreen = False, window = (100, 50, 1000, 800))

        while True:
            camera.annotate_text = "exposure time = %s us" % camera.shutter_speed
            tune = raw_input()
            if tune == "a":
                camera.shutter_speed = int(raw_input("Enter desired exposure time(us)\n"))
            elif tune == "s":
                camera.framerate = Fraction(1,int(raw_input("Enter the desired exposure time maximum (sec) \n")))
            elif tune == "d":
                camera.shutter_speed = int(1.0 / camera.framerate) * 1000000
            elif tune == "q":
                break

        camera.capture_sequence(['/home/pi/Documents/Preview Pics/{}.tif'.format(filename)], use_video_port = True)
        print('Tuned shutter speed: %s us' % camera.shutter_speed)
        # Always set the framerate = 1 so that the camera can close smoothly
        camera.framerate = 1
        relay_switch(ON = False)
        camera.stop_preview()


def time_lapse_mode(foldername):
    exposure_time = int(raw_input("Enter desired the exposure time: (s)\n"))
    time_diff = int(raw_input("Enter desired the time gap: (min)\n")) * 60.0
    total_pic = int(raw_input("Enter desired the total pictures:\n"))
    step = int(raw_input("Enter 1 for rhod, 2 for rhod + fam:\n"))

    if step == 1:
        os.mkdir("/home/pi/Documents/Time Lapse Images/{}".format(foldername))

        slider_mode(steps = 2)

        for i in range(total_pic):
            relay_switch(ON = True)
            sleep(2)

            filename = "/home/pi/Documents/Time Lapse Images/{}/SubImage{}.jpeg".format(foldername, i + 1)

            with picamera.PiCamera(resolution = (2560, 1920), framerate = Fraction(1, exposure_time)) as camera:
                print("Taking Image %d"%(i + 1))
                camera.iso = 800
                camera.shutter_speed = exposure_time * 1000000
                camera.image_effect = 'denoise'
                camera.exposure_mode = "night"
                # camera.exposure_mode = "auto"
                camera.capture(filename)
                camera.framerate = 1

            sleep(3)
            relay_switch(ON = False)
            if i+1 != total_pic:
                print("To Sleep")
                sleep(time_diff)
    else:

        os.mkdir("/home/pi/Documents/Time Lapse Images/{}/".format(foldername))
        os.mkdir("/home/pi/Documents/Time Lapse Images/{}/Rhod/".format(foldername))
        os.mkdir("/home/pi/Documents/Time Lapse Images/{}/FAM/".format(foldername))

        for i in range(total_pic):

            relay_switch(ON = True)
            sleep(2)

            slider_mode(steps = 2)

            filename = "/home/pi/Documents/Time Lapse Images/{}/Rhod/SubImage{}.jpeg".format(foldername, i + 1)

            with picamera.PiCamera(resolution = (2560, 1920), framerate = Fraction(1, exposure_time)) as camera:
                print("Taking Image %d"%(i + 1))
                camera.iso = 800
                camera.shutter_speed = exposure_time * 1000000
                camera.image_effect = 'denoise'
                camera.exposure_mode = "night"
                # camera.exposure_mode = "auto"
                camera.capture(filename)
                camera.framerate = 1

            slider_forward()

            filename = "/home/pi/Documents/Time Lapse Images/{}/FAM/SubImage{}.jpeg".format(foldername, i + 1)

            with picamera.PiCamera(resolution = (2560, 1920), framerate = Fraction(1, exposure_time)) as camera:
                print("Taking Image %d"%(i + 1))
                camera.iso = 800
                camera.shutter_speed = 5000000
                camera.image_effect = 'denoise'
                camera.exposure_mode = "night"
                # camera.exposure_mode = "auto"
                camera.capture(filename)
                camera.framerate = 1

            sleep(3)

            slider_mode(steps = 5)

            relay_switch(ON = False)
            if i+1 != total_pic:
                print("To Sleep")
                sleep(time_diff)


if __name__ == "__main__":

    try:
        gpio.setmode(gpio.BOARD)
        setup_gpio_pin_out()

        intro_txt = """
        Enter p for Preview Mode
        Enter f for Filter Switching
        Enter t for Time Lapse Mode
        Enter q to Quit the program
        """

        while True:
            move = raw_input(intro_txt)
            if move == "p":
                preview_mode(filename = raw_input("Enter the desired file name:\n"))
            elif move == "t":
                folder_name = raw_input("Enter the desired folder name:\n")
                time_lapse_mode(foldername = folder_name)
            elif move == "f":
                state = int(raw_input("Enter 1, 2, 3, 4, 5:\n"))
                slider_mode(steps = state)
            elif move == "q":
                break

    except:
        print("\nError or Leaving Program")

    finally:
        gpio.cleanup()
