import { createRouter, createWebHistory } from 'vue-router'

import Login from '../views/Login.vue'
import Dashboard from '../views/Dashboard.vue'
import Orders from '../views/Orders.vue'
import Users from '../views/Users.vue'
import Companions from '../views/Companions.vue'
import DoctorCertifications from '../views/DoctorCertifications.vue'
import Consultations from '../views/Consultations.vue'
import Prescriptions from '../views/Prescriptions.vue'
import ContentReports from '../views/ContentReports.vue'

const routes = [
  {
    path: '/login',
    name: 'Login',
    component: Login,
    meta: { title: '登录', noAuth: true }
  },
  {
    path: '/',
    name: 'Dashboard',
    component: Dashboard,
    meta: { title: '仪表板', icon: 'Odometer', requiresAuth: true }
  },
  {
    path: '/orders',
    name: 'Orders',
    component: Orders,
    meta: { title: '订单管理', icon: 'Document', requiresAuth: true }
  },
  {
    path: '/users',
    name: 'Users',
    component: Users,
    meta: { title: '用户管理', icon: 'User', requiresAuth: true }
  },
  {
    path: '/companions',
    name: 'Companions',
    component: Companions,
    meta: { title: '陪诊师管理', icon: 'UserFilled', requiresAuth: true }
  },
  {
    path: '/doctors/certifications',
    name: 'DoctorCertifications',
    component: DoctorCertifications,
    meta: { title: '医生认证审核', icon: 'Checked', requiresAuth: true }
  },
  {
    path: '/consultations',
    name: 'Consultations',
    component: Consultations,
    meta: { title: '问诊管理', icon: 'ChatDotSquare', requiresAuth: true }
  },
  {
    path: '/prescriptions',
    name: 'Prescriptions',
    component: Prescriptions,
    meta: { title: '处方管理', icon: 'DocumentCopy', requiresAuth: true }
  },
  {
    path: '/content-reports',
    name: 'ContentReports',
    component: ContentReports,
    meta: { title: '内容审核', icon: 'WarnTriangleFilled', requiresAuth: true }
  },
  {
    path: '/:pathMatch(.*)*',
    redirect: '/'
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// Token 工具
function getAdminToken() {
  try { return localStorage.getItem('admin_token') || '' } catch { return '' }
}

// 路由守卫 — 未登录自动跳登录页
router.beforeEach((to, from, next) => {
  if (to.meta.title) {
    document.title = `${to.meta.title} - 医小伴管理后台`
  }

  const token = getAdminToken()
  const noAuth = to.meta && to.meta.noAuth

  if (noAuth) {
    // 已登录用户访问登录页 -> 跳仪表板
    if (token) return next('/')
    return next()
  }

  if (to.meta.requiresAuth && !token) {
    return next('/login')
  }

  next()
})

export default router
