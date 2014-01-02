require "ipaddr_range_set/version"

require 'ipaddr'

class IPAddrRangeSet
  
  # Zero or more segment arguments, which can be input in a variety of
  # of formats. 
  # range = IPAddrRangeSet.new(
  #    '220.1.10.3',    # a single IPv4 as a string
  #    '2001:db8::10',  # a single IPv6 as a string
  #    '8.0.0.0/24',    # IPv4 as CIDR, works for IPv6 CIDR too
  #    '8.*.*.*',       # informal splat notation, only for IPv4
  #    '8.8.0.0'..'8.8.2.255', # arbitrary range, works for IPv6 too. 
  #    IPAddr.new(whatever),   # arbitrary existing IPAddr object
  #    (ip_addr..ip_addr),     # range of arbitrary IPAddr objects.
  #    IPAddrRangeSet::LocalAddresses    # An existing IPAddrRangeSet
  # )
  def initialize(*segments_list)        
    
    segments_list.each do |segment|
      
      if IPAddrRangeSet === segment
        # just absorb em
        segments.concat segment.segments
        next
      end
      
      if IPAddr === segment
        segment.freeze
        segments << segment
        next
      end
      
      if Range === segment
        first = segment.first
        last = segment.last
        
        first = IPAddr.new(first) unless first.kind_of? IPAddr
        last = IPAddr.new(last) unless last.kind_of? IPAddr
        
        segments << Range.new(first, last, segment.exclude_end?).freeze   
        next
      end

      
      segment = segment.to_str
      
      # special splat processing? eg '124.*.*.*' ipv4 only.
      # Convert to ordinary 'a.b.c.d/m' CIDR notation. 
      if segment.include?('*') && segment =~ /(\d{1,3}|\*\.){3}\d{1,3}|\*/
        octets = segment.split('.')
                
        if (octets.rindex {|o| o =~ /\d+/}) > octets.rindex("*")
          raise ArgumentError.new("Invalid splat range, all *s have to come before all concrete octets")
        end
                
        splats = 0
        base = octets.collect do |o|
          if o == '*'
            splats += 1
            '0'
          else
            o
          end          
        end.join(".")        
        
        prefix_size = 32 - (8 * splats)                
        segments << IPAddr.new("#{base}/#{prefix_size}")        
        
        next
      end
      
      segments << IPAddr.new(segment)              
    end        
  end
  
  # Does the range set include the argument?
  # Can pass in IPAddr or string IP addr (that will be used as arg to IPAddr.new)
  #
  # Aliased as #=== (for case/when!) and cover?
  def include?(ip_addr)
    ip_addr = IPAddr.new(ip_addr) unless ip_addr.kind_of? IPAddr
  
    segments.each do |segment|
      # important to use cover? and not include? on Ranges, to avoid
      # terribly inefficient check. But if segment is an IPAddr, you want include?
      if segment.respond_to?(:cover?)
        return true if segment.cover? ip_addr
      else
        return true if segment.include? ip_addr
      end        
    end
    
    return false    
  end
  alias_method :cover?, :include?
  alias_method :'===', :include?
  
  # Returns a NEW IPAddrRangeSet composed of union of segments
  # in receiver and argument.  Aliased as `+`
  #
  # IPAddrRangeSets are immutable. 
  def union(other_set)
    self.class.new(self, other_set)
  end
  alias_method :'+', :union
  
  # Returns a NEW IPAddrRangeSet composed of union of receiver,
  # and additional segments(s) given as arguments. 
  # IPAddrRangeSet is immutable. 
  def add(*new_segments)
    return self + IPAddrRangeSet.new(*new_segments)
  end
  
  
  protected
  
  # Not public API, but used for creating unions of range sets,
  # etc., is why it's protected instead of private
  def segments
    @segments ||= []
  end
   
  
end

class IPAddrRangeSet
  # Constant ranges for local/non-routable/private addresses
  IPv4Local     = IPAddrRangeSet.new("10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16")
  # who knew it's not just 127.0.0.1? Check the spec, it's this:
  IPv4Loopback  = IPAddrRangeSet.new("127.0.0.0/8")
  
  IPv6Local = IPAddrRangeSet.new("fc00::/7")
  IPv6Loopback =  IPAddrRangeSet.new("::1")
  
  LocalAddresses = IPv4Local + IPv4Loopback + IPv6Local + IPv6Loopback 
end
