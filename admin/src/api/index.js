// 管理后台 API 服务
// 对接医小伴真实后端（通过 Nginx 反向代理）

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || '/api'

// Token 管理
const getAdminToken = () => localStorage.getItem('admin_token') || ''
const setAdminToken = (t) => localStorage.setItem('admin_token', t)
const clearAdminToken = () => localStorage.removeItem('admin_token')

// 通用请求函数
async function apiRequest(url, options = {}) {
  const { method = 'GET', data, params } = options
  const token = getAdminToken()

  // 构建 URL
  let requestUrl = `${API_BASE_URL}${url}`
  if (params) {
    const qp = new URLSearchParams()
    Object.entries(params).forEach(([k, v]) => { if (v !== undefined && v !== null && v !== '') qp.append(k, v) })
    const qs = qp.toString()
    if (qs) requestUrl += `?${qs}`
  }

  const headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  }
  if (token) headers['Authorization'] = `Bearer ${token}`

  try {
    const res = await fetch(requestUrl, {
      method,
      headers,
      body: data ? JSON.stringify(data) : undefined,
    })
    const json = await res.json()
    return json
  } catch (e) {
    console.error(`[API] ${method} ${url} 失败:`, e)
    return { success: false, message: '网络错误' }
  }
}

// 导出
export default {
  // 认证
  login: (phone, password) => {
    return apiRequest('/auth/login', { method: 'POST', data: { phone, password } })
  },
  getProfile: () => apiRequest('/auth/profile'),

  // 仪表板
  getDashboardStats: () => apiRequest('/admin/dashboard'),
  getRecentOrders: () => apiRequest('/admin/consultations', { params: { page_size: 10 } }),

  // 普通订单管理（陪诊订单）
  getOrders: (params) => apiRequest('/admin/orders', { params }),
  getOrderDetail: (id) => apiRequest(`/admin/orders/${id}`),

  // 用户管理
  getUsers: (params) => apiRequest('/admin/users', { params }),
  getUserStats: () => apiRequest('/admin/users/stats'),
  getUserDetail: (id) => apiRequest(`/admin/users/${id}`),

  // 陪诊师
  getCompanions: (params) => apiRequest('/admin/companions', { params }),
  getCompanionStats: () => apiRequest('/admin/companions/stats'),

  // 医生认证审核
  getDoctorCertifications: (params) => apiRequest('/admin/doctors/certifications', { params }),
  reviewDoctorCertification: (id, data) => apiRequest(`/admin/doctors/certifications/${id}/review`, { method: 'POST', data }),

  // 问诊管理
  getConsultations: (params) => apiRequest('/admin/consultations', { params }),
  getConsultationStats: () => apiRequest('/admin/consultations/stats'),
  getConsultationDetail: (id) => apiRequest(`/admin/consultations/${id}`),

  // 处方管理
  getPrescriptions: (params) => apiRequest('/admin/prescriptions', { params }),
  getPrescriptionDetail: (id) => apiRequest(`/admin/prescriptions/${id}`),

  // 通用方法
  get: (url, params) => apiRequest(url, { params }),
  post: (url, data) => apiRequest(url, { method: 'POST', data }),
  put: (url, data) => apiRequest(url, { method: 'PUT', data }),
  delete: (url) => apiRequest(url, { method: 'DELETE' }),
}
