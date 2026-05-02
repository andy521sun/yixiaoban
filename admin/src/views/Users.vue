<template>
  <div class="users-container">
    <!-- 页面标题和操作栏 -->
    <div class="page-header">
      <h1>用户管理</h1>
      <div class="header-actions">
        <el-button type="primary" @click="handleCreateUser">
          <el-icon><User /></el-icon>
          新增用户
        </el-button>
        <el-button @click="refreshData">
          <el-icon><Refresh /></el-icon>
          刷新
        </el-button>
        <el-button @click="exportData">
          <el-icon><Download /></el-icon>
          导出
        </el-button>
      </div>
    </div>

    <!-- 筛选条件 -->
    <div class="filter-container">
      <el-form :inline="true" :model="filterForm">
        <el-form-item label="用户类型">
          <el-select
            v-model="filterForm.userType"
            placeholder="请选择用户类型"
            clearable
            style="width: 120px"
          >
            <el-option label="患者" value="patient" />
            <el-option label="陪诊师" value="companion" />
            <el-option label="管理员" value="admin" />
          </el-select>
        </el-form-item>
        
        <el-form-item label="姓名">
          <el-input
            v-model="filterForm.name"
            placeholder="请输入姓名"
            clearable
            style="width: 150px"
          />
        </el-form-item>
        
        <el-form-item label="手机号">
          <el-input
            v-model="filterForm.phone"
            placeholder="请输入手机号"
            clearable
            style="width: 150px"
          />
        </el-form-item>
        
        <el-form-item label="状态">
          <el-select
            v-model="filterForm.status"
            placeholder="请选择状态"
            clearable
            style="width: 120px"
          >
            <el-option label="正常" value="active" />
            <el-option label="禁用" value="disabled" />
            <el-option label="未验证" value="unverified" />
          </el-select>
        </el-form-item>
        
        <el-form-item label="注册时间">
          <el-date-picker
            v-model="filterForm.registerDateRange"
            type="daterange"
            range-separator="至"
            start-placeholder="开始日期"
            end-placeholder="结束日期"
            value-format="YYYY-MM-DD"
            style="width: 300px"
          />
        </el-form-item>
        
        <el-form-item>
          <el-button type="primary" @click="handleSearch">
            <el-icon><Search /></el-icon>
            搜索
          </el-button>
          <el-button @click="resetFilter">
            <el-icon><Refresh /></el-icon>
            重置
          </el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 用户表格 -->
    <div class="table-container">
      <el-table
        :data="userList"
        v-loading="loading"
        border
        stripe
        style="width: 100%"
        @selection-change="handleSelectionChange"
      >
        <el-table-column type="selection" width="55" />
        
        <el-table-column prop="id" label="用户ID" width="100" />
        
        <el-table-column prop="name" label="姓名" width="120">
          <template #default="{ row }">
            <div class="user-info">
              <el-avatar :size="32" :src="row.avatar" class="avatar">
                {{ row.name.charAt(0) }}
              </el-avatar>
              <div class="info">
                <div class="name">{{ row.name }}</div>
                <div class="type">
                  <el-tag :type="getUserTypeTag(row.userType)" size="small">
                    {{ getUserTypeText(row.userType) }}
                  </el-tag>
                </div>
              </div>
            </div>
          </template>
        </el-table-column>
        
        <el-table-column prop="phone" label="手机号" width="150" />
        
        <el-table-column prop="gender" label="性别" width="80">
          <template #default="{ row }">
            {{ getGenderText(row.gender) }}
          </template>
        </el-table-column>
        
        <el-table-column prop="age" label="年龄" width="80" />
        
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="getStatusTag(row.status)" size="small">
              {{ getStatusText(row.status) }}
            </el-tag>
          </template>
        </el-table-column>
        
        <el-table-column prop="registerTime" label="注册时间" width="180">
          <template #default="{ row }">
            {{ formatDateTime(row.registerTime) }}
          </template>
        </el-table-column>
        
        <el-table-column prop="lastLogin" label="最后登录" width="180">
          <template #default="{ row }">
            {{ formatDateTime(row.lastLogin) }}
          </template>
        </el-table-column>
        
        <el-table-column prop="orderCount" label="订单数" width="100" align="center">
          <template #default="{ row }">
            <span v-if="row.userType === 'patient'">{{ row.orderCount || 0 }}</span>
            <span v-else-if="row.userType === 'companion'">{{ row.serviceCount || 0 }}</span>
            <span v-else>-</span>
          </template>
        </el-table-column>
        
        <el-table-column prop="rating" label="评分" width="100" align="center">
          <template #default="{ row }">
            <el-rate
              v-if="row.userType === 'companion' && row.rating"
              v-model="row.rating"
              disabled
              show-score
              text-color="#ff9900"
              score-template="{value}"
              size="small"
            />
            <span v-else>-</span>
          </template>
        </el-table-column>
        
        <el-table-column label="操作" width="250" fixed="right">
          <template #default="{ row }">
            <el-button
              size="small"
              type="primary"
              @click="handleViewDetail(row)"
            >
              详情
            </el-button>
            <el-button
              size="small"
              type="warning"
              @click="handleEditUser(row)"
            >
              编辑
            </el-button>
            <el-button
              size="small"
              :type="row.status === 'active' ? 'danger' : 'success'"
              @click="handleToggleStatus(row)"
            >
              {{ row.status === 'active' ? '禁用' : '启用' }}
            </el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <!-- 批量操作 -->
    <div class="batch-actions" v-if="selectedUsers.length > 0">
      <el-space>
        <span>已选择 {{ selectedUsers.length }} 个用户</span>
        <el-button size="small" @click="batchEnable" :disabled="!canBatchEnable">
          批量启用
        </el-button>
        <el-button size="small" type="danger" @click="batchDisable" :disabled="!canBatchDisable">
          批量禁用
        </el-button>
        <el-button size="small" @click="clearSelection">
          取消选择
        </el-button>
      </el-space>
    </div>

    <!-- 分页 -->
    <div class="pagination-container">
      <el-pagination
        v-model:current-page="pagination.currentPage"
        v-model:page-size="pagination.pageSize"
        :total="pagination.total"
        :page-sizes="[10, 20, 50, 100]"
        layout="total, sizes, prev, pager, next, jumper"
        @size-change="handleSizeChange"
        @current-change="handleCurrentChange"
      />
    </div>

    <!-- 统计卡片 -->
    <div class="stats-container">
      <el-row :gutter="20">
        <el-col :span="6">
          <el-card class="stat-card">
            <div class="stat-content">
              <div class="stat-icon patient">
                <el-icon><User /></el-icon>
              </div>
              <div class="stat-info">
                <div class="stat-value">{{ stats.patientCount }}</div>
                <div class="stat-label">患者总数</div>
              </div>
            </div>
          </el-card>
        </el-col>
        
        <el-col :span="6">
          <el-card class="stat-card">
            <div class="stat-content">
              <div class="stat-icon companion">
                <el-icon><UserFilled /></el-icon>
              </div>
              <div class="stat-info">
                <div class="stat-value">{{ stats.companionCount }}</div>
                <div class="stat-label">陪诊师总数</div>
              </div>
            </div>
          </el-card>
        </el-col>
        
        <el-col :span="6">
          <el-card class="stat-card">
            <div class="stat-content">
              <div class="stat-icon active">
                <el-icon><CircleCheck /></el-icon>
              </div>
              <div class="stat-info">
                <div class="stat-value">{{ stats.activeCount }}</div>
                <div class="stat-label">活跃用户</div>
              </div>
            </div>
          </el-card>
        </el-col>
        
        <el-col :span="6">
          <el-card class="stat-card">
            <div class="stat-content">
              <div class="stat-icon today">
                <el-icon><TrendCharts /></el-icon>
              </div>
              <div class="stat-info">
                <div class="stat-value">{{ stats.todayRegister }}</div>
                <div class="stat-label">今日注册</div>
              </div>
            </div>
          </el-card>
        </el-col>
      </el-row>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, computed } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'

