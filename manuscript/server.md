# Debian server configuration

## Anonymizing yourself

At the time you register for your [Linode](https://www.linode.com/?r=1784f2516a909b1cd5d1e90d2dcfa43b176e4f8e) account, it's possible for you to anonymize yourself by doing things like register using the anonymous [Tor Browser](https://www.torproject.org/projects/torbrowser.html.en), use fake contact information, pay with a pre-paid debit card purchased with cash, and get your e-mail notifications through [mailinator.com](http://mailinator.com/). These measures may have limited success, because if you're the only one that ever connects to your VPN server, it shouldn't be hard to trace back your identity, especially if you connect frequently from your house.

I> Tor Browser protects you by bouncing your communications around a distributed network of relays run by volunteers all around the world: it prevents somebody watching your Internet connection from learning what sites you visit, it prevents the sites you visit from learning your physical location, and it lets you access sites which are blocked by your Internet providers.

You could share your VPN server with trusted friends to spread out the tracability of your server, but ultimately you still need to consider that it won't be impossible to trace back a Linode's ownership to you

## Leasing a Linode

Sign up for an account at [Linode](https://www.linode.com/?r=1784f2516a909b1cd5d1e90d2dcfa43b176e4f8e). Then navigate to the [Linode Manager](https://manager.linode.com) to add a Linode to your account. The smallest server is plenty large enough for an OpenVPN server.

![](images/add_a_linode.png)

Setting the location to a city closest to your home may be the best option to keep a fast Internet connection. Linode has a [speed test](https://www.linode.com/speedtest) so you can test which datacenter is best for you. A ping or traceroute may be quicker and easier than downloading a whole 100M file

{title="Average ping time from North Georgia, USA"}
| Datacenter | Ping in milliseconds |
|------------|---------------------:|
| Atlanta    | 16                   |
| Dallas     | 38                   |
| Newark     | 55                   |
| Fremont    | 89                   |
| London     | 103                  |
| Tokyo      | 185                  |

If I choose to host a VPN server in Tokyo from Georgia, I'm probably adding 400ms on average to every webpage I load. Latency like this would be most annoying when doing system administration and having a 0.5 second lag on anything I type in my SSH connection.

You may prefer instead to choose a server location in Japan in hopes that the NSA has a harder time keeping track of what's going on there than servers physically located in the United States.

W> Linode's headquarters is in New Jersey, so locating your server in Japan doesn't exclude you from US-based Linode complying with a US subpoena or [national security letter](https://en.wikipedia.org/wiki/National_Security_Letter) if you do questionable things through your VPN server.

T> ### Streaming television restrictions
T>
T> Providers of streaming television programming like Netflix and Hulu have restrictions on which countries can view their video content. If you plan on using these kinds of services over your private connection, you should get a server located in the United States, not the UK or Japan.

### Deploy a distro

In the Linode Manager, click to view the dashboard for your newly created instance. In the primary dashboard tab, click the *Deploy a Linux Distribution* link to create a virtual machine.

![Linode dashboard](images/deploy_a_linux_distribution.png)

Since I prefer Debian-based distributions, this guide is based on Debian 7 (Wheezy). I select the 512MB option for a swap space boost. OpenVPN won't consume anywhere near 20GB of space or 512MB of swap with just one user. A fully operational OpenVPN server, including the operating system, consumes about 675MB.

T> #### Reserving space for backup restoration
T>
T> If you activate the Linode backup service and need to do a restore, you'll want to keep some space in your Linode to do that. Just deploy 11776MB for your disk image and 512MB for swap. That will only consume exactly half your available space and leave you room to quickly restore an older disk image without re-sizing images or restoring to a second virtual machine.

![Deploy a Linux Distribution](images/deploy_distribution_selection.png)

Deploying the VM doesn't boot it, so you'll still need to click the Boot button on the Dashboard tab of Linode Manager.

![Click the Boot button](images/boot_vm.png)

### Install iTerm2

Normally Apple's built-in Terminal app would be enough to configure a server without extra software on the Mac side, but [iTerm2](http://iterm2.com/) is used later in this tutorial with some AppleScripts to automatically create a local proxy service. Now would be a good time to get it installed and get it configured the way you like it.

T> #### David's iTerm setup
T>
T> In case you see something you like, I use the [Tomorrow Night](https://github.com/ChrisKempson/Tomorrow-Theme) theme, the [Source Code Pro](http://store1.adobe.com/cfusion/store/html/index.cfm?event=displayFontPackage&code=1960) font, and [oh-my-zsh](http://ohmyz.sh/) for a shell. My `.zshrc` is set to the `gallifrey` theme.

The Remote Access tab has the information you need to connect to your server over SSH.

![Connect to VM by SSH](images/connect_to_vm.png)

T> ## Linode Getting Started guide
T>
T> Linode also has a guide on [Getting Started](https://www.linode.com/docs/getting-started/), including provisioning the Linode, booting it, connecting, setting a hostname, configuring the timezone, and installing updates.

## Install Debian security updates

To make sure bots and kids with nothing better to do don't exploit my fresh server, the first thing to do is install security updates and block persistent SSH login attempts.

{lang=bash}
    apt-get update

    apt-get upgrade

    apt-get install denyhosts

I prefer denyhosts, but fail2ban is also popular for SSH protection. Both of them block computers that make persistent attempts to guess passwords to login and take over the server.

## Set a hostname

{lang=bash}
    echo "obfsproxy" > /etc/hostname

## Setup OpenVPN

One command gets OpenVPN installed. The installer will configure OpenVPN to automatically stat when you reboot your server.

{lang=bash}
    apt-get install openvpn

OpenVPN uses SSL. SSL works based on a system of exchanging certificate files. Easy-RSA is the package OpenVPN uses to generate the files needed for the OpenVPN public key infrastructure.

The easy-rsa scripts are located by default in the `/usr/share/doc/openvpn/examples/easy-rsa/` directory, but the most common configurations copy them to the `/etc/openvpn` directory. Copy the easy-rsa files:

{lang=bash}
    cp -R /usr/share/doc/openvpn/examples/easy-rsa/ /etc/openvpn

The only directory this guide uses in easy-rsa is `/etc/openvpn/easy-rsa/2.0/`. You will create several files in the `2.0` directory used to create the handshake between the OpenVPN server and client.

Change directories to `/etc/openvpn/easy-rsa/2.0/`:

{lang=bash}
    cd /etc/openvpn/easy-rsa/2.0/

Create a symbolic link from openssl-1.0.0.cnf to openssl.cnf:

{lang=bash}
    ln -s openssl-1.0.0.cnf openssl.cnf

Optionally, edit the `vars` script to change the `KEY_SIZE` from 1024 to 2048. Increasing the key size will slow down TLS negotiation and the one-time DH parameter generation process. In other words, it will take a little longer to connect to your OpenVPN server.

W> ## File naming
W>
W> The key size makes a difference in later file naming. Later instructions will refer to a file named `dh2048.pem`, but if you don't change the `KEY_SIZE`, it will be named `dh1024.pem`.

{lang=bash}
    nano vars

Execute the `vars` script:

{lang=bash}
    chmod 755 vars

    ./vars

    source ./vars

This will return

`NOTE: If you run ./clean-all, I will be doing a rm -rf on /etc/openvpn/easy-rsa/2.0/keys`

Execute the `clean-all` script. If you mess up when creating keys, the `clean-all` script removes the mistaken ones for you.

{lang=bash}
    ./clean-all

Execute the `build-ca` script. At each prompt, make up a value. It's likely you'll be the only person who ever knows the values of the `ca` certificate because nobody else will care.

{lang=bash}
    ./build-ca

The next command generates a private key for the server.

{lang=bash}
    ./build-key-server server

Make up more values for the key, but leave the challenge password and company names blank. Answer `y` to the questions.

Generating certificates for clients is through a different script, but a similar process as with the server. The client certificates are the equivalent of the username and password. Since you won't have a login, these certificates should be protected as if they were login credentials.

{lang=bash}
    ./build-key macbook

Create as many client keys as you need. If you want to connect with your phone, tablet, computer, and router, make four certificates.

Though generating a Diffie-Hellman parameters file isn't required for a working connection, it helps create a more secure key exchange when connecting to the server. Generate a file with just one command.

{lang=bash}
    ./build-dh

Change directory to `keys` and copy the generated files to the main OpenVPN configuration location.

{lang=bash}
    cd /etc/openvpn/easy-rsa/2.0/keys

    cp ca.crt ca.key dh2048.pem /etc/openvpn

    cp server.crt server.key /etc/openvpn

    cd /etc/openvpn

    openvpn --genkey --secret ta.key

Create a file at `/etc/openvpn/tcp.conf` with the following contents:

{title="File excerpt: `/etc/openvpn/tcp.conf`", lang=text}
    port 1194
    proto tcp
    dev tun
    ca ca.crt
    cert server.crt
    key server.key
    dh dh2048.pem
    server 10.9.0.0 255.255.255.0
    ifconfig-pool-persist ipp.txt
    push "redirect-gateway def1 bypass-dhcp"
    push "dhcp-option DNS 10.9.0.1"
    push "dhcp-option DNS 72.14.179.5"
    push "dhcp-option DNS 72.14.188.5"
    push "dhcp-option DNS 8.8.8.8"
    push "dhcp-option DNS 8.8.4.4"
    push "dhcp-option DNS 208.67.222.222"
    push "dhcp-option DNS 208.67.220.220"
    client-to-client
    keepalive 15 120
    tls-auth ta.key 0
    cipher BF-CBC
    comp-lzo
    user nobody
    group nogroup
    persist-key
    persist-tun
    status openvpn-status.log
    verb 2

T> OpenVPN will also read a `udp.conf` file if you create one. If you copy `tcp.conf` to `udp.conf` and change `proto tcp` to `proto udp`, OpenVPN will also offer VPN service on UDP port 1194 in addition to TCP port 1194.

OpenVPN can either block clients from talking to each other or leave access so clients can form a virtual, remote private LAN. The `client-to-client` option should only be used if you trust the other users on your OpenVPN server. It will allow you to share files with each other.

Many `cipher` options are available for use after the initial key exchange: DES, RC2, 3DES, Blowfish, CAST5, AES, Camellia, and Seed. BF-CBC is the default setting and since I still wonder if there is a secret backdoor key in AES, I avoid that popular option when possible. See also: [Skipjack](https://en.wikipedia.org/wiki/Skipjack_(cipher)).

OpenVPN's normal connection occurs on port 1194. Any network administrator investigating network traffic on that port will discover the link to OpenVPN. Later, obfsproxy will be configured to use ports 80 and 443. Even the most strict public networks usually allow HTTP and HTTPS over TCP network access.

The first `dhcp-option DNS` is set to the local OpenVPN tunnel address. Later instructions will configure a lightweight DNS server to respond to those queries. Each Linode datacenter has different secondary and tertiary servers.

![Dallas DNS resolvers](images/dns_resolvers.png)

Locate your Linode DNS resolvers in the Linode Manager Remote Access tab and set those as the values for the second, third, or even fourth `dhcp-option DNS`.

### OpenVPN-related setup

Edit `/etc/sysctl.conf` to allow the server to forward IPv4 traffic by uncommenting the following line:

{lang=text}
    net.ipv4.ip_forward=1

To turn on forwarding without rebooting the server, you can issue a command directly to the network process:

{lang=bash}
    echo 1 > /proc/sys/net/ipv4/ip_forward

Add some firewall rules to `/etc/rc.local` just before the line with `exit 0`:

{lang=text}
    # OpenVPN firewall rules
    iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
    # TCP forwarding
    iptables -A FORWARD -s 10.9.0.0/24 -j ACCEPT
    iptables -A FORWARD -j REJECT
    iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
    iptables -t nat -A POSTROUTING -s 10.9.0.0/24 -o eth0 -j MASQUERADE
    iptables -A INPUT -i tun+ -j ACCEPT
    iptables -A FORWARD -i tun+ -j ACCEPT
    iptables -A INPUT -i tap+ -j ACCEPT
    iptables -A FORWARD -i tap+ -j ACCEPT

The `iptables` commands can be run directly at the terminal, too, to get that part working without rebooting. Adding them to `/etc/rc.local` makes sure they're set automatically after reboot.

## Setup local DNS masquerading

The OpenVPN server can also answer DNS queries by using `dnsmasq`. If you skip this step, remove `10.9.0.1` as a DNS option from `/etc/openvpn/tcp.conf`.

{lang=bash}
    apt-get install dnsmasq resolvconf

Then edit the `dnsmasq` configuration file.

{lang=bash}
    nano /etc/dnsmasq.conf

{title="File excerpt: `/etc/dnsmasq.conf`", lang=text}
    listen-address=127.0.0.1,10.9.0.1

    bind-interfaces

The file at `/etc/network/interfaces` needs two additional configuration lines for `dns-search` and `dns-nameservers`. This shows the DNS nameservers for the Japan datacenter, copied from the earlier screenshot used for OpenVPN's `tcp.conf`.

{title="File excerpt: `/etc/network/interfaces", lang=text}
    auto lo
    iface lo inet loopback

    allow-hotplug eth0
    iface eth0 inet dhcp

    dns-search members.linode.com
    dns-nameservers 106.187.34.20 106.187.35.20 106.187.36.20 2400:8900::2 2400:8900::3

Finally, since the `openvpn` and `dnsmasq` processes conflict when the VM boots, `dnsmasq` needs to be restarted in in `rc.local` *after* the `iptables` rules and *before* `exit 0`.

{title="File excerpt, excluding `iptables`: `/etc/rc.local`", lang=text}
    /etc/init.d/dnsmasq restart

    exit 0

T> ## Linode OpenVPN guide
T>
T> Linode also hosts an online [OpenVPN configuration guide](https://www.linode.com/docs/networking/vpn/secure-communications-with-openvpn-on-ubuntu-12-04-precise-and-debian-7), but is sprinkled with errors and omissions. If you found this guide hard to follow, the Linode guide may still provide alternative clarification.

## Setup obfsproxy

Debian 7 includes obfsproxy 0.1.4 as an option in the default apt repositories, but all the latest obfuscations (obfs3 and scramblesuit) were added in obfsproxy 0.2.6. Add the Tor project repositories to get the latest stable version. Adapted instructions from [Tor's Debian/Ubuntu instructions](https://www.torproject.org/docs/debian.html.en) are as follows:

    echo "deb http://deb.torproject.org/torproject.org wheezy main" >> \
    /etc/apt/sources.list.d/tor.list

    gpg --keyserver keys.gnupg.net --recv 886DDD89

    gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | apt-key add -

    apt-get update

    apt-get install obfsproxy

![Add the Tor repository](images/add_tor_repo.png)

Many additional python packages will be required to install `obfsproxy`.

Edit `/etc/rc.local` to add the `obfsproxy` commands to the list of startup actions when the server reboots. Insert them before the `exit 0`.

{lang=text}
    obfsproxy obfs3 --dest=127.0.0.1:1194 server 0.0.0.0:80 &

    obfsproxy scramblesuit --password QSCOXXUSXELBRT5SS2B54WCEQWSADY5L \
    --dest=127.0.0.1:1194 server 0.0.0.0:443 &

The ScrambleSuit password needs to be base32, so [create a string or hash a file with SHA-1](https://www.ssl-id.de/hash.jpkc.net/) to produce a 40 character hash, then [convert](http://tomeko.net/online_tools/hex_to_base32.php?lang=en) the hex SHA-1 hash to base32. The input hex value needs to be a length in multiples of 40. Since SHA-1 always produces a 40-character hex string, it's a convenient solution to feed the base32 converter. RIPEMD-160 would also produce 40-characters of hexadecimal digits if you prefer academic hashes to government ones.

X> ## Reverse engineering the password
X>
X> In case you would like to reproduce the hash value I provided here on your own, the source string I started with as the source of the SHA-1 hash was "Don't use this hash."

## Unattended upgrades

Keep your server current with the latest security (and other) updates automatically. To setup automatic updates, run these commands as root:

{lang=bash}
    apt-get install unattended-upgrades apt-listchanges

    dpkg-reconfigure -plow unattended-upgrades

Choose Yes for the `dpkg_reconfigure` prompt.

See: https://wiki.debian.org/UnattendedUpgrades

## Longview

Linode provides some basic charts for monitoring each of your Linodes. To get more sophisticated reporting about specific resources about each of the services running on your server, they have a client program to install on your server. They allow limited reporting (12 hours) for up to 10 virtual machines.

![Add Longview Client](images/add_longview_client.png)

Adding a client gives you a command to run on your server as `root`. If you're like me and manage personal servers by logging in as `root` instead of creating a separate user, omit `sudo` from the provided command.

{title="Longview example install command" lang=bash}
    curl -s https://lv.linode.com/M4E7 | sudo bash

In the 5-minute window following the installation of Longview, the Linode servers need to compile a few reports from your server before it can show statistics.

![Confusing interim message](images/welcome_to_longview.png)

Once the Longview reporting settles, the Overview tab for your VPN server should report CPU, load, memory, processes, network, and disk I/O.

![Longview overview](images/longview_overview.png)

## Remove exim4

Don't run services unless you need them. The more services your server runs, the larger the [attack surface](https://en.wikipedia.org/wiki/Attack_surface) for bots and script kiddies to exploit your server. If your server is just offering VPN services, removing `exim4` will prevent local mail delivery and routing.

{lang=bash}
    apt-get purge exim4 exim4-base exim4-config exim4-daemon-light

## Try starting OpenVPN

Starting OpenVPN manually at this point will expose if you have any misconfiguration.

{lang=bash}
    service openvpn start

![OpenVPN example failure](images/openvpn_fail.png)

## Reboot

Rebooting isn't strictly necessary, but doing so will confirm that any configuration you set so far will still work if you have to reboot the virtual machine.

![Linode Manager reboot button](images/linode_manager_reboot.png)

