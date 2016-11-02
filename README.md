# freebsd-lsisas-zfs-devicesmap
This script return a .csv formated output of the device mapping bettween a selected zfs pool and the LSI SAS3 controller.

the output return the following informations:
Controller ID, Enclosure ID, Slot Number, Disk Serial, Partition GPT ID and the BSD Device Name.

The first purpose of the script is to convert the gptid returned from the zpool status command to the complete physical location of the devices.

You need sas3ircu utility to use this script.