// 响应式数据
const loading = ref(false)
const userList = ref([])
const selectedUsers = ref([])

// 筛选表单
const filterForm = reactive({
  userType: '',
  name: '',
  phone: '',
  status: '',
  registerDateRange: []
})

// 分页配置
const pagination = reactive({
  currentPage: 1,
  pageSize: 20,
  total: 0
})

// 统计信息
const stats = reactive({
  patientCount: 0,
  companionCount: 0,
  activeCount: 0,
  todayRegister: 0
})

// 状态映射
const userTypeMap = {
  patient: { text: '患者', type: 'primary' },
  companion: { text: '陪诊师', type: 'success' },
  admin: { text: '管理员', type: 'warning' }
}

const statusMap = {
  active: { text: '正常', type: 'success' },
  disabled: { text: '禁用', type: 'danger' },
  unverified: { text: '未验证', type: 'warning' }
}

const genderMap = {
  male: '男',
  female: '女',
  unknown: '未知'
}

// 计算属性
const canBatchEnable = computed(() => {
  return selectedUsers.value.some(user => user.status !== 'active')
})

const canBatchDisable = computed(() => {
  return selectedUsers.value.some(user => user.status === 'active')
})

// 生命周期钩子
onMounted(() => {
  fetchUserList()
  fetchStats()
})

