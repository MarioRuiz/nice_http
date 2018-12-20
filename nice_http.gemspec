Gem::Specification.new do |s|
  s.name        = 'nice_http'
  s.version     = '0.9.8'
  s.summary     = "NiceHttp -- simplest library for accessing and testing HTTP and REST resources."
  s.description = "NiceHttp -- simplest library for accessing and testing HTTP and REST resources. Manage different hosts on the fly. Easily get the value you want from the JSON strings. Use hashes on your requests."
  s.authors     = ["Mario Ruiz"]
  s.email       = 'marioruizs@gmail.com'
  s.files       = ["lib/nice_http.rb","lib/nice_http_utils.rb","LICENSE","README.md",".yardopts"]
  s.extra_rdoc_files = ["LICENSE","README.md"]
  s.homepage    = 'https://github.com/MarioRuiz/nice_http'
  s.license       = 'MIT'
  s.add_runtime_dependency 'nice_hash', '~> 1.4', '>= 1.4.0'
end

