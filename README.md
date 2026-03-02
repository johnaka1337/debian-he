# Debian-HE

### Overview
> The core philosophy of this project is built upon two pillars: **minimalism** and **security**. The aim is to deliver a clean, efficient, and hardened base system that is fast, stable, and ready for daily use without unnecessary bloat.
>
> This repository contains configuration files and scripts to harden system security, improve performance, and build a custom, debloated Linux kernel. The kernel configuration is strictly targeted at modern desktop and home hardware (2020+).
>

### Highlights and Goals
* **Stripped Kernel Configuration:**
  * Removed legacy, deprecated, and exotic/server hardware support.
  * Disabled LDT (`MODIFY_LDT_SYSCALL`).
  * Enabled NT Sync driver (great for Wine/Proton gaming).
  * And more...
* **Attack Surface Reduction:**
  * Disabled tracers, debugging information, and `debugfs`.
  * Enabled explicit CPU register and memory zeroing (`ZERO_CALL_USED_REGS`).
  * Enforced kernel lockdown (`LOCK_DOWN_KERNEL_FORCE_CONFIDENTIALITY`).
  * And more...
* **System Hardening and Tuning:**
  * Advanced network stack tuning (latency reduction, TCP optimization, checked via [Waveform Bufferbloat Test](https://www.waveform.com/tools/bufferbloat)).
  * Baseline firewall configuration (drop incoming, allow outgoing + established).

### Installation / Deployment
```bash
git clone [https://github.com/johnaka1337/debian-he.git](https://github.com/johnaka1337/debian-he.git)
cd debian-he
bash install.sh --kernel-type=vanilla # the default is stock
```

### TODO
* Develop an automated deployment script for system-level configurations (sysctl, firewall, etc.).


### Contributing
Contributions, suggestions, and advice are always welcome! Feel free to open an issue or submit a pull request.

 EOF