// 获取用户列表
const fetchUserList = async () => {
  loading.value = true
  try {
    // 模拟API调用
    await new Promise(resolve => setTimeout(resolve, 500))
    
    // 模拟数据
    userList.value = Array.from({ length: 50 }, (_, index) => {
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
    })
    
    pagination.total = userList.value.length
  } catch (error) {
    ElMessage.error('获取用户列表失败：' + error.message)
  } finally {
    loading.value = false
  }
}

// 获取统计信息
const fetchStats = async () => {
  try {
    // 模拟API调用
    await new Promise(resolve => setTimeout(resolve, 300))
    
    // 模拟数据
    stats.patientCount = 1256
    stats.companionCount = 342
    stats.activeCount = 1489
    stats.todayRegister = 23
  } catch (error) {
    ElMessage.error('获取统计信息失败：' + error.message)
  }
}

// 搜索处理
const handleSearch = () => {
  pagination.currentPage = 1
  fetchUserList()
}

// 重置筛选
const resetFilter = () => {
  Object.keys(filterForm).forEach(key => {
    if (Array.isArray(filterForm[key])) {
      filterForm[key] = []
    } else {
      filterForm[key] = ''
    }
  })
  pagination.currentPage = 1
  fetchUserList()
}

// 刷新数据
const refreshData = () => {
  fetchUserList()
  fetchStats()
}

// 导出数据
const exportData = () => {
  ElMessage.info('导出功能开发中...')
}

// 查看详情
const handleViewDetail = (row) => {
  ElMessage.info(`查看用户详情：${row.name}`)
}

// 创建用户
const handleCreateUser = () => {
  ElMessage.info('创建用户功能开发中...')
}

// 编辑用户
const handleEditUser = (row) => {
  ElMessage.info(`编辑用户：${row.name}`)
}

// 切换状态
const handleToggleStatus = (row) => {
  const newStatus = row.status === 'active' ? 'disabled' : 'active'
  const action = newStatus === 'active' ? '启用' : '禁用'
  
  ElMessageBox.confirm(
    `确定要${action}用户 ${row.name} 吗？`,
    `${action}用户确认`,
    {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: newStatus === 'active' ? 'success' : 'warning'
    }
  ).then(async () => {
    try {
      // 模拟API调用
      await new Promise(resolve => setTimeout(resolve, 300))
      row.status = newStatus
      ElMessage.success(`用户${action}成功`)
      fetchStats() // 刷新统计信息
    } catch (error) {
      ElMessage.error(`${action}用户失败：` + error.message)
    }
  }).catch(() => {
    // 用户取消操作
  })
}

// 批量操作
const handleSelectionChange = (selection) => {
  selectedUsers.value = selection
}

const batchEnable = async () => {
  if (selectedUsers.value.length === 0) return
  
  ElMessageBox.confirm(
    `确定要启用 ${selectedUsers.value.length} 个用户吗？`,
    '批量启用确认',
    {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'success'
    }
  ).then(async () => {
    try {
      loading.value = true
      // 模拟API调用
      await new Promise(resolve => setTimeout(resolve, 500))
      
      selectedUsers.value.forEach(user => {
        if (user.status !== 'active') {
          user.status = 'active'
        }
      })
      
      ElMessage.success(`成功启用 ${selectedUsers.value.length} 个用户`)
      selectedUsers.value = []
      fetchStats() // 刷新统计信息
    } catch (error) {
      ElMessage.error('批量启用失败：' + error.message)
    } finally {
      loading.value = false
    }
  }).catch(() => {
    // 用户取消操作
  })
}

