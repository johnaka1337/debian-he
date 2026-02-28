# Debian-HE

### Overview
> This repository provides a streamlined set of **Debian kernel and system configurations** specifically tailored for **modern desktop and home systems (2020+)**.
> The core philosophy of this project is built upon two pillars: **minimalism** and **security**. We aim to deliver a clean, efficient, and hardened base system that is fast, stable, and ready for daily use without unnecessary bloat.

## Core Architecture
This configuration is designed around the capabilities of modern Linux kernels (6.19+). It eliminates legacy tuning parameters in favor of native kernel intelligence, specifically relying on the EEVDF scheduler for process management and lock-less networking queues for maximum throughput.

## Performance & Network Tuning
The network stack is heavily optimized to eliminate bufferbloat and reduce latency under load:
* **Congestion Control & AQM:** Utilizes Google's **BBR** combined with the **CAKE** queuing discipline. This setup guarantees stable RTT even on saturated Wi-Fi or Ethernet links.
* **TCP Stack Optimization:** Tuned buffer sizes, enabled TCP Fast Open (TFO), and restricted `tcp_notsent_lowat` to minimize queuing delay in the local stack.
* **MTU Probing:** Enabled to gracefully handle path MTU black holes without dropping connections.

## Security Hardening
The security model follows a defense-in-depth approach, restricting unprivileged access to kernel interfaces and securing the network layer:
* **Namespace Restrictions:** Modern AppArmor-based policies control unprivileged user namespaces (`kernel.unprivileged_userns_apparmor_policy`). Legacy cloning is disabled to significantly reduce the attack surface while maintaining compatibility with SUID sandboxes like Firejail.
* **Strict Routing:** Enforced strict Reverse Path Filtering (`rp_filter=1`) globally to drop spoofed packets. ICMP redirects and source routing are completely disabled.
* **Kernel Lockdown:** Restricted `dmesg` access, hidden kernel pointers (`kptr_restrict`), and limited `ptrace` scope to prevent unauthorized process memory inspection.
* **Stealth Firewall:** Designed to be paired with an `nftables` inbound "drop" policy to ensure the system remains invisible to unsolicited network probes.

## Deployment
