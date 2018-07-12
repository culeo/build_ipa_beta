#!/bin/sh

#------------ guide ----------
# 
# 1. 给脚本添加可执行权限 chmod +x 脚本路径
# 2. 创建 ExportOptions.plist 文件
# 3. 配置 Config
# 4. 执行脚本 sh 脚本路径
# 5. 等待..

#------------ begin config ----------

# 是否是xcworkspace
IS_WORKSPACE=0
# 工程路径
PROJECT_PATH="/Users/xxx/Desktop/Demo"
# 工程名(不需要后缀)
PROJECT_NAME="Demo"
# scheme
PROJECT_SCHEME="${PROJECT_NAME}"
# Debug 或 Release
BUILD_CONFIGURATION="Release"
# ExportOptions文件路径
EXPORTOPTIONS_PATH="${PROJECT_PATH}/ExportOptions.plist"
# Fir Token(启用fir，填入token，然后取消注释即可)
# FIR_API_TOKEN=""
# 蒲公英 Token(启用蒲公英，填入token，然后取消注释即可)
# PGYER_API_TOKEN=""

#------------ end config ------------

#------------ check -------------

if ! test -d ${PROJECT_PATH} ; then
	echo "请检查工程路径是否正确 '${PROJECT_PATH}'"
	exit
fi

if [[ ${IS_WORKSPACE} == 1 ]]; then
	if ! test -d ${PROJECT_PATH}/${PROJECT_NAME}.xcworkspace ; then
		echo "请检查工程名是否正确 '${PROJECT_NAME}.xcworkspace'"
		exit
	fi
else
	if ! test -d ${PROJECT_PATH}/${PROJECT_NAME}.xcodeproj ; then
		echo "请检查工程名是否正确 '${PROJECT_NAME}.xcodeproj'"
		exit
	fi
fi

if ! test -f ${EXPORTOPTIONS_PATH}; then
	echo "请检查ExportOptions文件路径是否正确 '${EXPORTOPTIONS_PATH}'"
fi

#------------ begin --------------

clear

# 准备
# Archive导出路径
ARCHIVE_EXPORT_PATH=${PROJECT_PATH}/${PROJECT_NAME}.xcarchive
# IPA 导出路径
IPA_EXPORT_PATH=${PROJECT_PATH}/${PROJECT_NAME}$(date +%Y-%m-%d-%H-%M-%S)
# IPA 文件路径
IPA_FILE_PATH=${IPA_EXPORT_PATH}/${PROJECT_SCHEME}.ipa

interrupted () {
	echo "\033[36m************  😁   脚本结束 ${PROJECT_NAME}  😁   ************\033[0m"
    exit                    
}

trap "interrupted" INT

# 开始
echo "\033[36m************  🚀   开始构建 ${PROJECT_NAME}  🚀   ************\033[0m"
echo $PROJECT_PATH

# 清理
if [[ ${IS_WORKSPACE} == 1 ]]; then
	xcodebuild clean \
	-workspace ${PROJECT_PATH}/${PROJECT_NAME}.xcworkspace \
	-scheme ${PROJECT_SCHEME} \
	-configuration ${BUILD_CONFIGURATION}
else
	xcodebuild clean \
	-project ${PROJECT_PATH}/${PROJECT_NAME}.xcodeproj \
	-scheme ${PROJECT_SCHEME} \
	-configuration ${BUILD_CONFIGURATION}
fi

# 构建
if [[ ${IS_WORKSPACE} == 1 ]]; then
	xcodebuild archive \
	-workspace ${PROJECT_PATH}/${PROJECT_NAME}.xcworkspace \
	-scheme ${PROJECT_SCHEME} \
	-archivePath ${ARCHIVE_EXPORT_PATH}
else
	xcodebuild archive \
	-project ${PROJECT_PATH}/${PROJECT_NAME}.xcodeproj \
	-scheme ${PROJECT_SCHEME} \
	-archivePath ${ARCHIVE_EXPORT_PATH}
fi

# 构建成功
if test -d ${ARCHIVE_EXPORT_PATH} ; then
echo "\033[36m************  🎉   构建成功 ${PROJECT_NAME}  🎉   ************\033[0m"
else
echo "\033[36m************  😭   构建失败 ${PROJECT_NAME}  😭   ************\033[0m"
exit 1
fi

echo "\n"
echo "\033[36m************  🚀   导出IPA ${PROJECT_NAME}  🚀   ************\033[0m"

xcodebuild \
-exportArchive \
-archivePath ${ARCHIVE_EXPORT_PATH} \
-exportPath ${IPA_EXPORT_PATH} \
-exportOptionsPlist ${EXPORTOPTIONS_PATH} \
-allowProvisioningUpdates

# 导出成功
if test -f ${IPA_FILE_PATH} ; then
echo ${IPA_EXPORT_PATH}
echo "\033[36m************  🎉   导出IPA成功 ${PROJECT_NAME}  🎉   ************\033[0m"
else
echo "\033[36m************  😭   导出IPA失败 ${PROJECT_NAME}  😭   ************\033[0m"
exit 1
fi

# 上传到fir
if [[ ${FIR_API_TOKEN} ]]; then
	echo ""
	if type fir >/dev/null 2>&1; then
		echo "\033[36m************  🚀   开始上传到 fir  🚀   ************\033[0m"
		fir publish ${IPA_FILE_PATH} -T ${FIR_API_TOKEN}
		if [[ $? -eq 0 ]]; then
			echo "\033[36m************  🎉   上传到 fir 成功  🎉   ************\033[0m"
		else
			echo "\033[36m************  😭   上传到 fir 失败  😭   ************\033[0m"
		fi
	else
		echo "\033[36m************  😅   没有安装 fir-cli  😅   ************\033[0m"
		echo 安装方法 'https://github.com/FIRHQ/fir-cli/blob/master/doc/install.md'
	fi
fi

# 上传到蒲公英
if [[ ${PGYER_API_TOKEN} ]]; then
	echo ""
	echo "\033[36m************  🚀   开始上传到蒲公英  🚀   ************\033[0m"
	result=$(curl -sb -H "Accept: application/json" \
	-F 'file=@'${IPA_FILE_PATH} \
	-F '_api_key='${PGYER_API_TOKEN} \
	"https://www.pgyer.com/apiv2/app/upload")
	echo $result
	if [[ $result ]]; then
		code=$(echo "${result}" \
		| awk -F"[,:}]" '{for(i=1;i<=NF;i++){if($i~/'code'\042/){print $(i+1)}}}' \
		| tr -d '"' | sed -n ${num}p)
		if [[ ${code} -eq 0 ]]; then
			echo "\033[36m************  🎉   上传到蒲公英成功  🎉   ************\033[0m"
		else
			echo 错误 Code ${code} 含义详见 'https://www.pgyer.com/doc/view/api#errorCode'
			echo "\033[36m************  😅   上传到蒲公英失败  😅   ************\033[0m"
		fi
	else
		echo "请检查网络"
		echo "\033[36m************  😅   上传到蒲公英失败  😅   ************\033[0m"
	fi
fi

echo "脚本执行共耗时：${SECONDS}s"

#------------ end --------------