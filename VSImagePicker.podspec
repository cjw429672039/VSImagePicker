#
# Be sure to run `pod lib lint VSImagePicker.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'VSImagePicker'
#  X.Y.Z （主版本号.次版本号.修订号）修复问题但不影响API 时，递增修订号；API 保持向下兼容的新增及修改时，递增次版本号；进行不向下兼容的修改时，递增主版本号
#  参考链接 https://segmentfault.com/a/1190000011368506  https://semver.org/lang/zh-CN/
  s.version          = '0.0.1'
  s.summary          = '图片选择组件'
  s.description      = '组件VSImagePicker，用于选择图片，拍照，或者相册'
  s.homepage         = 'https://github.com/cjw429672039/VSImagePicker'
  s.swift_version    = '5.0'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'cjw429672039' => 'cjw429672039@163.com' }
  s.source           = { :git => 'https://github.com/cjw429672039/VSImagePicker.git', :tag => s.version.to_s }
  s.ios.deployment_target = '9.0'
  s.source_files = 'VSImagePicker/Classes/**/*'
  s.requires_arc     = true
  s.framework        = "UIKit"  #使用到的系统库
  s.resource_bundles = {
    'VSImagePickerResource' => ['VSImagePicker/Assets/**/*.{*}']
  }
  # s.resource_bundles = {
  #   'VSImagePicker' => ['VSImagePicker/Assets/*.png']
  # }
  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
