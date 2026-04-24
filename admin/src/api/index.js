// API服务模块
const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || '/api'

// 模拟延迟
const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms))

// 模拟数据
const mockData = {
  // 仪表板数据
  dashboard: {
    stats: {
      totalUsers: 1256,
      totalCompanions: 342,
      totalOrders: 2894,
      totalRevenue: 568920
    },
    recentOrders: [
      {
        order_no: 'ORD20240415001',
        patient_name: '张先生',
        companion_name: '王陪诊师',
        hospital_name: '北京市第一人民医院',
        amount: 299,
        status: 'ongoing',
        created_at: '2026-04-15 10:30:00'
      },
      {
        order_no: 'ORD20240415002',
        patient_name: '李女士',
        companion_name: '李陪诊师',
        hospital_name: '北京市协和医院',
        amount: 399,
        status: 'accepted',
        created_at: '2026-04-15 09:15:00'
      },
      {
        order_no: 'ORD20240414001',
        patient_name: '王先生',
        companion_name: '张陪诊师',
        hospital_name: '北京大学人民医院',
        amount: 199,
        status: 'completed',
        created_at: '2026-04-14 14:20:00'
      },
      {
        order_no: 'ORD20240414002',
        patient_name: '赵女士',
        companion_name: '刘陪诊师',
        hospital_name: '北京天坛医院',
        amount: 499,
        status: 'pending',
        created_at: '2026-04-14 11:45:00'
      },
      {
        order_no: 'ORD20240413001',
        patient_name: '孙先生',
        companion_name: '陈陪诊师',
        hospital_name: '北京儿童医院',
        amount: 599,
        status: 'cancelled',
        created_at: '2026-04-13 16:30:00'
      }
    ]
  },
  
  // 订单数据
  orders: {
    list: Array.from({ length: 50 }, (_, index) => ({
      id: `ORD${String(index + 1).padStart(6, '0')}`,
      orderNo: `ORD${String(index + 1).padStart(6, '0')}`,
      patientName: `患者${index + 1}`,
      patientPhone: `138${String(index + 1).padStart(8, '0')}`,
      companionName: `陪诊师${index + 1}`,
      companionPhone: `139${String(index + 1).padStart(8, '0')}`,
      hospitalName: `第${(index % 5) + 1}人民医院`,
      serviceType: ['consultation', 'hospitalization', 'examination', 'surgery'][index % 4],
      amount: 100 + (index % 10) * 50,
      status: ['pending_payment', 'waiting_accept', 'in_progress', 'completed', 'cancelled', 'refunded'][index % 6],
      createdAt: new Date(Date.now() - index * 3600000).toISOString(),
      appointmentTime: new Date(Date.now() + (index + 1) * 86400000).toISOString()
    })),
    
    detail: (id) => ({
      id: id,
      orderNo: id,
      patientName: '张先生',
      patientPhone: '13800138000',
      patientGender: 'male',
      patientAge: 45,
      patientIdCard: '110101198001011234',
      emergencyContact: '李女士',
      emergencyPhone: '13900139000',
      healthCondition: '高血压，需定期复查',
      
      companionName: '王陪诊师',
      companionPhone: '13900139001',
      companionGender: 'female',
      companionAge: 32,
      experienceYears: 5,
      companionRating: 4.8,
      specialties: ['心血管内科', '神经内科', '老年科'],
      certificates: ['护士执业证书', '陪诊师资格证书'],
      
      hospitalName: '北京市第一人民医院',
      hospitalLevel: '三级甲等',
      hospitalAddress: '北京市东城区东单大华路1号',
      hospitalPhone: '010-12345678',
      department: '心血管内科',
      doctorName: '李主任',
      visitType: '专家门诊',
      hospitalNotes: '需要提前预约',
      
      serviceType: 'consultation',
      amount: 299.00,
      serviceHours: 3,
      paymentMethod: 'wechat',
      status: 'in_progress',
      
      createdAt: new Date(Date.now() - 86400000).toISOString(),
      paidAt: new Date(Date.now() - 86300000).toISOString(),
      acceptedAt: new Date(Date.now() - 86200000).toISOString(),
      startedAt: new Date(Date.now() - 3600000).toISOString(),
      appointmentTime: new Date(Date.now() + 86400000).toISOString(),
      
      serviceItems: [
        '门诊挂号协助',
        '就诊陪同',
        '取药协助',
        '检查结果解读'
      ],
      specialRequirements: '需要轮椅协助',
      notes: '患者行动不便，需要特别照顾'
    })
  },
  
  // 用户数据
  users: {
    list: Array.from({ length: 50 }, (_, index) => {
      const userType = index % 3 === 0 ? 'patient' : index % 3 === 1 ? 'companion' : 'admin'
      const status = index % 5 === 0 ? 'disabled' : index % 5 === 1 ? 'unverified' : 'active'
      const gender = index % 2 === 0 ? 'male' : 'female'
      
      return {
        id: `USER${String(index + 1).padStart(6, '0')}`,
        name: userType === 'patient' ? `患者${index + 1}` : 
              userType === 'companion' ? `陪诊师${index + 1}` : `管理员${index + 1}`,
        avatar: `https://randomuser.me/api/portraits/${gender === 'male' ? 'men' : 'women'}/${index % 10}.jpg`,
        phone: `138${String(index + 1).padStart(8, '0')}`,
        gender: gender,
        age: 20 + (index % 40),
        userType: userType,
        status: status,
        registerTime: new Date(Date.now() - index * 86400000).toISOString(),
        lastLogin: new Date(Date.now() - (index % 24) * 3600000).toISOString(),
        orderCount: userType === 'patient' ? index % 10 : 0,
        serviceCount: userType === 'companion' ? index % 20 : 0,
        rating: userType === 'companion' ? 3.5 + (index % 15) / 10 : null
      }
    }),
    
    stats: {
      patientCount: 1256,
      companionCount: 342,
      activeCount: 1489,
      todayRegister: 23
    }
  },
  
  // 陪诊师数据
  companions: {
    list: Array.from({ length: 50 }, (_, index) => {
      const gender = index % 2 === 0 ? 'male' : 'female'
      const verifyStatus = index % 5 === 0 ? 'pending' : index % 5 === 1 ? 'rejected' : 'approved'
      const workStatus = index % 4 === 0 ? 'online' : index % 4 === 1 ? 'offline' : index % 4 === 2 ? 'busy' : 'resting'
      
      // 专长科室
      const specialtyOptions = [
        '心血管内科', '神经内科', '呼吸内科', '消化内科', '内分泌科',
        '肾内科', '风湿免疫科', '肿瘤科', '儿科', '老年科',
        '精神心理科', '康复医学科', '外科', '骨科', '泌尿外科',
        '妇科', '产科', '眼科', '耳鼻喉科', '皮肤科',
        '口腔科', '急诊科', '重症医学科', '影像科', '病理科'
      ]
      
      const specialtyCount = 3 + (index % 4)
      const specialties = []
      for (let i = 0; i < specialtyCount; i++) {
        const specialtyIndex = (index + i) % specialtyOptions.length
        specialties.push(specialtyOptions[specialtyIndex])
      }
      
      // 资格证书
      const certificates = []
      if (index % 3 !== 0) certificates.push('护士执业证书')
      if (index % 4 !== 0) certificates.push('陪诊师资格证书')
      if (index % 5 !== 0) certificates.push('急救证书')
      if (index % 6 !== 0) certificates.push('健康管理师证书')
      
      return {
        id: `COMP${String(index + 1).padStart(6, '0')}`,
        name: gender === 'male' ? `王${index + 1}` : `李${index + 1}`,
        avatar: `https://randomuser.me/api/portraits/${gender === 'male' ? 'men' : 'women'}/${index % 10}.jpg`,
        gender: gender,
        age: 25 + (index % 20),
        phone: `139${String(index + 1).padStart(8, '0')}`,
        wechat: index % 3 === 0 ? `wx_${index + 1}` : null,
        specialties: specialties,
        certificates: certificates,
        experienceYears: 1 + (index % 10),
        serviceCount: 10 + (index % 100),
        rating: 3.5 + (index % 15) / 10,
        reviewCount: 5 + (index % 50),
        verifyStatus: verifyStatus,
        workStatus: workStatus,
        registerTime: new Date(Date.now() - index * 86400000).toISOString(),
        lastActiveTime: new Date(Date.now() - (index % 24) * 3600000).toISOString()
      }
    }),
    
    stats: {
      totalCount: 342,
      approvedCount: 298,
      pendingCount: 32,
      onlineCount: 156
    }
  }
}