const batchDisable = async () => {
  if (selectedUsers.value.length === 0) return
  
  ElMessageBox.confirm(
    `确定要禁用 ${selectedUsers.value.length} 个用户吗？`,
    '批量禁用确认',
    {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    }
  ).then(async () => {
    try {
      loading.value = true
      // 模拟API调用
      await new Promise(resolve => setTimeout(resolve, 500))
      
      selectedUsers.value.forEach(user => {
        if (user.status === 'active') {
          user.status = 'disabled'
        }
      })
      
      ElMessage.success(`成功禁用 ${selectedUsers.value.length} 个用户`)
      selectedUsers.value = []
      fetchStats() // 刷新统计信息
    } catch (error) {
      ElMessage.error('批量禁用失败：' + error.message)
    } finally {
      loading.value = false
    }
  }).catch(() => {
    // 用户取消操作
  })
}

const clearSelection = () => {
  selectedUsers.value = []
}

// 分页处理
const handleSizeChange = (size) => {
  pagination.pageSize = size
  fetchUserList()
}

const handleCurrentChange = (page) => {
  pagination.currentPage = page
  fetchUserList()
}

// 工具函数
const getUserTypeText = (type) => {
  return userTypeMap[type]?.text || type
}

const getUserTypeTag = (type) => {
  return userTypeMap[type]?.type || 'info'
}

const getStatusText = (status) => {
  return statusMap[status]?.text || status
}

const getStatusTag = (status) => {
  return statusMap[status]?.type || 'info'
}

const getGenderText = (gender) => {
  return genderMap[gender] || gender
}

const formatDateTime = (dateString) => {
  if (!dateString) return ''
  const date = new Date(dateString)
  return date.toLocaleString('zh-CN')
}
</script>

<style scoped>
.users-container {
  padding: 20px;
  background-color: #f5f7fa;
  min-height: calc(100vh - 60px);
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.page-header h1 {
  margin: 0;
  font-size: 24px;
  color: #303133;
}

.header-actions {
  display: flex;
  gap: 10px;
}

.filter-container {
  background-color: #fff;
  padding: 20px;
  border-radius: 4px;
  margin-bottom: 20px;
  box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.1);
}

.table-container {
  background-color: #fff;
  padding: 20px;
  border-radius: 4px;
  margin-bottom: 20px;
  box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.1);
}

.batch-actions {
  background-color: #fff;
  padding: 15px 20px;
  border-radius: 4px;
  margin-bottom: 20px;
  box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.1);
}

.pagination-container {
  display: flex;
  justify-content: flex-end;
  background-color: #fff;
  padding: 20px;
  border-radius: 4px;
  margin-bottom: 20px;
  box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.1);
}

.stats-container {
  margin-bottom: 20px;
}

.stat-card {
  border-radius: 8px;
  border: none;
  box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.1);
}

.stat-content {
  display: flex;
  align-items: center;
  gap: 20px;
}

.stat-icon {
  width: 60px;
  height: 60px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 28px;
  color: white;
}

.stat-icon.patient {
  background: linear-gradient(135deg, #409eff, #337ecc);
}

.stat-icon.companion {
  background: linear-gradient(135deg, #67c23a, #529b2e);
}

.stat-icon.active {
  background: linear-gradient(135deg, #e6a23c, #b88230);
}

.stat-icon.today {
  background: linear-gradient(135deg, #f56c6c, #c45656);
}

.stat-info {
  flex: 1;
}

.stat-value {
  font-size: 28px;
  font-weight: 700;
  color: #303133;
  line-height: 1;
  margin-bottom: 8px;
}

.stat-label {
  font-size: 14px;
  color: #909399;
}

.user-info {
  display: flex;
  align-items: center;
  gap: 12px;
}

.user-info .avatar {
  flex-shrink: 0;
}

.user-info .info {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.user-info .name {
  font-weight: 500;
  color: #303133;
}

.user-info .type {
  font-size: 12px;
}

:deep(.el-table) {
  font-size: 14px;
}

:deep(.el-table th) {
  background-color: #f5f7fa;
  font-weight: 600;
  color: #303133;
}

:deep(.el-table--border) {
  border: 1px solid #ebeef5;
  border-radius: 4px;
}

:deep(.el-table--striped .el-table__body tr.el-table__row--striped td) {
  background-color: #fafafa;
}

:deep(.el-rate) {
  --el-rate-font-size: 14px;
}
</style>
