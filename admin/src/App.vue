<template>
  <div class="app-container">
    <!-- 侧边栏 -->
    <el-container class="main-container">
      <el-aside width="200px" class="sidebar">
        <div class="logo">
          <h1>医小伴</h1>
          <p>管理后台</p>
        </div>
        
        <el-menu
          :default-active="activeMenu"
          class="sidebar-menu"
          :router="true"
          :collapse="isCollapse"
        >
          <el-menu-item index="/">
            <el-icon><Odometer /></el-icon>
            <span>仪表板</span>
          </el-menu-item>
          
          <el-menu-item index="/orders">
            <el-icon><Document /></el-icon>
            <span>订单管理</span>
          </el-menu-item>
          
          <el-menu-item index="/users">
            <el-icon><User /></el-icon>
            <span>用户管理</span>
          </el-menu-item>
          
          <el-menu-item index="/companions">
            <el-icon><UserFilled /></el-icon>
            <span>陪诊师管理</span>
          </el-menu-item>
          
          <el-sub-menu index="system">
            <template #title>
              <el-icon><Setting /></el-icon>
              <span>系统管理</span>
            </template>
            <el-menu-item index="/system/hospitals">
              <el-icon><OfficeBuilding /></el-icon>
              <span>医院管理</span>
            </el-menu-item>
            <el-menu-item index="/system/settings">
              <el-icon><Tools /></el-icon>
              <span>系统设置</span>
            </el-menu-item>
            <el-menu-item index="/system/logs">
              <el-icon><DocumentCopy /></el-icon>
              <span>操作日志</span>
            </el-menu-item>
          </el-sub-menu>
        </el-menu>
        
        <div class="sidebar-footer">
          <el-button
            type="text"
            @click="toggleSidebar"
            class="collapse-btn"
          >
            <el-icon v-if="isCollapse"><Expand /></el-icon>
            <el-icon v-else><Fold /></el-icon>
          </el-button>
        </div>
      </el-aside>
      
      <!-- 主内容区 -->
      <el-container class="content-container">
        <!-- 顶部导航栏 -->
        <el-header class="header">
          <div class="header-left">
            <el-breadcrumb separator="/">
              <el-breadcrumb-item v-for="item in breadcrumb" :key="item.path">
                {{ item.meta?.title || item.name }}
              </el-breadcrumb-item>
            </el-breadcrumb>
          </div>
          
          <div class="header-right">
            <el-dropdown @command="handleCommand">
              <div class="user-info">
                <el-avatar :size="32" :src="userInfo.avatar">
                  {{ userInfo.name?.charAt(0) }}
                </el-avatar>
                <span class="user-name">{{ userInfo.name }}</span>
                <el-icon><ArrowDown /></el-icon>
              </div>
              <template #dropdown>
                <el-dropdown-menu>
                  <el-dropdown-item command="profile">
                    <el-icon><User /></el-icon>
                    个人中心
                  </el-dropdown-item>
                  <el-dropdown-item command="settings">
                    <el-icon><Setting /></el-icon>
                    账户设置
                  </el-dropdown-item>
                  <el-dropdown-item divided command="logout">
                    <el-icon><SwitchButton /></el-icon>
                    退出登录
                  </el-dropdown-item>
                </el-dropdown-menu>
              </template>
            </el-dropdown>
          </div>
        </el-header>
        
        <!-- 页面内容 -->
        <el-main class="main-content">
          <router-view v-slot="{ Component }">
            <transition name="fade" mode="out-in">
              <component :is="Component" />
            </transition>
          </router-view>
        </el-main>
        
        <!-- 底部信息 -->
        <el-footer class="footer" height="40px">
          <div class="footer-content">
            <span>© 2026 医小伴陪诊服务平台. All Rights Reserved.</span>
            <span class="version">v1.0.0</span>
          </div>
        </el-footer>
      </el-container>
    </el-container>
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  Odometer,
  Document,
  User,
  UserFilled,
  Setting,
  OfficeBuilding,
  Tools,
  DocumentCopy,
  Expand,
  Fold,
  ArrowDown,
  SwitchButton
} from '@element-plus/icons-vue'

const route = useRoute()
const router = useRouter()

// 响应式数据
const isCollapse = ref(false)
const userInfo = ref({
  name: '管理员',
  avatar: 'https://cube.elemecdn.com/0/88/03b0d39583f48206768a7534e55bcpng.png',
  role: '超级管理员'
})

