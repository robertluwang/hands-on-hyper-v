
# hyper-v networking 
## type of networking
3 types:
- private - vm<->vm only
- internal - vm<->vm, vm<->host, vm->Internet if NAT enabled
- external - kind of bridge, vm<->host, vm->Internet
 
## private network 
It is isolated network, vm can access each other only.

## internal network 
It is private network plus host due to virtual NIC on host.

It is similar with Host-only in Virtualbox.

It could be further as NAT to allow vm to access Internet by adding internal network in NetNat, which solve the routing traffic to outside.

The Default Switch is internal NAT switch, the only issue is switch ip always changed after reboot; also DNS not working well. As remedy you can manually change vm ip and DNS inside vm, to match new change on Default Switch.

The good news is that it is possible to setup static NAT network, to have stable test lab env, which is host-only + NAT.

## external switch
External switch will bind with physical NIC on host, sharing same network with host to access outside, ip assigned from DHCP.

In my pc there is only Wi-Fi adaptor, so external switch will bind to Wi-Fi adaptor, it always crashed and lost all Wi-Fi Internet access during creating, have to recover by Network Reset.

Let's forget about external switch for wi-fi at all, since it will directly impact host network access.

Someone told me docking station could be to have external switch working stable due to ethernet adaptor from dock will function as native physical NIC.

