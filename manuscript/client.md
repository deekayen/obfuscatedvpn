# Mac OS X client configuration

W> Most of the configuration in this chapter requires administrative access to your Mac.

Install [Homebrew](http://brew.sh/). It is a software installation utility that gives you access to software normally available in a comparable Linux server. The specific command to install Homebrew occasionally changes as the project evolves, so be sure to check the official site for the latest install method.

{title="Example Homebrew install command", lang=bash}
    ruby -e "$(curl -fsSL \
    https://raw.githubusercontent.com/Homebrew/install/master/install)"

Install python since that's what the `obfsproxy` software is written in. Without python, the `obfsproxy` scripts won't have an interpreter to parse its code.

{lang=bash}
    brew install python

Install `obfsproxy` using the python-based `pip` manager.

{lang=bash}
    pip install obfsproxy

## Download certificate files

The authentication to your OpenVPN server won't use a username and password, rather it uses certificate files. The files you need are located on your server at `/etc/openvpn/easy-rsa/2.0/keys`. You'll need `ca.crt`, `macbook.crt`, and `macbook.key`. The `macbook` files should follow whatever name you used for the client certificate generation in the previous chapter.

Also copy the static key file at `/etc/openvpn/ta.key`.

T> The certificate files are not binary, so you may use your favorite terminal-based editor to copy the contents into new files on your Mac, otherwise, you can use a file download utility like [FileZilla](https://filezilla-project.org/) (free) to download the files to your Mac.
T>
T> ![FileZilla showing needed certificate files](images/filezilla.png)

## Create obfsproxy AppleScripts

Create some AppleScripts on your Mac using AppleScript Editor, also posted as a [GitHub Gist](https://gist.github.com/deekayen/17d119254c33982cb7fe). The AppleScript Editor application is installed by default on every Mac.

![obfsproxy obfs3 AppleScript](images/obfsproxy_obfs3_scpt.png)

{lang=AppleScript}
<<[Mac OS client AppleScript for The Threebfuscator](code/obfsproxy_obfs3.scpt)

{lang=AppleScript}
<<[Mac OS client AppleScript for ScrambleSuit](code/obfsproxy_scramblesuit.scpt)

## Install Viscosity

[Viscosity](http://www.sparklabs.com/viscosity/) is the clear winner for managing OpenVPN connections on a Mac. It's well worth the license fee in time-saved for setting up connections.

Create a new connection in the Preferences window of Viscosity to setup your connection information.

![Create a new connection](images/viscosity_preferences.png)

The general tab has IP and port information for your server. Though OpenVPN will be available on 3 different ports for your server, you'll want to create a separate connection in Viscosity for the different services you'll have available on your server. Remember TCP port 80 will use `obfs3`, TCP port 443 use ScrambleSuit, and TCP port 1194 traditional OpenVPN.

## Configure standard OpenVPN connection

![Viscosity standard OpenVPN general settings](images/viscosity_standard_general.png)

![Viscosity obfs3 authentication settings](images/viscosity_obfs3_authentication.png)

![Viscosity obfs3 options settings](images/viscosity_obfs3_options.png)

After the connection is setup, click the Viscosity icon in the menu bar and select your new connection to try the standard OpenVPN option. To test success, try searching for "[what is my ip](https://duckduckgo.com/?q=what+is+my+ip)" with your favorite search engine. You could also use the `traceroute` utility in iTerm.

![Traceroute for OpenVPN Linode in Dallas](images/dallas_traceroute.png)

Test DNS with the `dig` utility. You should see the virtual IP address of your OpenVPN network as the DNS server, served by `dnsmasq`.

![DNS test showing 10.9.0.1](images/openvpn_dig.png)

T> Once you have imported your certificate files and AppleScripts to the connection preferences, you can move or delete the original files. Viscosity copies and saves the files separately to its own Application Support folder.
T>
T> ![Viscosity Application Support connection preferences folder](images/viscosity_application_support.png)

## Configure obfs3 connection

You can start this connection by choosing the *Duplicate Connection* option in Viscosity. That will pre-configure the certificates and IP address for the obfs3 connection.

![Viscosity obfs3 general settings](images/viscosity_obfs3_general.png)

![Viscosity obfs3 authentication settings](images/viscosity_obfs3_authentication.png)

![Viscosity obfs3 options settings](images/viscosity_obfs3_options.png)

For the proxy settings to work for `obfsproxy`, the networking needs to directly route through your local network gateway instead of trying to tunnel through the VPN. The `obfsproxy` client needs to connect first before trying to tunnel through it, which is accomplished by setting a static network route.

For a VPN server address of `173.255.202.129`, set a static route as follows.

![Viscosity obfs3 networking settings](images/viscosity_obfs3_networking.png)

Set the Proxy address to SOCKS at 127.0.0.1 port 2222, the same as what the AppleScript is setup to use.

![Viscosity obfs3 proxy settings](images/viscosity_obfs3_proxy.png)

Add the AppleScript to the "Before Connection Script" in the Advanced tab of the OpenVPN configuration. Using a port below 1024 requires sudo, so I picked a higher port.

![Viscosity obfs3 advanced settings](images/viscosity_obfs3_advanced.png)

## Configure ScrambleSuit

For [ScrambleSuit](https://kryptera.se/wp-content/uploads/2014/02/ScrambleSuit-A-Polymorphic-Network-Protocol-to-Circumvent-Censorship.pdf), follow a similar procedure as for obfs3. Duplicate the OpenVPN connection so that the pre-connection script.

![ScrambleSuit AppleScript](images/obfsproxy_scramblesuit_scpt.png)

The ScrambleSuit proxy needs to connect to a different port than obfs3. The connection port from the server configuration chapter used port 443.

![Viscosity ScrambleSuit general settings](images/viscosity_scramblesuit_general.png)

I configured ScrambleSuit to use a different proxy port than obfs3.

![Viscosity ScrambleSuit proxy settings](images/viscosity_scramblesuit_proxy.png)

Update the cloned obfs3 pre-connection script to use the ScrambleSuit script, which includes the password you generated and saved to the `obfsproxy` startup command in `/etc/rc.local` on your VPN server.

![Viscosity ScrambleSuit advanced settings](images/viscosity_scramblesuit_advanced.png)

