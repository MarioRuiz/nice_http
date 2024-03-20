Gem::Specification.new do |s|
  s.name        = 'nice_http'
  s.version     = '1.9.8'
  s.summary     = "NiceHttp -- simplest library for accessing and testing HTTP and REST resources. Get http logs and statistics automatically. Use hashes on your requests. Access JSON even easier."
  s.description = "NiceHttp -- simplest library for accessing and testing HTTP and REST resources. Get http logs and statistics automatically. Use hashes on your requests. Access JSON even easier."
  s.authors     = ["Mario Ruiz"]
  s.email       = 'marioruizs@gmail.com'
  s.files       = Dir["lib/nice_http/methods/*.rb"] + Dir["lib/nice_http/manage/*.rb"] + 
                  Dir["lib/nice_http/utils/*.rb"] + Dir["lib/nice_http/*.rb"] +
                  ["lib/nice_http.rb","LICENSE","README.md",".yardopts"]
  s.extra_rdoc_files = ["LICENSE","README.md"]
  s.homepage    = 'https://github.com/MarioRuiz/nice_http'
  s.license       = 'MIT'
  s.add_runtime_dependency 'nice_hash', '1.18.7'
  s.add_development_dependency 'rspec', '~> 3.8', '>= 3.8.0'
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]
  s.required_ruby_version = ['>= 2.7']
  s.post_install_message = "Thanks for installing! Visit us on https://github.com/MarioRuiz/nice_http"
end

