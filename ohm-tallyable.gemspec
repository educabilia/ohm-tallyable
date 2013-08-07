Gem::Specification.new do |s|
  s.name        = 'ohm-tallyable'
  s.version     = '0.1.0'
  s.summary     = "Ohm Tally Plugin"
  s.description = "A tally plugin for Ohm that keeps counts of records for every value of an attribute"
  s.author      = "Federico Bond"
  s.email       = 'federico@educabilia.com'
  s.files       = Dir["UNLICENSE", "README.md", "Rakefile", "lib/**/*.rb", "*.gemspec", "test/*.*"]
  s.homepage    = 'https://github.com/educabilia/ohm-tallyable'

  s.add_dependency "ohm", ">= 0.1.3"
end
