# MacProOverclockUtility

Mac Pro 1.1, 2.1 &amp; 3.1 Overclock kernel extension

Overclocks FSB frequency 

Compatible with macOS 10.5 or any later version

Usage:

1. Go to the Releases section and download the latest release
2. Open macOS terminal and execute commands:

    cd ~/Downloads/overclock
    sudo xattr -r -d com.apple.quarantine ./overclock.kext
    sudo xattr -r -d com.apple.quarantine ./overclock_fsb
    sudo chown -R root:wheel ./overclock.kext
    sudo kextload -v ./overclock.kext

3. Click "Open System Preferences", unlock the settings by typing root password, click "Allow" button and then "Reboot" button
4. Open macOS terminal and execute command to obtain the current FSB speed

    cd ~/Downloads/overclock
    ./overclock_fsb
    
5. The real processor speed = FSB_speed * multiplier. Different processors has different multipliers but the resulting processor speed always depends on the FSB_speed. So to overclock the system you should choose a higher FSB_speed. For example, if you see that FSB=400 MHz in the previous step, you can try to overclock to FSB=420. To do this, execute the following command in the macOS terminal:

    cd ~/Downloads/overclock
    ./overclock_fsb 420
    
Or you can choose any other value instead of 420. But it is recommended to increase FSB frequency step-by-step instead of just selecting the desired value: 

    cd ~/Downloads/overclock
    ./overclock_fsb 405
    ./overclock_fsb 410
    ./overclock_fsb 415
    ./overclock_fsb 420
  
6. Now you have a problem remaining - your system clock is running too fast. To fix it you can just reboot the system. Execute in macOS terminal:

    sudo reboot
  
7. You have overclock the system but don`t see that it become fast. This is because of the Intel Speed Step algorithms that dynamically downclock your system. To get rid of this feature you should just delete the following a few files from your system. Execute in macOS terminal:

    sudo rm -rf /System/Library/Extensions/IOPlatformPluginFamily.kext/Contents/PlugIns/ACPI_SMC_PlatformPlugin.kext/Contents/Resources/MacPro1_1.plist
    sudo rm -rf /System/Library/Extensions/IOPlatformPluginFamily.kext/Contents/PlugIns/ACPI_SMC_PlatformPlugin.kext/Contents/Resources/MacPro2_1.plist
    sudo rm -rf /System/Library/Extensions/IOPlatformPluginFamily.kext/Contents/PlugIns/ACPI_SMC_PlatformPlugin.kext/Contents/Resources/MacPro3_1.plist

  It works fine before macOS 11. Starting from macOS 11 you should do the following:
  
  a) Go to the System Preferences and make sure that FileVault is disabled. If it is not, you should disable it.
  b) Reboot the system while holding Command+R to boot into the recovery mode. Alternatively, you can use boot into usb flash copy of macOS installation. Open the terminal and run the commands:
    
    csrutil disable
    csrutil authenticated-root disable
    reboot    
  
  The first command disables System Integrity Protection (SIP), the second disables Signed System Volume (SSV) and the last one reboots the system.
  
  c) Open macOS terminal and execute commands:
    
    mkdir ~/rootmount
    mount
    
  In the listed devices you can see a device with the "sealed" word. It is the currently mounted snapshot of the System Volume. For example:
  
  /dev/disk1s5s1 on / (apfs, sealed, local, read-only, journaled)
  
  The System Volume itself is the same, except without the final s1. While device numbers may vary, in this example the command which you should execute to mount the System Volume would be:
  
  sudo mount -o nobrowse -t apfs /dev/disk1s5 ~/rootmount
  
  d) A writable copy of the System Volume is now mounted at ~/rootmount. Changes to the volume can be made. Execute in macOS terminal:
  
    cd ~/rootmount
    sudo rm -rf ./System/Library/Extensions/IOPlatformPluginFamily.kext/Contents/PlugIns/ACPI_SMC_PlatformPlugin.kext/Contents/Resources/MacPro1_1.plist
    sudo rm -rf ./System/Library/Extensions/IOPlatformPluginFamily.kext/Contents/PlugIns/ACPI_SMC_PlatformPlugin.kext/Contents/Resources/MacPro2_1.plist
    sudo rm -rf ./System/Library/Extensions/IOPlatformPluginFamily.kext/Contents/PlugIns/ACPI_SMC_PlatformPlugin.kext/Contents/Resources/MacPro3_1.plist

  e) After making changes, the modified copy of the System Volume must be marked as a bootable snapshot using bless. To create a snapshot of the modified volume, mark it as bootable, and set it as the new boot volume, run:
  
    sudo bless --folder ~/rootmount/System/Library/CoreServices \
    --bootefi --create-snapshot
    sudo reboot
    
8. Finally, you can see the overclocked CPU frequency. Run the following command in the macOS terminal:

    sudo powermetrics
    
9. If you want your system to be overclocked automatically during the first boot, you should first copy all or the files from the distributive of this utility to the /Users/Shared/overclock folder so that the kext can be found at path /Users/Shared/overclock/overclock.kext. Edit the /Users/Shared/overclock/overclock_daemon.sh file first. You should disable automatic syntax correction in TextEdit before opening. You can see "SET_FSB=455" in the first line of the file. Replace 455 with the desired FSB frequency for automatic overclocking and save the file. After that you should perform actions described in p.7 c) of this instruction. Then run the following commands in terminal:

  sudo cp -R /Users/Shared/overclock/com.example.plist ~/rootmount/Library/LaunchDaemons
  
  sudo chmod -R 755 ~/rootmount/Library/LaunchDaemons/com.example.plist
  
  sudo bless --folder ~/rootmount/System/Library/CoreServices \\
    --bootefi --create-snapshot
    
  sudo reboot
  
  The system will automatically reboot during the first boot after power on and then boot normally. 
  if you want to change the target FSB frequency, you can edit the /Users/Shared/overclock/overclock_daemon.sh file again. If you rename or delete this file, the system will boot without automatic overclocking.

