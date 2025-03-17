Gem::Specification.new do |gem|
  gem.name          = 'ai-commit-message'
  gem.version       = '0.1.2'
  gem.authors       = ['Afonso Neto']
  gem.email         = ['afonso.pontesneto@gmail.com']

  gem.summary       = 'Git commit messages suggested by AI'
  gem.description   = 'Git commit messages suggested by AI'
  gem.homepage      = 'https://github.com/AfonsoNeto/ai-commit-message'
  gem.license       = nil
  
  gem.files         = Dir.glob('{bin/*,lib/**/*,README.md}')
  gem.require_paths = ['lib']
  gem.executables   = ['ai-commit-message']
  gem.required_ruby_version = '>= 3.0'

  gem.add_dependency 'thor'
  gem.add_runtime_dependency 'tty-prompt'
  gem.add_runtime_dependency 'net-http'
  gem.add_runtime_dependency 'json'
end