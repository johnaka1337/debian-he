# Debian Home Edition
### Overview
> This repository provides a streamlined set of **Debian kernel and system configurations** specifically tailored for **modern desktop and home systems (2020+)**.
> The core philosophy of this project is built upon two pillars: **minimalism** and **security**. We aim to deliver a clean, efficient, and hardened base system that is fast, stable, and ready for daily use without unnecessary bloat.

## HowTo / Install / Usage

### Preparing
#### Install requirements (as `root` user)
```
:~# apt install build-essential xz-utils git sbsigntool dkms libncurses-dev flex bison debhelper bc libdw-dev libssl-dev rsync
```

#### Download project
```
:~$ mkdir prj
:~/prj$ cd prj/
:~/prj$ git clone https://github.com/johnaka1337/debian-he.git
```

#### Prepare your MOK (as `root` user)
```
:~/prj$ su -l   # or sudo -i
:~# # mkdir -p /var/lib/dkms  # should be already created via the dkms package
:~# cp /home/user/prj/debian-he/var/lib/dkms/*.sh /var/lib/dkms
:~# cd /var/lib/dkms
:/var/lib/dkms# chmod +x *.sh
:/var/lib/dkms# generate_keys.sh
:/var/lib/dkms# mokutil --import mok.pub  # input simple password, needed after reboot
```

#### Download latest stable kernel release
```
:~/prj$ wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.19.5.tar.xz
```

#### Unpack
```
:~/prj$ unxz linux-6.19.5.tar.xz
:~/prj$ tar -xf linux-6.19.5.tar
:~/prj$ mv linux-6.19.5/ linux-6.19.x/  # for applying patches
```

#### Apply kernel configuration and build
```
:~/prj$ cp debian-he/.config linux-6.19.x/
:~/prj$ cd linux-6.19.x/
:~/prj/linux-6.19.x$ make -j$(nproc) bindeb-pkg  # now you have 5-15min to make coffee :)
```


### Install and sign
#### Install new kernel (as `root` user)
```
:~/prj/linux-6.19.x$ su -l  # or sudo -i
:~# cd /home/user/prj/
:/home/user/prj$ dpkg -i *6.19.5*.deb
```

#### Sign new kernel
```
:~# cd /var/lib/dkms
:/var/lib/dkms# ./sign_kernel.sh
:/var/lib/dkms# systemctl reboot --force
```
