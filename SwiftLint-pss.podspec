Pod::Spec.new do |s|
  s.name                      = 'SwiftLint-pss'
  s.version                   = '0.0.24'
  s.summary                   = 'A tool to enforce Swift style and conventions.'
  s.homepage                  = 'https://github.com/perrystreetsoftware/SwiftLint'
  s.license                   = { type: 'MIT', file: 'LICENSE' }
  s.author                    = { 'JP Simard' => 'jp@jpsim.com' }
  s.source                    = { http: "#{s.homepage}/releases/download/#{s.version}/portable_swiftlint.zip" }
  s.preserve_paths            = '*'
  s.exclude_files             = '**/file.zip'
  s.ios.deployment_target     = '11.0'
  s.macos.deployment_target   = '10.13'
end
