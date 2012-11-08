require 'test/unit'

require 'ipaddr_range_set'


class TestIpAddrRange < Test::Unit::TestCase

  def self.test_inclusion(label, argument, should_include, *should_not_include)
    self.send(:define_method , "test_#{label}"  ) do
      range = IPAddrRangeSet.new(argument)
      assert range.include?(should_include), "IPAddrRangeSet.new #{argument} should include? #{should_include}"
      
      should_not_include.each do | should_not|
        assert !range.include?(should_not), "IPAddrRangeSet.new #{argument} should NOT include? #{should_not}"
      end      
    end
  end
  
  # label (suitable for part of method name), then 
  # init argument, arg that should be included, 1 to more args that should not be included
  test_inclusion("single_ipv4_str", "128.220.0.1", "128.220.0.1", "128.220.0.2", "128.220.0.0" )
  test_inclusion("single_ipv4_obj", IPAddr.new("128.220.0.1"), "128.220.0.1", "128.220.0.2" )
  test_inclusion("single_ipv4_obj_obj", IPAddr.new("128.220.0.1"), IPAddr.new("128.220.0.1"), IPAddr.new("128.220.0.2") )

  test_inclusion("single_ipv6_str", "2607:f0d0:1002:51::4", "2607:f0d0:1002:51::4", "2607:f0d0:1002:51::5", "2607:f0d0:1002:51::3" )
  test_inclusion("single_ipv6_obj", IPAddr.new("2607:f0d0:1002:51::4"), "2607:f0d0:1002:51::4", "2607:f0d0:1002:51::5", "2607:f0d0:1002:51::3" )

  test_inclusion("test_ipv4_cidr", "128.220.10.1/24", "128.220.10.100", "128.220.9.255", "128.220.11.1" )

  test_inclusion("test_ipv6_cidr", "2001:db8::/50", "2001:db8::10", "2001:db7::", "2001:db9::" )  
  
  test_inclusion("ipv4_range_str", ("128.220.10.1".."128.220.11.255"), "128.220.11.10", "128.220.9.255", '128.220.12.1')
  test_inclusion("ipv4_range_obj", (IPAddr.new("128.220.10.1")..IPAddr.new("128.220.11.255")), "128.220.11.10", "128.220.9.255", '128.220.12.1')
  
  test_inclusion("ipv6_range_str", ("2001:db8::10".."2001:db8::15"), "2001:db8::12", "2001:db8::9", '2001:db8::16')
    
  
  test_inclusion("ipv4_range_str_exclusive_endpoint", ("128.220.10.1"..."128.220.11.255"), "128.220.10.1", "128.220.9.255", "128.220.11.255")

    
  def test_incompatible_range        
    # one ipv4 one ipv6. 
    
    # Somehow get this for free from ruby Range at the moment
    assert_raise ArgumentError do
      IPAddrRangeSet.new( ("128.220.0.1".."2001:db8::10") )
    end
    
    assert_raise ArgumentError do
      IPAddrRangeSet.new( (IPAddr.new("128.220.0.1").."2001:db8::10") )
    end
    
    assert_raise ArgumentError do
      IPAddrRangeSet.new(  (IPAddr.new("128.220.0.1")..IPAddr.new("2001:db8::10")) ) 
    end
  end
  
  def test_empty_set
    range = IPAddrRangeSet.new()
    
    assert ! range.include?("128.220.0.1")
    assert ! range.include?(IPAddr.new "128.220.0.1")
    assert ! range.include?(IPAddr.new "2001:db8::10")    
  end
  
  def test_splats
    range = IPAddrRangeSet.new("128.*.*.*")     
    
    assert range.include?("128.4.2.1")
    
    assert ! range.include?("127.0.0.1")
    
    assert ! range.include?("129.1.1.1")
  end
  
  def test_bad_input
    assert_raise(ArgumentError) {  IPAddrRangeSet.new("foo")}
    
    assert_raise(ArgumentError) {  IPAddrRangeSet.new("124.*")}
    
    # splats have to be at end  
    assert_raise(ArgumentError) {  IPAddrRangeSet.new("124.*.1.1")}
    
    # Not a valid ipv4, make sure we catch it on ranges
    assert_raise(ArgumentError) {  IPAddrRangeSet.new("124.999.1.1".."125.0.0.1") }
  end
  
  def test_multi_arg
    range = IPAddrRangeSet.new("128.220.1.1", "128.221.*.*", "128.222.0.0/16", ("128.223.1.0".."128.224.255.255"))
    
    assert ! range.include?("128.220.10.1")
    
    assert range.include?("128.220.1.1")
    assert range.include?("128.221.10.1")
    assert range.include?("128.222.10.1")
    assert range.include?("128.224.1.1")
    
    assert ! range.include?("128.225.0.0")
  end
  
  def test_union
    range = IPAddrRangeSet.new("128.220.1.1") + IPAddrRangeSet.new("128.225.1.1")
    
    assert range.include? "128.220.1.1"
    assert range.include? "128.225.1.1"
    
    assert ! range.include?("128.222.1.1")
  end
  
  def test_add
    range = IPAddrRangeSet.new("128.220.1.1")
    
    new_range = range.add("128.225.1.1", "128.230.1.1")
    
    assert new_range.include? "128.220.1.1"
    assert new_range.include? "128.225.1.1"
    assert new_range.include? "128.230.1.1"
    
    assert ! new_range.include?("128.226.1.1")
    
  end
  
  def test_local_constants
    %w{10.3.3.1 172.16.4.1 192.168.2.1  fc00::1}.each do |ip|
      assert IPAddrRangeSet::LocalAddresses.include?(ip), "IPAddrRangeSet::LocalAddresses should include #{ip}"
    end
    
    %w{9.1.1.1 173.1.1.1 193.1.1.1 2607:f0d0:1002:51::4}.each do |ip|
      assert (! IPAddrRangeSet::LocalAddresses.include?(ip)), "IPAddrRangeSet::LocalAddresses should NOT include #{ip}"
    end    
  end
    
  
  
end