// API请求函数
const apiRequest = async (url, options = {}) => {
  const { method = 'GET', data, params } = options
  
  // 构建请求URL
  let requestUrl = `${API_BASE_URL}${url}`
  if (params) {
    const queryParams = new URLSearchParams(params).toString()
    requestUrl += `?${queryParams}`
  }
  
  // 模拟网络延迟
  await delay(300 + Math.random() * 200)
  
  // 根据URL返回模拟数据
  if (url === '/admin/dashboard/stats') {
    return { data: mockData.dashboard.stats }
  } else if (url === '/admin/orders/recent') {
    return { data: mockData.dashboard.recentOrders }
  } else if (url.startsWith('/admin/orders')) {
    if (url.includes('/detail/')) {
      const id = url.split('/').pop()
      return { data: mockData.orders.detail(id) }
    } else {
      // 分页处理
      const page = params?.page || 1
      const pageSize = params?.pageSize || 20
      const start = (page - 1) * pageSize
      const end = start + pageSize
      const list = mockData.orders.list.slice(start, end)
      return { 
        data: list,
        total: mockData.orders.list.length,
        page,
        pageSize
      }
    }
  } else if (url.startsWith('/admin/users')) {
    if (url === '/admin/users/stats') {
      return { data: mockData.users.stats }
    } else {
      // 分页处理
      const page = params?.page || 1
      const pageSize = params?.pageSize || 20
      const start = (page - 1) * pageSize
      const end = start + pageSize
      const list = mockData.users.list.slice(start, end)
      return { 
        data: list,
        total: mockData.users.list.length,
        page,
        pageSize
      }
    }
  } else if (url.startsWith('/admin/companions')) {
    if (url === '/admin/companions/stats') {
      return { data: mockData.companions.stats }
    } else {
      // 分页处理
      const page = params?.page || 1
      const pageSize = params?.pageSize || 20
      const start = (page - 1) * pageSize
      const end = start + pageSize
      const list = mockData.companions.list.slice(start, end)
      return { 
        data: list,
        total: mockData.companions.list.length,
        page,
        pageSize
      }
    }
  }
  
  // 默认返回空数据
  return { data: null }
}

