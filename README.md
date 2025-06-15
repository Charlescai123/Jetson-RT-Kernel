# Jetson-RT-Kernel

This repo includes a compiled **real-time** kernel for [Nvidia Jetson AGX Orin (developer-kit)](https://developer.nvidia.com/embedded/learn/jetson-agx-orin-devkit-user-guide/index.html) and a script for installation. The system version information is below:

* *JetPack Version - 6.2*
* *NVIDIA Jetson Linux - 36.4.3*
* *Linux kernel Version - 5.15.148*

**Real-Time Kerenel Patch**:

> **Preliminary:** The real-time (RT) kernel enables in-response CPU scheduling, resulting in improved system responsiveness for real-time applications. We strongly recommend that users apply the RT kernel patch for their system’s real-time performance.


> **Warning:** Nvidia has provided the rt-kernel with a Debian package management-based [OTA](https://docs.nvidia.com/jetson/archives/r36.4.3/DeveloperGuide/SD/Kernel/KernelCustomization.html#real-time-kernel-using-ota-update). But since it has been reported to cause the system to [freeze at boot](https://forums.developer.nvidia.com/t/boot-freezing-when-installing-preemptrt-on-nvme-setup-with-agx-orin-dev-kit-jetpack-6-2/323869) when entering the GUI, we recommend building and installing the kernel manually.

## Kernel Compile

> **Recommendation:** It is highly recommended to have a rough review for Nvidia's officia [documents](https://docs.nvidia.com/jetson/archives/r36.4/DeveloperGuide/index.html) if you are new to Jetson. 

Nvidia has provided a detailed [guidance](https://docs.nvidia.com/jetson/archives/r36.4.3/DeveloperGuide/SD/Kernel/KernelCustomization.html#sd-kernel-kernelcustomization) on building a customized kernel for Jetson platforms. Following this procedure typically produces:

   * A bindary real-time kernel image
   * The kernel module 5.15.148-rt-tegra
   * A set of DTB (Device Tree Blob) files for boot configuration

> **Note:** This repo contains the compiled real-time kernel and related dependencies. If you want to apply it, make sure your Jetson L4T is the same version as required. 

(Optional) If UEFI Secure Boot is not enabled, you can skip the kernel signing and encryption steps. Or otherwise, follow [Secure Boot](https://docs.nvidia.com/jetson/archives/r36.4.3/DeveloperGuide/SD/Security/SecureBoot.html#sd-security-secureboot).

## Installation

There're two options provided to install the compiled kernel:

   * Flash the new kernel and modules onto the Jetson device using `flash.sh`. You may find more information from [flashing support](https://docs.nvidia.com/jetson/archives/r36.4/DeveloperGuide/SD/FlashingSupport.html).

   * Use script `install_rt_kernel.sh` if you want to install the compiled kernel in this repo.

For the second option, you need to download this repo on the Jetson:

```bash
git clone git@github.com:Charlescai123/Jetson-RT-Kernel.git
```

The installation script will change stuff in your `/boot` folder. So before applying the kernel, it is safe to make a backup:

```bash
sudo cp -rf /boot /boot_bak
```

Specify the disk for real-time kernel installation (NVMe or eMMC):

```bash
sudo ./install_rt_kernel.sh --storage <nvme> or <emmc>
```

Running this script will: 

   * Install the `dtbs` files into `/boot`
   * Decompress the kernel library under `/lib/modules`
   * Install real-time binary image `Image.rt` to `/boot`
   * Install real-time initrd image `initrd.img-5.15.148-rt-tegra` to `/boot`
   * Add new boot entry for real-time kernel to `/boot/extlinux/extlinux.conf`

From now, you are all set! The next step is to validate the installed kernel by rebooting.

Here are some useful links for reference: 
- https://chipnbits.github.io/content/projects/RLUnicycle/rtkernel/rtpatch.html
- https://forums.developer.nvidia.com/t/preempt-rt-patches-for-jetson-nano/72941
- https://forums.developer.nvidia.com/t/jetson-agx-orin-rt-linux-without-reflashing/283832
- https://forums.developer.nvidia.com/t/no-display-with-preempt-rt-patches/240876
- https://forums.developer.nvidia.com/t/build-the-real-time-kernel/229571
- https://blog.csdn.net/weixin_43854380/article/details/126584835
- https://github.com/kozyilmaz/nvidia-jetson-rt/blob/master/docs/README.03-realtime.md


## Configuration and Test

### Config and test HAT device

1. Check if there are two SPI device

   ```
   ls /dev/spidev*
   ```

   you should get:

   ```
   /dev/spidev2.0  /dev/spidev2.1
   ```

2. Enable the HAT functionality from userspace

   ```
   sudo add-apt-repository ppa:ubilinux/up
   sudo apt install upboard-extras
   sudo usermod -a -G gpio ${USER}
   sudo usermod -a -G leds ${USER}
   sudo usermod -a -G spi ${USER}
   sudo usermod -a -G i2c ${USER}
   sudo usermod -a -G dialout ${USER}
   sudo reboot
   ```

3. Go to the `/test` file run the `./blink.sh`

   ```
   cd test
   sh ./blink.sh
   ```

   then the green led of UP board will blink

4. For HAT test, check

   https://wiki.up-community.org/Pinou

### Real time test using latency plot under the stress

1. Install requirement

   ```
   sudo apt install rt-tests stress gnuplot
   ```

2. Go to the `/test` file and Run the RT test

   ```
   cd test
   sudo ./rt-test.sh --cores <cores-num>
   ```

   For example, the latency plot of 4-cores and 8-cores should look like:

| 4 Cores (non real-time kernel)                                        | 4 Cores (real-time kernel)                                        |
|-----------------------------------------------------------------------|-------------------------------------------------------------------|
| <img src="./test/results/4-cores/non-rt.png" height="300" alt="rlm"/> | <img src="./test/results/4-cores/rt.png" height="300" alt="rlm"/> |

| 8 Cores (non real-time kernel)                                        | 8 Cores (real-time kernel)                                        |
|-----------------------------------------------------------------------|-------------------------------------------------------------------|
| <img src="./test/results/8-cores/non-rt.png" height="300" alt="rlm"/> | <img src="./test/results/8-cores/rt.png" height="300" alt="rlm"/> |


5. Analysis:
   - More sample on the left means lower latency in general
   - More clustered samples indicate less flutter
   - The max latency should not deviate far from mean value (typically under 100us)

## Acknowledgement
Thanks [Ubuntu-RT-UP-Board](https://github.com/qiayuanl/Ubuntu-RT-UP-Board) for the real-time kernel testing script.
