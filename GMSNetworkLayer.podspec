Pod::Spec.new do |spec|

  spec.name         = "GMSNetworkLayer"
  spec.version      = "1.2.0"
  spec.summary      = "Stylish HTTP Networking in Swift."

  spec.homepage     = "https://github.com/GabrielSilveiraa/GMSNetworkLayer"

  spec.license      = "MIT"

  spec.author             = { "Gabriel Silveira" => "gabi.msilveira@gmail.com" }

  spec.source       = { :git => "https://github.com/GabrielSilveiraa/GMSNetworkLayer.git", :tag => "#{spec.version}" }

  spec.source_files  = "GMSNewtorkLayer/Sources/GMSNewtorkLayer*.swift"

  spec.ios.deployment_target = "12.2"
  spec.swift_version = "5"

end