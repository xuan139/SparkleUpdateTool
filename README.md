## SparkleUpdateTool

## fork and clone 
https://github.com/sparkle-project/Sparkle.git

## Build Release
## 把 Release 下的 binarydelta cp 到 /usr/local/bin/binarydelta
## 把 Release 下的 sign_update cp 到 /usr/local/bin/sign_update
## Release 下的  /Users/lijiaxi/Library/Developer/Xcode/DerivedData/Sparkle-fromtshtpkdymdbrcldzhggburwb/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_keys cp 到 /usr/local/bin/generate_keys

## generate keys 产生公钥 和 私钥 把私钥添加到所有要更新的app的Info.list 里 公钥同时会保存到chain里

## build 运行app 产生 增量delta 签名 和 xml 后放到服务器上 

## 新建一个app 用于update 相关app 待开发
## 待测试 游戏平台
