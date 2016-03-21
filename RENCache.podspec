Pod::Spec.new do |s|
  s.name         = "RENCache"
  s.version      = "1.0.1"
  s.summary      = "iOS 文件缓存类库，支持内存缓存和缓存过期"
  s.homepage     = "https://github.com/REN-LEI/RENCache"
  s.license      = "MIT"
  s.authors      = {'renlei' => '568577297@qq.com'}
  s.platform     = :ios, "7.0"
  s.source       = {:git => "https://github.com/REN-LEI/RENCache.git", :tag => s.version}
  s.frameworks   = 'Foundation', 'UIKit'     
  s.source_files = 'RENCache','RENCache.{h,m}'
  s.requires_arc = true
end
