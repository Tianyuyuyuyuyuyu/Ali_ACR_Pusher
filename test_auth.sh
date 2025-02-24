#!/bin/bash

# 设置测试环境变量
ALIYUN_REGISTRY="crpi-rqoug8ghwb30v7uf.cn-hangzhou.personal.cr.aliyuncs.com"
ALIYUN_NAME_SPACE="tianyuyuyu"
ALIYUN_REGISTRY_USER="TianYun1"
ALIYUN_REGISTRY_PASSWORD="Ty1998697598.."

# 测试镜像信息
TEST_IMAGE="docker:24.0.7-dind"
IMAGE_NAME=$(echo "$TEST_IMAGE" | awk -F':' '{print $1}')
TAG=$(echo "$TEST_IMAGE" | awk -F':' '{print $2}')

echo "🔍 开始测试认证..."

# 测试 Docker 登录
echo "1️⃣ 测试 Docker 登录"
if docker login -u "$ALIYUN_REGISTRY_USER" -p "$ALIYUN_REGISTRY_PASSWORD" "$ALIYUN_REGISTRY"; then
    echo "✅ Docker 登录成功"
else
    echo "❌ Docker 登录失败"
    exit 1
fi

# 测试 API 认证
echo -e "\n2️⃣ 测试 API 认证"
AUTH_HEADER="Basic $(echo -n "${ALIYUN_REGISTRY_USER}:${ALIYUN_REGISTRY_PASSWORD}" | base64 -w 0)"

echo "🔍 发送 API 请求..."
RESPONSE=$(curl -s -X GET \
    -H "Content-Type: application/json" \
    -H "Authorization: $AUTH_HEADER" \
    -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
    "https://${ALIYUN_REGISTRY}/v2/${ALIYUN_NAME_SPACE}/${IMAGE_NAME}/manifests/${TAG}")

echo -e "\n📝 API 响应:"
echo "$RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"

# 检查响应
if echo "$RESPONSE" | grep -q "schemaVersion"; then
    echo "✅ 镜像存在且认证成功"
elif echo "$RESPONSE" | grep -q "MANIFEST_UNKNOWN"; then
    echo "ℹ️ 镜像不存在，但认证成功"
elif echo "$RESPONSE" | grep -q "UNAUTHORIZED"; then
    echo "❌ 认证失败"
else
    echo "❓ 未知响应"
fi

echo -e "\n🔍 测试完成" 