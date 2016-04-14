# Debian on iWork 8 (i1)

This repo contains resources to help make Debian run on the dual-OS version of iWork 8 (i1), a Bay Trail-based tablet. This repo is NOT for the newer "flagship version" (i1-T) which is based on the Cherry Trail chipset, but they both share many characteristics. See the i1-T section for details.

The iWork 8, like many other budget tablets, is a 64-bit machine with 32-bit UEFI firmware. It comes with Windows 10 and Android out of the box (Sorry, I didn't check the version of Android).

## Current status
Note: I used a self-compiled 4.4.0-r2 kernel from the [drm-intel-nightly](http://cgit.freedesktop.org/drm-intel/) repo.

### Working
- [64-bit install](#installation)
- Touchscreen (FocalTech IC; works out of the box)
- [3D acceleration](#3d-acceleration) (with a dirty workaround)
- [Wi-Fi](#wi-fi) (with kernel patches and [hadess's rtl8723bs driver](https://github.com/hadess/rtl8723bs))
- SD card reader (with kernel patches in the Wi-Fi section)
- [Battery status](#battery-status) (kinda "works" :/)

### Not (yet) working
- [Sound](#sound)
- [Backlight](#backlight) (software only, by manually adjusting with `xrandr`)
- Bluetooth
- Camera
- Suspending to RAM

## Installation
Download [the multi-arch Jessie image](http://cdimage.debian.org/cdimage/release/current/multi-arch/iso-dvd/debian-8.2.0-i386-amd64-source-DVD-1.iso) and write it onto a USB stick with `dd`. Installation will "just work" (Select *64-bit install* if you wish). Touchscreen should work during the progress, but a USB keyboard is required as the installation environment does not provide an on-screen keyboard. Answer no when asked whether to use a mirror.

## Getting things to work
### 3D acceleration
At the GRUB screen, temporarily append the `nomodeset` option to the boot parameters, or you may encounter a blank screen. We need to apply a dirty workaround first for KMS to work. Strangely though, with KMS the display works after suspending then resuming the tablet. To achieve this, I wrote a systemd service file that executes `systemctl suspend` to suspend the device on boot (see `systemd/suspend-hack.service`). Afterwards, when the screen goes blank during boot, wait about 10 seconds then quickly press the home button two times. The system will resume with the display working.

Relevant logs will be attached later.
Relevant thread: https://bugs.freedesktop.org/show_bug.cgi?id=71977 (and no, none of the workarounds work on recent kernels)

### Wi-Fi
[hadess's rtl8723bs driver](https://github.com/hadess/rtl8723bs) is required to make Wi-Fi work. Apply the patches in the `patches` directory, then build and install the patched kernel and the module as usual. Note that in `0004-mmc-sdhci-pci-Fix-device-hang-on-Intel-BayTrail.patch`, you will need to change `sdhci-pci.c` to `sdhci-pci-core.c` in order to apply the patch to 4.4.0.

### Backlight
ACPI brightness adjustment is not supported. You can manually "adjust" the backlight with `xrandr --output DSI1 --brightness [a value from .1 to 1]`. However, it's not possible to complete turn off the display, even if you set the brightness all the way down to 0.

### Battery status
The device uses AXP288 as its PMIC. For some reason, the `axp288_fuel_gauge` driver isn't working (compile your own kernel if you think you have better luck). You can, however, get the battery reading using `i2cget`, and feed it into the `test_power` module. I've made a script (`scripts/battery.sh`) to do that periodically.

Related thread: https://bugzilla.kernel.org/show_bug.cgi?id=88471

### Sound
Still working to make it work. I've attached the ELF firmware included in the Android image in `firmware` (no longer works with upstream drivers).

Related thread: http://thread.gmane.org/gmane.linux.alsa.devel/134554

## t1-T
The newer flagship version (t1-T) is a Cherry Trail-based tablet with Windows 10 as the only OS. It has GSL3670 as its touchscreen IC (though DSDT shows a 1680), and I could not find the right firmware for it anywhere. If you are considering buying an iWork 8, do not choose the flagship version if you want touchscreen support on Linux.

