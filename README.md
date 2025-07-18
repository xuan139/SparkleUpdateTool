# SparkleUpdateTool

#  fork and clone 
https://github.com/sparkle-project/Sparkle.git

# Build 
# 把 binarydelta cp 到 /usr/local/bin/binarydelta
# 把 sign_update cp 到 /usr/local/bin/sign_update
# /Users/lijiaxi/Library/Developer/Xcode/DerivedData/Sparkle-fromtshtpkdymdbrcldzhggburwb/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_keys cp 到 /usr/local/bin/sign_update

# generate keys 添加到所有要更新的app的Info.list 里 同时会保存到chain里
# 运行app 产生 增量delta 签名 和 xml 后放到服务器上 
# 新建一个app 用于update 相关app 
# 待测试
