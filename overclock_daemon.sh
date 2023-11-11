SET_FSB=455

kextload -v /Users/Shared/overclock/overclock.kext || exit 0
/Users/Shared/overclock/overclock_fsb | grep Current | grep $SET_FSB && exit 0
/Users/Shared/overclock/overclock_fsb $SET_FSB && reboot
