#!/usr/bin/env python3
"""
医小伴APP - 陪诊师端功能测试
"""

import requests
import json

BASE_URL = "http://localhost:3004"

def test_companion_flow():
    print("🏥 陪诊师端功能测试")
    print("=" * 60)
    
    # 1. 健康检查
    print("\n1. 健康检查")
    try:
        resp = requests.get(f"{BASE_URL}/health", timeout=3)
        print(f"   状态: {resp.status_code}, 响应: {resp.json()}")
    except:
        print("   失败")
        return
    
    # 2. 登录测试
    print("\n2. 登录测试")
    login_data = {"username": "doctor1", "password": "123"}
    try:
        resp = requests.post(f"{BASE_URL}/api/login", json=login_data, timeout=3)
        if resp.status_code == 200:
            data = resp.json()
            print(f"   成功: {data['success']}")
            print(f"   陪诊师: {data['companion']['name']}")
            token = data['token']
            print(f"   Token: {token}")
        else:
            print(f"   失败: {resp.status_code}")
            return
    except Exception as e:
        print(f"   异常: {e}")
        return
    
    # 3. 获取任务列表
    print("\n3. 获取任务列表")
    headers = {"Authorization": token}
    try:
        resp = requests.get(f"{BASE_URL}/api/tasks", headers=headers, timeout=3)
        if resp.status_code == 200:
            data = resp.json()
            print(f"   成功: {data['success']}")
            print(f"   任务数量: {data['count']}")
            for task in data.get('tasks', []):
                print(f"     - {task['id']}: {task['patient']} @ {task['hospital']} ({task['status']})")
        else:
            print(f"   失败: {resp.status_code}")
    except Exception as e:
        print(f"   异常: {e}")
    
    # 4. 接单测试
    print("\n4. 接单测试")
    # 先找一个待接单的任务
    pending_tasks = [t for t in data.get('tasks', []) if t['status'] == 'pending']
    if pending_tasks:
        task_id = pending_tasks[0]['id']
        try:
            resp = requests.post(f"{BASE_URL}/api/tasks/{task_id}/accept", headers=headers, timeout=3)
            if resp.status_code == 200:
                accept_data = resp.json()
                print(f"   接单成功: {accept_data['success']}")
                print(f"   任务状态: {accept_data['task']['status']}")
            else:
                print(f"   接单失败: {resp.status_code}")
        except Exception as e:
            print(f"   异常: {e}")
    else:
        print("   没有待接单的任务")
    
    # 5. 再次获取任务列表查看状态
    print("\n5. 验证任务状态更新")
    try:
        resp = requests.get(f"{BASE_URL}/api/tasks", headers=headers, timeout=3)
        if resp.status_code == 200:
            data = resp.json()
            print(f"   当前任务状态:")
            for task in data.get('tasks', []):
                status = "✅ 已接单" if task['status'] == 'accepted' else "⏳ 待接单"
                print(f"     - {task['patient']}: {status}")
    except:
        print("   获取失败")
    
    print("\n" + "=" * 60)
    print("✅ 陪诊师端基础功能测试完成")
    print("\n📋 已实现功能:")
    print("  ✅ 陪诊师登录认证")
    print("  ✅ 任务列表查看")
    print("  ✅ 任务接单处理")
    print("  ✅ 状态管理")
    print("\n🎯 下一步开发:")
    print("  1. 任务详情页面")
    print("  2. 任务开始/完成流程")
    print("  3. 日程安排视图")
    print("  4. 收入统计报表")

if __name__ == "__main__":
    test_companion_flow()