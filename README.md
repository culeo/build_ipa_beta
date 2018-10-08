## iOS 自动构建 IPA

#### 前提

Xcode9，自动签名

#### 功能

- 支持 xcworkspace 和 xcodeproj 两种类型的工程；
- 支持上传到 `fir` 和 `蒲公英` 平台

#### 使用

```
1. 给脚本添加可执行权限 chmod +x 脚本路径
2. 创建 ExportOptions.plist 文件
3. 配置 Config
4. 执行脚本 sh 脚本路径
5. 等待...
```


#### ExportOptions.plist模板

```
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>compileBitcode</key>
	<false/>
	<key>destination</key>
	<string>export</string>
	<key>method</key>
	<string>ad-hoc</string>
	<key>signingStyle</key>
	<string>automatic</string>
	<key>stripSwiftSymbols</key>
	<true/>
	<key>teamID</key>
	<string>xxxxxx</string>
	<key>thinning</key>
	<string>&lt;none&gt;</string>
</dict>
</plist>
```

可以参照模板修改。也可以手动构建一次，导出的文件夹中会包含 ExportOptions.plist。
具体可以看 [Xcode9 xcodebuild export plist 配置](https://blog.csdn.net/andanlan/article/details/78113330?locationNum=9&fps=1)