#!/usr/bin/env python3
"""
医小伴APP - 支付功能测试脚本
创建时间：2026年4月19日
"""

import requests
import json
import time

BASE_URL = "http://localhost:3000"

def test_payment_api():
    """测试支付API"""
    print("=== 医小伴APP支付功能测试 ===\n")
    
    # 1. 测试创建支付订单
    print("1. 创建支付订单测试")
    payload = {
        "order_id": "order_011",
        "payment_method": "wechat",
        "amount": 250.00,
        "description": "测试支付功能"
    }
    
    try:
        response = requests.post(f"{BASE_URL}/api/payment/create", 
                                json=payload,
                                timeout=10)
        print(f"   状态码: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"   结果: {data.get('success', False)}")
            if data.get('success'):
                payment_id = data['data']['payment_id']
                print(f"   支付ID: {payment_id}")
                print(f"   支付链接: {data['data']['payment_url']}")
                return payment_id
            else:
                print(f"   错误: {data.get('message', '未知错误')}")
        else:
            print(f"   HTTP错误: {response.text[:100]}")
    except Exception as e:
        print(f"   请求失败: {e}")
    
    return None

def test_payment_simulation(payment_id):
    """测试模拟支付"""
    print(f"\n2. 模拟支付测试 (支付ID: {payment_id})")
    
    payload = {"result": "success"}
    
    try:
        response = requests.post(f"{BASE_URL}/api/payment/simulate/{payment_id}", 
                                json=payload,
                                timeout=10)
        print(f"   状态码: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"   结果: {data.get('success', False)}")
            print(f"   消息: {data.get('message', '')}")
            if data.get('data'):
                print(f"   交易ID: {data['data'].get('transaction_id', '')}")
                print(f"   支付状态: {data['data'].get('status', '')}")
        else:
            print(f"   HTTP错误: {response.text[:100]}")
    except Exception as e:
        print(f"   请求失败: {e}")

def test_payment_statistics():
    """测试支付统计"""
    print("\n3. 支付统计测试")
    
    try:
        response = requests.get(f"{BASE_URL}/api/payment/statistics/summary", 
                               timeout=10)
        print(f"   状态码: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"   结果: {data.get('success', False)}")
            if data.get('data'):
                stats = data['data']
                print(f"   总支付笔数: {stats.get('total_payments', 0)}")
                print(f"   总支付金额: {stats.get('total_amount', 0)}")
                print(f"   成功支付笔数: {stats.get('success_payments', 0)}")
                print(f"   成功率: {stats.get('success_rate', '0.00')}%")
        else:
            print(f"   HTTP错误: {response.text[:100]}")
    except Exception as e:
        print(f"   请求失败: {e}")

def test_existing_payments():
    """测试现有支付记录"""
    print("\n4. 现有支付记录测试")
    
    test_payments = ['pay_test_001', 'pay_test_002', 'pay_test_003']
    
    for payment_id in test_payments:
        try:
            response = requests.get(f"{BASE_URL}/api/payment/{payment_id}", 
                                   timeout=10)
            if response.status_code == 200:
                data = response.json()
                if data.get('success'):
                    payment = data['data']
                    print(f"   {payment_id}: {payment.get('payment_method', '')} - ¥{payment.get('amount', 0)} - {payment.get('status', '')}")
                else:
                    print(f"   {payment_id}: {data.get('message', '未找到')}")
            else:
                print(f"   {payment_id}: HTTP {response.status_code}")
        except Exception as e:
            print(f"   {payment_id}: 请求失败 - {e}")

def main():
    """主函数"""
    print("开始支付功能测试...\n")
    
    # 测试现有支付记录
    test_existing_payments()
    
    # 测试支付统计
    test_payment_statistics()
    
    # 测试创建新支付
    payment_id = test_payment_api()
    
    # 如果创建成功，测试模拟支付
    if payment_id:
        test_payment_simulation(payment_id)
        
        # 等待一下再测试统计
        time.sleep(1)
        test_payment_statistics()
    
    print("\n=== 测试完成 ===")

if __name__ == "__main__":
    main()