# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "ipaddr_range_set/version"

Gem::Specification.new do |s|
  s.name        = "ipaddr_range_set"
  s.version     = IpaddrRangeSet::VERSION
  s.authors     = ["Jonathan Rochkind"]
  s.email       = ["jonathan@dnil.net"]
  s.homepage    = "https://github.com/jrochkind/ipaddr_range_set"
  s.summary     = %q{convenience class to create a set of possibly discontiguous IP address range
segments, and check if an IP address is in the set.}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