// 导出API方法
export default {
  // 仪表板
  getDashboardStats: () => apiRequest('/admin/dashboard/stats'),
  getRecentOrders: () => apiRequest('/admin/orders/recent'),
  
  // 订单管理
  getOrders: (params) => apiRequest('/admin/orders', { params }),
  getOrderDetail: (id) => apiRequest(`/admin/orders/detail/${id}`),
  createOrder: (data) => apiRequest('/admin/orders', { method: 'POST', data }),
  updateOrder: (id, data) => apiRequest(`/admin/orders/${id}`, { method: 'PUT', data }),
  deleteOrder: (id) => apiRequest(`/admin/orders/${id}`, { method: 'DELETE' }),
  
  // 用户管理
  getUsers: (params) => apiRequest('/admin/users', { params }),
  getUserStats: () => apiRequest('/admin/users/stats'),
  getUserDetail: (id) => apiRequest(`/admin/users/detail/${id}`),
  createUser: (data) => apiRequest('/admin/users', { method: 'POST', data }),
  updateUser: (id, data) => apiRequest(`/admin/users/${id}`, { method: 'PUT', data }),
  deleteUser: (id) => apiRequest(`/admin/users/${id}`, { method: 'DELETE' }),
  
  // 陪诊师管理
  getCompanions: (params) => apiRequest('/admin/companions', { params }),
  getCompanionStats: () => apiRequest('/admin/companions/stats'),
  getCompanionDetail: (id) => apiRequest(`/admin/companions/detail/${id}`),
  createCompanion: (data) => apiRequest('/admin/companions', { method: 'POST', data }),
  updateCompanion: (id, data) => apiRequest(`/admin/companions/${id}`, { method: 'PUT', data }),
  deleteCompanion: (id) => apiRequest(`/admin/companions/${id}`, { method: 'DELETE' }),
  
  // 通用方法
  get: (url, params) => apiRequest(url, { params }),
  post: (url, data) => apiRequest(url, { method: 'POST', data }),
  put: (url, data) => apiRequest(url, { method: 'PUT', data }),
  delete: (url) => apiRequest(url, { method: 'DELETE' })
}