# 设置测试环境变量
$ALIYUN_REGISTRY = "crpi-rqoug8ghwb30v7uf.cn-hangzhou.personal.cr.aliyuncs.com"
$ALIYUN_NAME_SPACE = "tianyuyuyu"
$ALIYUN_REGISTRY_USER = "TianYun1"
$ALIYUN_REGISTRY_PASSWORD = "Ty1998697598.."

# 测试镜像信息
$TEST_IMAGE = "docker:24.0.7-dind"
$IMAGE_NAME = $TEST_IMAGE.Split(':')[0]
$TAG = $TEST_IMAGE.Split(':')[1]

Write-Host "🔍 开始测试认证..." -ForegroundColor Cyan

# 测试 Docker 登录
Write-Host "`n1️⃣ 测试 Docker 登录" -ForegroundColor Yellow
try {
    $loginOutput = docker login -u $ALIYUN_REGISTRY_USER -p $ALIYUN_REGISTRY_PASSWORD $ALIYUN_REGISTRY 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Docker 登录成功" -ForegroundColor Green
    } else {
        Write-Host "❌ Docker 登录失败" -ForegroundColor Red
        Write-Host $loginOutput -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Docker 命令执行失败: $_" -ForegroundColor Red
    exit 1
}

# 测试 API 认证
Write-Host "`n2️⃣ 测试 API 认证" -ForegroundColor Yellow

# 生成 Base64 认证头
$auth = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("${ALIYUN_REGISTRY_USER}:${ALIYUN_REGISTRY_PASSWORD}"))
$headers = @{
    'Authorization' = "Basic $auth"
    'Content-Type' = 'application/json'
    'Accept' = 'application/vnd.docker.distribution.manifest.v2+json'
}

Write-Host "🔍 发送 API 请求..." -ForegroundColor Cyan
$uri = "https://${ALIYUN_REGISTRY}/v2/${ALIYUN_NAME_SPACE}/${IMAGE_NAME}/manifests/${TAG}"

try {
    # 忽略 SSL 证书验证（如果需要的话）
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
    
    $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get -ErrorVariable restError -ErrorAction SilentlyContinue
    
    Write-Host "`n📝 API 响应:" -ForegroundColor Yellow
    $response | ConvertTo-Json -Depth 10
    
    if ($response.schemaVersion) {
        Write-Host "✅ 镜像存在且认证成功" -ForegroundColor Green
    }
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    $statusDescription = $_.Exception.Response.StatusDescription
    $errorMessage = $_.Exception.Message
    
    Write-Host "`n📝 错误响应:" -ForegroundColor Yellow
    Write-Host "状态码: $statusCode" -ForegroundColor Red
    Write-Host "描述: $statusDescription" -ForegroundColor Red
    Write-Host "消息: $errorMessage" -ForegroundColor Red
    
    if ($errorMessage -match "MANIFEST_UNKNOWN") {
        Write-Host "ℹ️ 镜像不存在，但认证成功" -ForegroundColor Yellow
    } elseif ($errorMessage -match "UNAUTHORIZED") {
        Write-Host "❌ 认证失败" -ForegroundColor Red
    } else {
        Write-Host "❓ 未知响应" -ForegroundColor Red
    }
} finally {
    Write-Host "`n🔍 测试完成" -ForegroundColor Cyan
} 