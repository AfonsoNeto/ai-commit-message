Gem::Specification.new do |gem|
  gem.name          = 'ai-commit-message'
  gem.version       = '0.1.0'
  gem.authors       = ['Afonso Neto']
  gem.email         = ['afonso.pontesneto@gmail.com']

  gem.summary       = 'Git commit messages suggested by AI'
  gem.description   = 'Git commit messages suggested by AI'
  gem.homepage      = 'https://github.com/AfonsoNeto/ai-commit-message'
  gem.license       = 'None'

  gem.files         = Dir.glob('{bin/*,lib/**/*,README.md}')
  gem.require_paths = ['lib']
  gem.executables   = ['ai-commit-message']

  gem.add_dependency 'thor'
  gem.add_runtime_dependency 'net-http'
  gem.add_runtime_dependency 'json'
end