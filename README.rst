==================================
Yet Another Tesla Camera USB drive
==================================

This project turns a Raspberry Pi board into a USB drive for Tesla camera. It also automatically
uploads videos to your SSH server when you arrive home.

How to Use
==========

::

  # Manually download the AWESOME shflags file.
  wget https://raw.githubusercontent.com/kward/shflags/master/shflags

  # Insert a SD card into the host.

  # Configure how your USB drive is going to connect to your home network.
  ./change_settings.sh
  # 'conf/settings.sh' is generated.

  # Write the Raspberry Pi OS image, our code and settings to the SD card.
  ./inject_to_sdcard.sh ~/Downloads/2021-12-02-raspios-buster-armhf-lite.img /dev/sdg
  # 'conf/id_rsa*' are generated. Please copy the conf/id_rsa.pub to your SSH server.

  # Remove the SD card and boot it with a Raspberry Pi board. Remember to connect a USB Ethernet
  # adapter to install/update software packages.

  # After about half hour, it will automatically shutdown once the setup procedure is done.
  # Then you are ready to go.


For Developer
=============

Update Program to Device
------------------------

::

  export RPI_ADDR="account@your_rpi_address"
  rsync -av * ${RPI_ADDR}:/root/teslacam/ ; \
  ssh ${RPI_ADDR} rm /root/teslacam/setup_system.sh \
                     /root/teslacam/FAKE_BUTTON \
                     /root/teslacam/NEW_STATE

Test Context
------------

::

  echo "AWAY" > NEW_STATE
  echo "HOME" > NEW_STATE


Test Button (Optional)
----------------------

You can connect a physical button on GPIO4 and GND. When the button is presswed, it will copy
the videos as well (so that you don't need to press on the Tesla screen). This has 2 minutes
delay due to the technical reason.

::

  echo "0" > FAKE_BUTTON; sleep 0.2; \
  echo "1" > FAKE_BUTTON; sleep 0.2; \
  echo "0" > FAKE_BUTTON; sleep 0.2;


Tested Board
------------

I mainly develop and test on the Raspberry Pi 1/2 Zero W board. But this should be able to
run on other Raspberry boards as well (or with minimum modification).
