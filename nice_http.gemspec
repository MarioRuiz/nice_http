Gem::Specification.new do |s|
  s.name        = 'nice_http'
  s.version     = '1.4.0'
  s.summary     = "NiceHttp -- simplest library for accessing and testing HTTP and REST resources."
  s.description = "NiceHttp -- simplest library for accessing and testing HTTP and REST resources. Manage different hosts on the fly. Easily get the value you want from the JSON strings. Use hashes on your requests."
  s.authors     = ["Mario Ruiz"]
  s.email       = 'marioruizs@gmail.com'
  s.files       = ["lib/nice_http.rb","lib/nice_http/utils.rb","LICENSE","README.md",".yardopts"]
  s.extra_rdoc_files = ["LICENSE","README.md"]
  s.homepage    = 'https://github.com/MarioRuiz/nice_http'
  s.license       = 'MIT'
  s.add_runtime_dependency 'nice_hash', '~> 1.9', '>= 1.9.0'
  s.add_development_dependency 'rspec', '~> 3.8', '>= 3.8.0'
  s.add_development_dependency 'coveralls', '~> 0.8', '>= 0.8.22'
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]
  s.required_ruby_version = ['>= 2.4', '< 2.6']
  s.post_install_message = "Thanks for installing! Visit us on https://github.com/MarioRuiz/nice_http"
end

