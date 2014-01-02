ipaddr_range_set
================
[![Build Status](https://travis-ci.org/jrochkind/ipaddr_range_set.png)](https://travis-ci.org/jrochkind/ipaddr_range_set)
[![Gem Version](https://badge.fury.io/rb/ipaddr_range_set.png)](http://badge.fury.io/rb/ipaddr_range_set)


convenience class to create a set of possibly discontiguous IP address range
segments, and check if an IP address is in the set. ruby 1.9.3+ only. 

Ruby stdlib [IPAddr](http://www.ruby-doc.org/stdlib-1.9.3/libdoc/ipaddr/rdoc/IPAddr.html) 
does the heavy-lifting, this is relatively simple code wrapping it
in a convenience class. But this can simplify your own code when used. 
Basing logic on IP address range checking can often be the sign of a bad design, 
but many of us have to do it anyway.  

## Usage

### Creating

    require 'ipaddr_range_set'
    
    # Zero or more segment arguments, which can be input in a variety of
    # of formats. 
    range = IPAddrRangeSet.new(
      '220.1.10.3',    # a single IPv4 as a string
      '2001:db8::10',  # a single IPv6 as a string
      '8.0.0.0/24',    # IPv4 as CIDR, works for IPv6 CIDR too
      '8.*.*.*',       # informal splat notation, only for IPv4
      '8.8.0.0'..'8.8.2.255', # arbitrary range, works for IPv6 too. 
      IPAddr.new(whatever),   # arbitrary existing IPAddr object
      (ip_addr..ip_addr),     # range of arbitrary IPAddr objects.
      IPAddrRangeSet::LocalAddresses    # An existing IPAddrRangeSet
    )

Ranges and splats are handled by this gem (in terms of underlying IPAddr), other strings
passed directly to IPAddr constructor. 

When ruby Range's are used, IPAddrRangeSet makes sure to use `Range#cover?`
internally, not `Range#include?` (the latter being disastrous for anything that
doesn't have `#to_int`).  Triple dot `...` exclusive endpoint ranges are 
supported, which can be convenient if you don't like writing lots of `255`s
in your range end points. 

### Checking

And then, once you have an IPAddrRangeSet, you can check if a particular
ip is in the range set, using string (IPv4 or v6) or IPAddr instance:

    range.include?  '220.1.10.5'
    range.include?  IPAddr.new('220.1.10.5')
    
`#include?` is aliased as `#===` so you can easily use it in `case/when`.  


### Immutable, but create new with union of existing
    
IPAddrRangeSets are immutable, but you can create new ones combining existing
ranges:

    new_range = IPAddrRangeSet('8.10.5.1') + IPAddrRangeSet('8.11.6.1')
    new_range = IPAddrRangeSet('8.10.5.1').add('8.0.0.0/24', '10.0.0.1'..'10.1.4.255' )
    
The internal implementation just steps through all range segments and checks
the argument for inclusion, there's no special optimization to detect overlapping
ranges and simplify them.  If you are doing a high enough volume of segment/arg
checks that you need performance, you probably need a custom implementation
involving a search tree of some kind anyway. 

As above range 'union' is supported, but range intersection is not. It's 
a bit tricky to implement well, and I don't have a use case for it. 

## Built-in ranges for checking local addresses

Built-in constants are available for local (private, not publically routable)
and loopback ranges in both IPv4 and IPv6.   `IPAddrRangeSet::IPv4Local`, `IPv4Loopback`, `IPv6Local`, 
`IPv6Loopback`.  The constant `LocalAddresses` is the union of all v4 and v6 local 
and loopback addresses. 

    IPAddrRangeSet::LocalAddresses.include? "127.0.0.1" # true
    IPAddrRangeSet::LocalAddresses.include? "10.0.0.1" # true
    IPAddrRangeSet::LocalAddresses.include? "192.168.0.1" # true
    IPAddrRangeSet::LocalAddresses.include? "::1" # true, ipv6 loopback
    IPAddrRangeSet::LocalAddresses.include? "fc00::1" # an ipv6 local
    
## Note on ipv6

It supports ipv6 just because it was so easy to do so with the underlying
IPAddr implementation.  But I don't have much experience or use for IPv6, there
could be oddities hiding in there. 

You can create an IPAddrRangeSet that includes both IPv4 and IPv6 segments, no
problem. But an individual `include?` argument will only match a segment of
it's own type, no automatic conversion of IPv4-compatible IPv6 addresses
is done (should it be? I have no idea, don't really understand ipv6 use cases). 

## thanks

to whoever wrote IPAddr in ruby stdlib, nice to have it, this is just a
convenience wrapper over it, really. 
