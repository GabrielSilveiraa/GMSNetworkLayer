Pod::Spec.new do |spec|

  spec.name         = "GMSNetworkLayer"
  spec.version      = "0.0.1"
  spec.summary      = "Stylish HTTP Networking in Swift."

  spec.homepage     = "https://github.com/GabrielSilveiraa/GMSNetworkLayer"

  spec.license      = "MIT"

  spec.author             = { "Gabriel Silveira" => "gabi.msilveira@gmail.com" }

  spec.source       = { :git => "https://github.com/GabrielSilveiraa/GMSNetworkLayer.git", :tag => "#{spec.version}" }

  spec.source_files  = "NetworkLayer/*.swift"

  spec.ios.deployment_target = "13.3"
  spec.swift_version = "5"

end