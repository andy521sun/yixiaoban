import { createRouter, createWebHistory } from 'vue-router'

// 导入组件
import Dashboard from '../views/Dashboard.vue'
import Orders from '../views/Orders.vue'
import Users from '../views/Users.vue'
import Companions from '../views/Companions.vue'

// 路由配置
const routes = [
  {
    path: '/',
    name: 'Dashboard',
    component: Dashboard,
    meta: {
      title: '仪表板',
      icon: 'Odometer',
      requiresAuth: true
    }
  },
  {
    path: '/orders',
    name: 'Orders',
    component: Orders,
    meta: {
      title: '订单管理',
      icon: 'Document',
      requiresAuth: true
    }
  },
  {
    path: '/users',
    name: 'Users',
    component: Users,
    meta: {
      title: '用户管理',
      icon: 'User',
      requiresAuth: true
    }
  },
  {
    path: '/companions',
    name: 'Companions',
    component: Companions,
    meta: {
      title: '陪诊师管理',
      icon: 'UserFilled',
      requiresAuth: true
    }
  },
  {
    path: '/:pathMatch(.*)*',
    redirect: '/'
  }
]

// 创建路由实例
const router = createRouter({
  history: createWebHistory(),
  routes
})

// 路由守卫
router.beforeEach((to, from, next) => {
  // 设置页面标题
  if (to.meta.title) {
    document.title = `${to.meta.title} - 医小伴管理后台`
  }
  
  // 检查是否需要认证
  if (to.meta.requiresAuth) {
    // 这里可以添加认证逻辑
    // const isAuthenticated = checkAuth()
    // if (!isAuthenticated) {
    //   next('/login')
    // } else {
    //   next()
    // }
    next()
  } else {
    next()
  }
})

export default router