// 计算属性
const activeMenu = computed(() => {
  return route.path
})

const breadcrumb = computed(() => {
  const matched = route.matched.filter(item => item.meta && item.meta.title)
  return matched
})

// 方法
const toggleSidebar = () => {
  isCollapse.value = !isCollapse.value
}

const handleCommand = (command) => {
  switch (command) {
    case 'profile':
      ElMessage.info('个人中心功能开发中...')
      break
    case 'settings':
      ElMessage.info('账户设置功能开发中...')
      break
    case 'logout':
      handleLogout()
      break
  }
}

const handleLogout = () => {
  ElMessageBox.confirm(
    '确定要退出登录吗？',
    '退出确认',
    {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    }
  ).then(() => {
    // 这里应该调用退出登录的API
    ElMessage.success('退出登录成功')
    // 在实际应用中，这里应该跳转到登录页面
    // router.push('/login')
  }).catch(() => {
    // 用户取消操作
  })
}

// 监听路由变化
watch(
  () => route.path,
  () => {
    // 滚动到顶部
    window.scrollTo(0, 0)
  }
)
</script>

<style scoped>
.app-container {
  width: 100%;
  height: 100vh;
  overflow: hidden;
}

.main-container {
  height: 100%;
}

/* 侧边栏样式 */
.sidebar {
  background-color: #001529;
  color: #fff;
  display: flex;
  flex-direction: column;
  transition: width 0.3s;
  overflow: hidden;
}

.logo {
  padding: 20px;
  text-align: center;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}

.logo h1 {
  margin: 0;
  font-size: 20px;
  font-weight: 600;
  color: #fff;
}

.logo p {
  margin: 5px 0 0 0;
  font-size: 12px;
  color: rgba(255, 255, 255, 0.7);
}

.sidebar-menu {
  flex: 1;
  border-right: none;
  background-color: transparent;
}

.sidebar-menu :deep(.el-menu-item),
.sidebar-menu :deep(.el-sub-menu__title) {
  color: rgba(255, 255, 255, 0.7);
  height: 48px;
  line-height: 48px;
}

.sidebar-menu :deep(.el-menu-item:hover),
.sidebar-menu :deep(.el-sub-menu__title:hover) {
  background-color: rgba(255, 255, 255, 0.1);
}

.sidebar-menu :deep(.el-menu-item.is-active) {
  background-color: #1890ff;
  color: #fff;
}

.sidebar-menu :deep(.el-icon) {
  color: inherit;
}

.sidebar-footer {
  padding: 10px;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
  text-align: center;
}

.collapse-btn {
  color: rgba(255, 255, 255, 0.7);
  width: 100%;
}

.collapse-btn:hover {
  color: #fff;
}

/* 内容区样式 */
.content-container {
  display: flex;
  flex-direction: column;
}

.header {
  height: 60px;
  background-color: #fff;
  border-bottom: 1px solid #e8e8e8;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 20px;
}

.header-left {
  flex: 1;
}

.header-right {
  display: flex;
  align-items: center;
}

.user-info {
  display: flex;
  align-items: center;
  cursor: pointer;
  padding: 5px 10px;
  border-radius: 4px;
  transition: background-color 0.3s;
}

.user-info:hover {
  background-color: #f5f5f5;
}

.user-name {
  margin: 0 8px;
  font-size: 14px;
  color: #333;
}

.main-content {
  flex: 1;
  padding: 20px;
  background-color: #f0f2f5;
  overflow-y: auto;
}

.footer {
  background-color: #fff;
  border-top: 1px solid #e8e8e8;
  display: flex;
  align-items: center;
  justify-content: center;
}

.footer-content {
  font-size: 12px;
  color: #999;
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 100%;
  padding: 0 20px;
}

.version {
  font-weight: 500;
  color: #666;
}

/* 过渡动画 */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .sidebar {
    position: fixed;
    z-index: 1000;
    height: 100%;
  }
  
  .content-container {
    margin-left: 0;
  }
  
  .header {
    padding: 0 10px;
  }
  
  .main-content {
    padding: 10px;
  }
  
  .footer-content {
    flex-direction: column;
    gap: 5px;
    text-align: center;
  }
}
</style>