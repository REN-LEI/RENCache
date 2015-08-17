Pod::Spec.new do |s|
  s.name         = "RENCache"
  s.version      = "1.0.0"
  s.summary      = "iOS 文件缓存类库，支持内存缓存和缓存过期"
  s.homepage     = "https://github.com/REN-LEI/RENCache"
  s.license      = "MIT"
  s.authors      =  { “任磊" => "https://github.com/REN-LEI" }
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/REN-LEI/RENCache.git", :tag => "v1.0" }
  s.frameworks   = 'Foundation', 'UIKit'     
  s.source_files = 'RENCache'
  s.requires_arc = true
end
