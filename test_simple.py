#!/usr/bin/env python3
import requests
import json

BASE_URL = "http://localhost:3000"

def test_api(endpoint, method="GET", data=None):
    """测试API端点"""
    try:
        if method == "GET":
            response = requests.get(f"{BASE_URL}{endpoint}", timeout=5)
        elif method == "POST":
            response = requests.post(f"{BASE_URL}{endpoint}", json=data, timeout=5)
        
        print(f"{method} {endpoint} -> {response.status_code}")
        if response.status_code == 200:
            result = response.json()
            print(f"  成功: {result.get('success', False)}")
            print(f"  消息: {result.get('message', '')[:50]}")
            return result
        else:
            print(f"  错误: {response.text[:100]}")
            return None
    except Exception as e:
        print(f"  异常: {e}")
        return None

# 测试
print("=== 医小伴APP支付功能测试 ===\n")

# 1. 测试基础orders API
print("1. 测试基础orders API:")
test_api("/api/orders")

# 2. 测试订单详情
print("\n2. 测试订单详情:")
test_api("/api/orders/order_001")

# 3. 测试支付创建（应该失败，因为需要POST）
print("\n3. 测试支付创建端点（GET应该404）:")
test_api("/api/orders/order_001/payment/create")

# 4. 测试支付统计
print("\n4. 测试支付统计:")
test_api("/api/orders/payment/statistics")

print("\n=== 测试完成 ===")