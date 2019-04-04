Gem::Specification.new do |s|
  s.name        = 'nice_http'
  s.version     = '1.7.10'
  s.summary     = "NiceHttp -- simplest library for accessing and testing HTTP and REST resources. Get http logs and statistics automatically. Use hashes on your requests. Access JSON even easier."
  s.description = "NiceHttp -- simplest library for accessing and testing HTTP and REST resources. Get http logs and statistics automatically. Use hashes on your requests. Access JSON even easier."
  s.authors     = ["Mario Ruiz"]
  s.email       = 'marioruizs@gmail.com'
  s.files       = ["lib/nice_http.rb","lib/nice_http/http_methods.rb","lib/nice_http/utils.rb",
                   "lib/nice_http/manage_request.rb","lib/nice_http/manage_response.rb",
                   "LICENSE","README.md",".yardopts"]
  s.extra_rdoc_files = ["LICENSE","README.md"]
  s.homepage    = 'https://github.com/MarioRuiz/nice_http'
  s.license       = 'MIT'
  s.add_runtime_dependency 'nice_hash', '~> 1.12', '>= 1.12.3'
  s.add_development_dependency 'rspec', '~> 3.8', '>= 3.8.0'
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]
  s.required_ruby_version = ['>= 2.4']
  s.post_install_message = "Thanks for installing! Visit us on https://github.com/MarioRuiz/nice_http"
end