This is [good video](https://www.youtube.com/watch?v=jdk6xCNmydU) to show hyper-v network types differences and possible to have stable dedicated external network for hyper-v by adding 2nd physical NIC, for example USB network adaptor, without impact host internet access.

## static NAT 
The Default Switch NAT ip dynamic changed, will be great if setup as static NAT following up [here](https://learn.microsoft.com/en-us/virtualization/hyper-v-on-windows/user-guide/setup-nat-network).

create own internal switch with static ip,
```

New-VMSwitch -SwitchName "myNATSW" -SwitchType Internal

Name    SwitchType NetAdapterInterfaceDescription
----    ---------- ------------------------------
myNATSW Internal                                 

Get-VMSwitch

Name           SwitchType NetAdapterInterfaceDescription
----           ---------- ------------------------------
Default Switch Internal                                 
myNATSW        Internal    
```
create vNIC, 
```
New-NetIPAddress -IPAddress 192.168.80.1 -PrefixLength 24 -InterfaceAlias 'vEthernet (myNATSW)'

IPAddress         : 192.168.80.1
InterfaceIndex    : 52
InterfaceAlias    : vEthernet (myNATSW)
AddressFamily     : IPv4
Type              : Unicast
PrefixLength      : 24
PrefixOrigin      : Manual
SuffixOrigin      : Manual
AddressState      : Tentative
ValidLifetime     : Infinite ([TimeSpan]::MaxValue)
PreferredLifetime : Infinite ([TimeSpan]::MaxValue)
SkipAsSource      : False
PolicyStore       : ActiveStore

IPAddress         : 192.168.80.1
InterfaceIndex    : 52
InterfaceAlias    : vEthernet (myNATSW)
AddressFamily     : IPv4
Type              : Unicast
PrefixLength      : 24
PrefixOrigin      : Manual
SuffixOrigin      : Manual
AddressState      : Invalid
ValidLifetime     : Infinite ([TimeSpan]::MaxValue)
PreferredLifetime : Infinite ([TimeSpan]::MaxValue)
SkipAsSource      : False
PolicyStore       : PersistentStore
```
create NAT for above internal switch,
```
New-NetNat -Name myNAT -InternalIPInterfaceAddressPrefix 192.168.80.0/24
Name                             : myNAT
ExternalIPInterfaceAddressPrefix : 
InternalIPInterfaceAddressPrefix : 192.168.80.0/24
IcmpQueryTimeout                 : 30
TcpEstablishedConnectionTimeout  : 1800
TcpTransientConnectionTimeout    : 120
TcpFilteringBehavior             : AddressDependentFiltering
UdpFilteringBehavior             : AddressDependentFiltering
UdpIdleSessionTimeout            : 120
UdpInboundRefresh                : False
Store                            : Local
Active                           : True
```
ipconfig
```
Ethernet adapter vEthernet (myNATSW):

   Connection-specific DNS Suffix  . : 
   Description . . . . . . . . . . . : Hyper-V Virtual Ethernet Adapter
   Physical Address. . . . . . . . . : 00-15-5D-17-01-04
   DHCP Enabled. . . . . . . . . . . : No
   Autoconfiguration Enabled . . . . : Yes
   Link-local IPv6 Address . . . . . : fe80::831a:b50c:82bc:cb35%52(Preferred) 
   IPv4 Address. . . . . . . . . . . : 192.168.80.1(Preferred) 
   Subnet Mask . . . . . . . . . . . : 255.255.255.0
   Default Gateway . . . . . . . . . : 
   DHCPv6 IAID . . . . . . . . . . . : 872420701
   DHCPv6 Client DUID. . . . . . . . : 00-01-00-01-2A-E5-3A-41-38-CA-84-54-73-1E
   DNS Servers . . . . . . . . . . . : fec0:0:0:ffff::1%1
                                       fec0:0:0:ffff::2%1
                                       fec0:0:0:ffff::3%1
   NetBIOS over Tcpip. . . . . . . . : Enabled
```
win11 vm, 
```
   C:\Users\oldhorse>ipconfig /all

Windows IP Configuration

   Host Name . . . . . . . . . . . . : DESKTOP-QE97US8
   Primary Dns Suffix  . . . . . . . :
   Node Type . . . . . . . . . . . . : Mixed
   IP Routing Enabled. . . . . . . . : No
   WINS Proxy Enabled. . . . . . . . : No

Ethernet adapter Ethernet 3:

   Connection-specific DNS Suffix  . :
   Description . . . . . . . . . . . : Microsoft Hyper-V Network Adapter
   Physical Address. . . . . . . . . : 00-15-5D-17-01-01
   DHCP Enabled. . . . . . . . . . . : No
   Autoconfiguration Enabled . . . . : Yes
   Link-local IPv6 Address . . . . . : fe80::a9ea:bfdd:b64c:ca49%7(Preferred)
   IPv4 Address. . . . . . . . . . . : 192.168.80.10(Preferred)
   Subnet Mask . . . . . . . . . . . : 255.255.240.0
   Default Gateway . . . . . . . . . : 192.168.80.1
   DHCPv6 IAID . . . . . . . . . . . : 285218141
   DHCPv6 Client DUID. . . . . . . . : 00-01-00-01-2A-F9-CC-96-08-00-27-92-7B-BA
   DNS Servers . . . . . . . . . . . : 8.8.8.8
   NetBIOS over Tcpip. . . . . . . . : Enabled

C:\Users\oldhorse>ping 8.8.8.8

Pinging 8.8.8.8 with 32 bytes of data:
Reply from 8.8.8.8: bytes=32 time=53ms TTL=106
Reply from 8.8.8.8: bytes=32 time=52ms TTL=106

Ping statistics for 8.8.8.8:
    Packets: Sent = 2, Received = 2, Lost = 0 (0% loss),
Approximate round trip times in milli-seconds:
    Minimum = 52ms, Maximum = 53ms, Average = 52ms
Control-C
^C
C:\Users\oldhorse>ping google.ca

Pinging google.ca [142.250.65.163] with 32 bytes of data:
Reply from 142.250.65.163: bytes=32 time=21ms TTL=106
Reply from 142.250.65.163: bytes=32 time=23ms TTL=106

Ping statistics for 142.250.65.163:
    Packets: Sent = 2, Received = 2, Lost = 0 (0% loss),
Approximate round trip times in milli-seconds:
    Minimum = 21ms, Maximum = 23ms, Average = 22ms
Control-C
^C
```
## reset NAT network if it changed
run in PS as admin,
```
Get-NetAdapter 'vEthernet (myNATSW)' | Get-NetIPAddress | Remove-NetIPAddress -Confirm:$False; New-NetIPAddress -IPAddress 192.168.80.1 -PrefixLength 24 -InterfaceAlias 'vEthernet (myNATSW)'; Get-NetNat | ? Name -Eq myNAT | Remove-NetNat -Confirm:$False; New-NetNat -Name myNAT -InternalIPInterfaceAddressPrefix 192.168.80.0/24
```
or run batch myNATSW-reset.bat in cmd as admin,
```
date /t
time /t
 
powershell -c "Get-NetAdapter 'vEthernet (myNATSW)' | Get-NetIPAddress | Remove-NetIPAddress -Confirm:$False; New-NetIPAddress -IPAddress 192.168.80.1 -PrefixLength 24 -InterfaceAlias 'vEthernet (myNATSW)'; Get-NetNat | ? Name -Eq myNAT | Remove-NetNat -Confirm:$False; New-NetNat -Name myNAT -InternalIPInterfaceAddressPrefix 192.168.80.0/24;"
 
date /t
time /t

pause
```
I never see static NAT switch ip touched by hyper-v like Default Switch, above remedy just keep as last shot.

## WSL NAT
WSL is also internal switch and for sure NAT, both hyper-v NAT and WSL working without conflict.
```
Get-NetNat

Name                             : WSLNat
ExternalIPInterfaceAddressPrefix : 
InternalIPInterfaceAddressPrefix : 172.26.128.0/20
IcmpQueryTimeout                 : 30
TcpEstablishedConnectionTimeout  : 1800
TcpTransientConnectionTimeout    : 120
TcpFilteringBehavior             : AddressDependentFiltering
UdpFilteringBehavior             : AddressDependentFiltering
UdpIdleSessionTimeout            : 120
UdpInboundRefresh                : False
Store                            : Local
Active                           : True

Name                             : myNAT
ExternalIPInterfaceAddressPrefix : 
InternalIPInterfaceAddressPrefix : 192.168.80.0/24
IcmpQueryTimeout                 : 30
TcpEstablishedConnectionTimeout  : 1800
TcpTransientConnectionTimeout    : 120
TcpFilteringBehavior             : AddressDependentFiltering
UdpFilteringBehavior             : AddressDependentFiltering
UdpIdleSessionTimeout            : 120
UdpInboundRefresh                : False
Store                            : Local
Active                           : True

Ethernet adapter vEthernet (WSL):

   Connection-specific DNS Suffix  . : 
   Description . . . . . . . . . . . : Hyper-V Virtual Ethernet Adapter #2
   Physical Address. . . . . . . . . : 00-15-5D-08-11-D4
   DHCP Enabled. . . . . . . . . . . : No
   Autoconfiguration Enabled . . . . : Yes
   Link-local IPv6 Address . . . . . : fe80::e63:3bc:8902:b76d%88(Preferred) 
   IPv4 Address. . . . . . . . . . . : 172.27.96.1(Preferred) 
   Subnet Mask . . . . . . . . . . . : 255.255.240.0
   Default Gateway . . . . . . . . . : 
   DHCPv6 IAID . . . . . . . . . . . : 1476400477
   DHCPv6 Client DUID. . . . . . . . : 00-01-00-01-2A-E5-3A-41-38-CA-84-54-73-1E
   DNS Servers . . . . . . . . . . . : fec0:0:0:ffff::1%1
                                       fec0:0:0:ffff::2%1
                                       fec0:0:0:ffff::3%1
   NetBIOS over Tcpip. . . . . . . . : Enabled
```
## multi NAT switch 
reboot pc, Default Switch, WSL and my own NAT myNATSW all seems up and working, interesting [discussion here](https://learn.microsoft.com/en-us/answers/questions/111248/windows-10-hyper-v-34default-switch34-question.html).

Default Switch and WSL keep changed after reboot, but my own MyNATSW looks like real static NAT network, that is what I am looking for.










