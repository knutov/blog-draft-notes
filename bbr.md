# Speed up and make more robust network with BBR

**BBR** (Bottleneck Bandwidth and RTT) is [TCP congestion control][wiki]. It computes the sending rate based on the delivery rate (throughput) estimated from ACKs.

[wiki]: https://en.wikipedia.org/wiki/TCP_congestion_control

BBR can significantly increase throughput and reduce latency for TCP connections:

- up to 25% on [Dobrohost](https://dobrohost.ru) production setup
- "up to 22% improvement" at [AWS](https://aws.amazon.com/ru/blogs/networking-and-content-delivery/tcp-bbr-congestion-control-with-amazon-cloudfront/)
- "up to 2,700x higher" - [Google Cloud blogpost](https://cloud.google.com/blog/products/networking/tcp-bbr-congestion-control-comes-to-gcp-your-internet-just-got-faster)
- "improves performance by 21%" at [Gumlet](https://www.gumlet.com/blog/tcp-bbr-vs-cubic-congestion-control/)
- "reduced median round-trip-time (RTT) of YouTube by 80%" - [link](https://www.sciencedirect.com/science/article/pii/S2405959520301296#bb2)

BBR is good for:

- Resilience to random loss (e.g. from shallow buffers):
- Low latency with the bloated buffers common in today’s last-mile links

BBR requires only changes on the sender side, not in the network or the receiver side.

BBRv1 is available from 4.9 kernel (with some issues) and is ok to use starting from approximately 4.13. It's good with Ubuntu 5.15 HWE kernel.

## Important issues

### Unfairness

BBRv1 is known to be unfair to other loss-based congestion algorithms and BBR traffic can dominate over non-BBR traffic in network. BBR can obtain more than 90% of the total bandwidth:

- https://blog.apnic.net/2020/01/10/when-to-use-and-not-use-bbr/
- https://www.ietf.org/proceedings/97/slides/slides-97-iccrg-bbr-congestion-control-02.pdf
- https://www.uio.no/studier/emner/matnat/ifi/INF5072/v18/inf5072_example1.pdf

### BBR must be used with the `fq` qdisc:

> BBR requires pacing. The Linux `fq_codel` qdisc does not implement pacing, so `fq_codel` would not be sufficient.
>
> So the note in the `tcp_bbr.c` code is still current and complete:
>
> > NOTE: BBR *must* be used with the fq qdisc ("`man tc-fq`") with pacing enabled, since pacing is integral to the BBR design and implementation. BBR without pacing would not function properly, and may incur unnecessary high packet loss rates.
>
> from <cite>https://groups.google.com/g/bbr-dev/c/4jL4ropdOV8/m/GyndlPWpAAAJ</cite>

**Update**: this can be no longer true, as https://wiki.geant.org/pages/releaseview.action?pageId=121340614 states:

> Linux 4.13 and above: In May 2017, Éric Dumazet submitted a patch to implement pacing in TCP itself, removing the dependency on the fq scheduler. This makes BBR is simpler to enable, and allows its use together with other schedulers (such as the popular fq_codel).

### BBR variants

There are multiple BBR variants and modifications, but most of them are not actual as of 2022:

- [BBR Advanced (BBR-A)](https://www.sciencedirect.com/science/article/pii/S2405959520301296), [github](https://github.com/imtiaztee/BBR-Advanced--BBR-A--Linux-Kernel-Code)
- tsunami, nanqinlang or bbrplus - [github](https://github.com/KozakaiAya/TCP_BBR)
- [bbrplus](https://github.com/cx9208/bbrplus) with [ports](https://github.com/UJX6N?tab=repositories&q=bbrplus) to newer kernels
- [An Evaluation of BBR and its variants](http://arxiv.org/pdf/1909.03673v1) (pdf)


## How to enable

`cubic` is used by default:

```bash
# sysctl net.ipv4.tcp_available_congestion_control
net.ipv4.tcp_available_congestion_control = reno cubic

#sysctl net.ipv4.tcp_congestion_control
net.ipv4.tcp_congestion_control = cubic
```

Check if we can enable BBR:

```bash
# cat /boot/config-$(uname -r) | grep 'CONFIG_TCP_CONG_BBR'
CONFIG_TCP_CONG_BBR=m

# cat /boot/config-$(uname -r) | grep 'CONFIG_NET_SCH_FQ'
CONFIG_NET_SCH_FQ_CODEL=m
CONFIG_NET_SCH_FQ=m
CONFIG_NET_SCH_FQ_PIE=m
```

Enabling BBR:

```bash
modprobe tcp_bbr

echo "tcp_bbr" >> /etc/modules-load.d/modules.conf

cat << 'EOF' >> /etc/sysctl.conf

# Enable BBR
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF

sysctl -p
```

### How to check if BBR is used?

```bash
sysctl net.ipv4.tcp_available_congestion_control
sysctl net.ipv4.tcp_congestion_control
lsmod | grep bbr
```

### How to monitor monitor TCP connections

`ss -ti` or `ss -tin`.

`ss` is "utility to investigate sockets":

- `-i` is for "Show internal TCP information"
- `-t` is for "Display TCP sockets".
- `-n` for numeric. "Show exact bandwidth values, instead of human-readable."

See `man ss` for details.

## BBRv2

BBRv2 is in alpha as on 2022 november - https://github.com/google/bbr/commits/v2alpha.

There are ready kernels with this patches:

- https://codeberg.org/pf-kernel/linux/wiki/README
- https://xanmod.org/
- https://liquorix.net/ (zen kernel) - https://launchpad.net/~damentz/+archive/ubuntu/liquorix
- https://github.com/CachyOS/linux-cachyos

But it looks like BBRv2 has some issues and is not ready for production:

- from march 2020: https://roov.org/2020/03/bbr-bbrplus-bbr2/ (use google translate )
- from may 2022: https://groups.google.com/g/bbr-dev/c/xmley7VkeoE/m/W4lEyyW_AAAJ
