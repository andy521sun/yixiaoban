#!/usr/bin/env python3
"""
医小伴陪诊APP - 简化本地开发服务器
同时提供API后端和管理后台
"""

import http.server
import socketserver
import threading
import subprocess
import time
import os
import sys

class SimpleHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    """自定义HTTP请求处理器"""
    
    def do_GET(self):
        # 重写根路径到管理后台
        if self.path == '/':
            self.path = '/admin/dist/index.html'
        elif self.path.startswith('/api/'):
            # API请求转发到后端（这里只是模拟）
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(b'{"message": "API请求已转发到后端服务", "status": "success"}')
            return
        
        return http.server.SimpleHTTPRequestHandler.do_GET(self)
    
    def log_message(self, format, *args):
        """自定义日志格式"""
        print(f"[HTTP] {self.address_string()} - {format % args}")

def start_backend():
    """启动Node.js后端服务"""
    print("🚀 启动后端API服务...")
    os.chdir('backend')
    try:
        # 检查是否已安装依赖
        if not os.path.exists('node_modules'):
            print("📦 安装后端依赖...")
            subprocess.run(['npm', 'install'], check=True)
        
        # 启动后端服务
        print("⚡ 启动后端服务在端口 3000...")
        backend_process = subprocess.Popen(['node', 'src/server.js'], 
                                          stdout=subprocess.PIPE,
                                          stderr=subprocess.STDOUT,
                                          text=True)
        
        # 输出后端日志
        def log_backend_output():
            for line in backend_process.stdout:
                print(f"[Backend] {line}", end='')
        
        threading.Thread(target=log_backend_output, daemon=True).start()
        return backend_process
        
    except Exception as e:
        print(f"❌ 后端启动失败: {e}")
        return None

def start_admin_server(port=8080):
    """启动管理后台静态文件服务器"""
    print(f"🚀 启动管理后台在端口 {port}...")
    
    # 切换到admin目录
    os.chdir('admin')
    
    # 构建管理后台（如果dist目录不存在）
    if not os.path.exists('dist'):
        print("📦 构建管理后台...")
        subprocess.run(['npm', 'run', 'build'], check=True)
    
    # 切换回项目根目录
    os.chdir('..')
    
    # 启动HTTP服务器
    handler = SimpleHTTPRequestHandler
    handler.directory = 'admin/dist'
    
    with socketserver.TCPServer(("", port), handler) as httpd:
        print(f"✅ 管理后台已启动: http://localhost:{port}")
        print(f"📁 静态文件目录: {handler.directory}")
        httpd.serve_forever()

def main():
    """主函数"""
    print("=" * 50)
    print("🏥 医小伴陪诊APP - 本地开发测试环境")
    print("=" * 50)
    
    # 确保在项目根目录
    project_root = os.path.dirname(os.path.abspath(__file__))
    os.chdir(project_root)
    
    print(f"📁 项目目录: {project_root}")
    
    # 启动后端服务
    backend_process = start_backend()
    if not backend_process:
        return
    
    # 等待后端启动
    print("⏳ 等待后端服务启动...")
    time.sleep(3)
    
    # 检查后端健康状态
    try:
        import urllib.request
        response = urllib.request.urlopen('http://localhost:3000/health', timeout=5)
        print(f"✅ 后端健康检查通过: {response.read().decode()}")
    except Exception as e:
        print(f"⚠️  后端健康检查失败: {e}")
    
    # 启动管理后台
    try:
        start_admin_server()
    except KeyboardInterrupt:
        print("\n🛑 收到停止信号，关闭服务...")
    finally:
        # 清理后端进程
        if backend_process:
            backend_process.terminate()
            backend_process.wait()
            print("✅ 后端服务已停止")
        
        print("👋 医小伴陪诊APP服务已全部停止")

if __name__ == "__main__":
    main()