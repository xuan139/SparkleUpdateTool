# SparkleUpdateTool for Publisher

## fork and clone 
https://github.com/sparkle-project/Sparkle.git

## Build Release
## 把 Release 下的 binarydelta cp 到 /usr/local/bin/binarydelta
## 把 Release 下的 sign_update cp 到 /usr/local/bin/sign_update
## Release 下的  /Users/lijiaxi/Library/Developer/Xcode/DerivedData/Sparkle-fromtshtpkdymdbrcldzhggburwb/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_keys cp 到 /usr/local/bin/generate_keys


## 第一步 用 generate keys 产生公钥 和 私钥 
###    它会把私钥保存进你的钥匙串，并输出公钥。
###    把公钥放入每个要更新的app的 info.list 里

## 第二步 build 运行SparkleUpdateTool.app 产生 增量delta, 签名, 和 castxml 后放到服务器上 要包含old app 的zip ，delta， 签名，类似如下结构

    <?xml version="1.0" encoding="utf-8"?>
    <rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle"
         xmlns:dc="http://purl.org/dc/elements/1.1/">
      <channel>
        <title>App Updates</title>
        <link>https://yourserver.com/updates/</link>
        <description>Latest updates for your app</description>
        <language>en</language>

        <item>
          <title>Version 2.0</title>
          <sparkle:releaseNotesLink>https://yourserver.com/updates/release_notes_2.0.html</sparkle:releaseNotesLink>
          <pubDate>Fri, 18 Jul 2025 10:35:51 -0500</pubDate>
          <enclosure url="https://yourserver.com/updates/YourApp-2.0.zip"
                     sparkle:version="2.0"
                     sparkle:shortVersionString="2.0"
                     length="0"
                     type="application/octet-stream"
                     sparkle:edSignature="ApZHFghsd4Sl8nUy3eN2+XzO0VoD..." />

          <sparkle:delta>
            <enclosure url="https://yourserver.com/updates/YourApp-1.5-to-2.0.delta"
                       sparkle:version="2.0"
                       sparkle:deltaFrom="1.5"
                       length="34518"
                       type="application/octet-stream"
                       sparkle:edSignature="LWHx4F65ifViHpkguF0UziBnwYpi..." />
          </sparkle:delta>
        </item>
      </channel>
    </rss>

## 可以用 binarydeltavapply old.zip 加 delta 产生新的 new。zip
## 新建一个app 用于update 相关app 待开发
## 待测试 所有的游戏平台 ostation

