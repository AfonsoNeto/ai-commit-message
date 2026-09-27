Gem::Specification.new do |gem|
  gem.name          = 'ai-commit-message'
  gem.version       = '0.2.0'
  gem.authors       = ['Afonso Neto']
  gem.email         = ['afonso.pontesneto@gmail.com']

  gem.summary       = 'Git commit messages suggested by AI'
  gem.description   = 'Git commit messages suggested by AI using a local LLM via any OpenAI-compatible API'
  gem.homepage      = 'https://github.com/AfonsoNeto/ai-commit-message'
  gem.license       = 'MIT'

  gem.metadata['rubygems_mfa_required'] = 'true'

  gem.files         = Dir.glob('{bin/*,lib/**/*,README.md,LICENSE}')
  gem.require_paths = ['lib']
  gem.executables   = ['ai-commit-message']
  gem.required_ruby_version = '>= 3.0'

  gem.add_dependency 'thor'
  gem.add_dependency 'tty-prompt'

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'minitest'
end
