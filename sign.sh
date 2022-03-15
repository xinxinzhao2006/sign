
# 打印所有证书
security find-identity -v -p codesigning 

#设置证书
signCode=""

if [[ -z $signCode ]];
then
	echo "——————————请配置证书————————"
	exit
fi

#查找描述文件
if [ $(find . -name "*.mobileprovision") ]
then
	mobileprovisionPath=$(find . -name "*.mobileprovision")
else
	echo "——————————mobileprovision 不存在————————"
	exit
fi

#提取设备信息
security cms -D -i${mobileprovisionPath:2} > temp.plist
/usr/libexec/PlistBuddy -x -c 'Print:Entitlements' temp.plist > entitlements.plist

#查找ipa文件
if [ $(find . -name "*.ipa") ]
then
	ipaPath=$(find . -name "*.ipa")
	ipaName=${ipaPath:2}
	unzip $ipaName
	rm -f $ipaName
	appPath=$(find ./Payload -name "*.app")
	appPath=${appPath:2}
else
	echo "——————————IPA 不存在————————"
	exit
fi

#复制描述文件
# cp -f $mobileprovisionPath $appPath

#查找framework文件
for f in  $(find $appPath/Frameworks -name "*.framework"); do
	p=$appPath/Frameworks
	begin=${#p}+1
	length=${#f}-${#p}-10-1
	framework=${f:begin:length}
	framework=$f/$framework
	#签名库文件
	codesign -fs $signCode --entitlements entitlements.plist $framework
done

#查找dylib文件
for f in  $(find $appPath/Frameworks -name "*.dylib"); do
	#签名库文件
	codesign -fs $signCode --entitlements entitlements.plist $f
done
#如果签名失败 应该是存还需要签名的 可执行文件需手动签名
#签名
codesign -fs $signCode --entitlements entitlements.plist $appPath
#压缩
zip -r "重签"$ipaName Payload
#删除
rm -rf Payload
rm -f entitlements.plist
rm -f temp.plist

