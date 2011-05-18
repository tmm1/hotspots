Gem::Specification.new do |s|
  s.name = 'hotspots'
  s.version = '0.1.0'
  s.homepage = 'http://github.com/tmm1/hotspots'

  s.authors = 'Aman Gupta'
  s.email   = 'aman@tmm1.net'

  s.files = `git ls-files`.split("\n")

  s.bindir = 'bin'
  s.executables << 'hotspots'

  s.add_dependency 'fssm'
  s.add_dependency 'json'
  s.add_dependency 'sass'
  s.add_dependency 'thin'
  s.add_dependency 'compass'
  s.add_dependency 'uglifier'
  s.add_dependency 'yajl-ruby'
  s.add_dependency 'coffee-script'
  s.add_dependency 'trollop', '>= 1.16.2'

  s.summary = "a graphical view into your rails app's performance"
  s.description = 'hotspots shows you where your rails app is spending its time'
end
