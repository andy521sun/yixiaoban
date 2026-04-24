<template>
  <div class="companions-container">
    <!-- 页面标题和操作栏 -->
    <div class="page-header">
      <h1>陪诊师管理</h1>
      <div class="header-actions">
        <el-button type="primary" @click="handleCreateCompanion">
          <el-icon><UserAdd /></el-icon>
          新增陪诊师
        </el-button>
        <el-button @click="refreshData">
          <el-icon><Refresh /></el-icon>
          刷新
        </el-button>
        <el-button @click="handleImport">
          <el-icon><Upload /></el-icon>
          导入
        </el-button>
      </div>
    </div>

    <!-- 筛选条件 -->
    <div class="filter-container">
      <el-form :inline="true" :model="filterForm">
        <el-form-item label="审核状态">
          <el-select
            v-model="filterForm.verifyStatus"
            placeholder="请选择审核状态"
            clearable
            style="width: 120px"
          >
            <el-option label="待审核" value="pending" />
            <el-option label="已通过" value="approved" />
            <el-option label="已拒绝" value="rejected" />
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
        
        <el-form-item label="专长科室">
          <el-select
            v-model="filterForm.specialty"
            placeholder="请选择专长科室"
            clearable
            filterable
            style="width: 150px"
          >
            <el-option
              v-for="item in specialtyOptions"
              :key="item.value"
              :label="item.label"
              :value="item.value"
            />
          </el-select>
        </el-form-item>
        
        <el-form-item label="评分">
          <el-select
            v-model="filterForm.minRating"
            placeholder="最低评分"
            clearable
            style="width: 120px"
          >
            <el-option label="4.0分以上" value="4.0" />
            <el-option label="4.5分以上" value="4.5" />
            <el-option label="4.8分以上" value="4.8" />
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

    <!-- 陪诊师表格 -->
    <div class="table-container">
      <el-table
        :data="companionList"
        v-loading="loading"
        border
        stripe
        style="width: 100%"
        @selection-change="handleSelectionChange"
      >
        <el-table-column type="selection" width="55" />
        
        <el-table-column prop="id" label="ID" width="80" />
        
        <el-table-column prop="name" label="陪诊师" width="180">
          <template #default="{ row }">
            <div class="companion-info">
              <el-avatar :size="40" :src="row.avatar" class="avatar">
                {{ row.name.charAt(0) }}
              </el-avatar>
              <div class="info">
                <div class="name-row">
                  <span class="name">{{ row.name }}</span>
                  <el-tag :type="getGenderTag(row.gender)" size="small">
                    {{ getGenderText(row.gender) }}
                  </el-tag>
                  <span class="age">{{ row.age }}岁</span>
                </div>
                <div class="rating-row">
                  <el-rate
                    v-model="row.rating"
                    disabled
                    show-score
                    text-color="#ff9900"
                    score-template="{value}"
                    size="small"
                  />
                  <span class="review-count">({{ row.reviewCount }}评价)</span>
                </div>
              </div>
            </div>
          </template>
        </el-table-column>
        
        <el-table-column prop="phone" label="联系方式" width="150">
          <template #default="{ row }">
            <div class="contact-info">
              <div class="phone">{{ row.phone }}</div>
              <div class="wechat" v-if="row.wechat">
                <el-icon><ChatLineRound /></el-icon>
                {{ row.wechat }}
              </div>
            </div>
          </template>
        </el-table-column>
        
        <el-table-column prop="specialties" label="专长科室" width="200">
          <template #default="{ row }">
            <div class="specialties">
              <el-tag
                v-for="specialty in row.specialties.slice(0, 3)"
                :key="specialty"
                type="info"
                size="small"
                class="specialty-tag"
              >
                {{ specialty }}
              </el-tag>
              <el-tag
                v-if="row.specialties.length > 3"
                type="info"
                size="small"
              >
                +{{ row.specialties.length - 3 }}
              </el-tag>
            </div>
          </template>
        </el-table-column>
        
        <el-table-column prop="certificates" label="资格证书" width="180">
          <template #default="{ row }">
            <div class="certificates">
              <el-tag
                v-for="cert in row.certificates.slice(0, 2)"
                :key="cert"
                type="success"
                size="small"
                class="cert-tag"
              >
                {{ cert }}
              </el-tag>
              <el-tag
                v-if="row.certificates.length > 2"
                type="success"
                size="small"
              >
                +{{ row.certificates.length - 2 }}
              </el-tag>
            </div>
          </template>
        </el-table-column>
        
        <el-table-column prop="experience" label="经验" width="120">
          <template #default="{ row }">
            <div class="experience">
              <div class="years">{{ row.experienceYears }}年经验</div>
              <div class="service-count">服务{{ row.serviceCount }}次</div>
            </div>
          </template>
        </el-table-column>
        
        <el-table-column prop="verifyStatus" label="审核状态" width="120">
          <template #default="{ row }">
            <el-tag :type="getVerifyStatusTag(row.verifyStatus)" size="small">
              {{ getVerifyStatusText(row.verifyStatus) }}
            </el-tag>
          </template>
        </el-table-column>
        
        <el-table-column prop="status" label="工作状态" width="120">
          <template #default="{ row }">
            <el-tag :type="getWorkStatusTag(row.workStatus)" size="small">
              {{ getWorkStatusText(row.workStatus) }}
            </el-tag>
          </template>
        </el-table-column>
        
        <el-table-column prop="registerTime" label="注册时间" width="180">
          <template #default="{ row }">
            {{ formatDateTime(row.registerTime) }}
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
              @click="handleEditCompanion(row)"
            >
              编辑
            </el-button>
            <el-button
              size="small"
              :type="row.verifyStatus === 'approved' ? 'danger' : 'success'"
              @click="handleToggleVerify(row)"
              :disabled="row.verifyStatus === 'rejected'"
            >
              {{ row.verifyStatus === 'approved' ? '取消认证' : '通过审核' }}
            </el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <!-- 批量操作 -->
    <div class="batch-actions" v-if="selectedCompanions.length > 0">
      <el-space>
        <span>已选择 {{ selectedCompanions.length }} 个陪诊师</span>
        <el-button size="small" type="success" @click="batchApprove" :disabled="!canBatchApprove">
          批量通过
        </el-button>
        <el-button size="small" type="danger" @click="batchReject" :disabled="!canBatchReject">
          批量拒绝
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
              <div class="stat-icon total">
                <el-icon><User /></el-icon>
              </div>
              <div class="stat-info">
                <div class="stat-value">{{ stats.totalCount }}</div>
                <div class="stat-label">陪诊师总数</div>
              </div>
            </div>
          </el-card>
        </el-col>
        
        <el-col :span="6">
          <el-card class="stat-card">
            <div class="stat-content">
              <div class="stat-icon approved">
                <el-icon><CircleCheck /></el-icon>
              </div>
              <div class="stat-info">
                <div class="stat-value">{{ stats.approvedCount }}</div>
                <div class="stat-label">已认证</div>
              </div>
            </div>
          </el-card>
        </el-col>
        
        <el-col :span="6">
          <el-card class="stat-card">
            <div class="stat-content">
              <div class="stat-icon pending">
                <el-icon><Clock /></el-icon>
              </div>
              <div class="stat-info">
                <div class="stat-value">{{ stats.pendingCount }}</div>
                <div class="stat-label">待审核</div>
              </div>
            </div>
          </el-card>
        </el-col>
        
        <el-col :span="6">
          <el-card class="stat-card">
            <div class="stat-content">
              <div class="stat-icon online">
                <el-icon><VideoPlay /></el-icon>
              </div>
              <div class="stat-info">
                <div class="stat-value">{{ stats.onlineCount }}</div>
                <div class="stat-label">在线</div>
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
import { UserAdd, Refresh, Upload, Search, User, CircleCheck, Clock, VideoPlay, ChatLineRound } from '@element-plus/icons-vue'

// 响应式数据
const loading = ref(false)
const companionList = ref([])
const selectedCompanions = ref([])

// 筛选表单
const filterForm = reactive({
  verifyStatus: '',
  name: '',
  phone: '',
  specialty: '',
  minRating: '',
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
  totalCount: 0,
  approvedCount: 0,
  pendingCount: 0,
  onlineCount: 0
})

// 专长科室选项
const specialtyOptions = [
  { value: 'cardiology', label: '心血管内科' },
  { value: 'neurology', label: '神经内科' },
  { value: 'respiratory', label: '呼吸内科' },
  { value: 'gastroenterology', label: '消化内科' },
  { value: 'endocrinology', label: '内分泌科' },
  { value: 'nephrology', label: '肾内科' },
  { value: 'rheumatology', label: '风湿免疫科' },
  { value: 'oncology', label: '肿瘤科' },
  { value: 'pediatrics', label: '儿科' },
  { value: 'geriatrics', label: '老年科' },
  { value: 'psychiatry', label: '精神心理科' },
  { value: 'rehabilitation', label: '康复医学科' },
  { value: 'surgery', label: '外科' },
  { value: 'orthopedics', label: '骨科' },
  { value: 'urology', label: '泌尿外科' },
  { value: 'gynecology', label: '妇科' },
  { value: 'obstetrics', label: '产科' },
  { value: 'ophthalmology', label: '眼科' },
  { value: 'ent', label: '耳鼻喉科' },
  { value: 'dermatology', label: '皮肤科' },
  { value: 'stomatology', label: '口腔科' },
  { value: 'emergency', label: '急诊科' },
  { value: 'icu', label: '重症医学科' },
  { value: 'imaging', label: '影像科' },
  { value: 'pathology', label: '病理科' }
]

// 状态映射
const verifyStatusMap = {
  pending: { text: '待审核', type: 'warning' },
  approved: { text: '已通过', type: 'success' },
  rejected: { text: '已拒绝', type: 'danger' }
}

const workStatusMap = {
  online: { text: '在线', type: 'success' },
  offline: { text: '离线', type: 'info' },
  busy: { text: '忙碌', type: 'warning' },
  resting: { text: '休息', type: 'info' }
}

const genderMap = {
  male: { text: '男', type: 'primary' },
  female: { text: '女', type: 'danger' },
  unknown: { text: '未知', type: 'info' }
}

// 计算属性
const canBatchApprove = computed(() => {
  return selectedCompanions.value.some(companion => 
    companion.verifyStatus === 'pending' || companion.verifyStatus === 'rejected'
  )
})

const canBatchReject = computed(() => {
  return selectedCompanions.value.some(companion => 
    companion.verifyStatus === 'pending' || companion.verifyStatus === 'approved'
  )
})

// 生命周期钩子
onMounted(() => {
  fetchCompanionList()
  fetchStats()
})

// 获取陪诊师列表
const fetchCompanionList = async () => {
  loading.value = true
  try {
    // 模拟API调用
    await new Promise(resolve => setTimeout(resolve, 500))
    
    // 模拟数据
    companionList.value = Array.from({ length: 50 }, (_, index) => {
      const gender = index % 2 === 0 ? 'male' : 'female'
      const verifyStatus = index % 5 === 0 ? 'pending' : index % 5 === 1 ? 'rejected' : 'approved'
      const workStatus = index % 4 === 0 ? 'online' : index % 4 === 1 ? 'offline' : index % 4 === 2 ? 'busy' : 'resting'
      
      // 随机专长科室
      const specialtyCount = 3 + (index % 4)
      const specialties = []
      for (let i = 0; i < specialtyCount; i++) {
        const specialtyIndex = (index + i) % specialtyOptions.length
        specialties.push(specialtyOptions[specialtyIndex].label)
      }
      
      // 随机资格证书
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
    })
    
    pagination.total = companionList.value.length
  } catch (error) {
    ElMessage.error('获取陪诊师列表失败：' + error.message)
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
    stats.totalCount = 342
    stats.approvedCount = 298
    stats.pendingCount = 32
    stats.onlineCount = 156
  } catch (error) {
    ElMessage.error('获取统计信息失败：' + error.message)
  }
}

// 搜索处理
const handleSearch = () => {
  pagination.currentPage = 1
  fetchCompanionList()
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
  fetchCompanionList()
}

// 刷新数据
const refreshData = () => {
  fetchCompanionList()
  fetchStats()
}

// 导入数据
const handleImport = () => {
  ElMessage.info('导入功能开发中...')
}

// 创建陪诊师
const handleCreateCompanion = () => {
  ElMessage.info('创建陪诊师功能开发中...')
}

// 查看详情
const handleViewDetail = (row) => {
  ElMessage.info(`查看陪诊师详情：${row.name}`)
}

// 编辑陪诊师
const handleEditCompanion = (row) => {
  ElMessage.info(`编辑陪诊师：${row.name}`)
}

// 切换审核状态
const handleToggleVerify = (row) => {
  const newStatus = row.verifyStatus === 'approved' ? 'pending' : 'approved'
  const action = newStatus === 'approved' ? '通过审核' : '取消认证'
  
  ElMessageBox.confirm(
    `确定要${action}陪诊师 ${row.name} 吗？`,
    `${action}确认`,
    {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: newStatus === 'approved' ? 'success' : 'warning'
    }
  ).then(async () => {
    try {
      // 模拟API调用
      await new Promise(resolve => setTimeout(resolve, 300))
      row.verifyStatus = newStatus
      ElMessage.success(`陪诊师${action}成功`)
      fetchStats() // 刷新统计信息
    } catch (error) {
      ElMessage.error(`${action}失败：` + error.message)
    }
  }).catch(() => {
    // 用户取消操作
  })
}

// 批量操作
const handleSelectionChange = (selection) => {
  selectedCompanions.value = selection
}

const batchApprove = async () => {
  if (selectedCompanions.value.length === 0) return
  
  ElMessageBox.confirm(
    `确定要通过 ${selectedCompanions.value.length} 个陪诊师的审核吗？`,
    '批量通过确认',
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
      
      selectedCompanions.value.forEach(companion => {
        if (companion.verifyStatus !== 'approved') {
          companion.verifyStatus = 'approved'
        }
      })
      
      ElMessage.success(`成功通过 ${selectedCompanions.value.length} 个陪诊师的审核`)
      selectedCompanions.value = []
      fetchStats() // 刷新统计信息
    } catch (error) {
      ElMessage.error('批量通过失败：' + error.message)
    } finally {
      loading.value = false
    }
  }).catch(() => {
    // 用户取消操作
  })
}

const batchReject = async () => {
  if (selectedCompanions.value.length === 0) return
  
  ElMessageBox.confirm(
    `确定要拒绝 ${selectedCompanions.value.length} 个陪诊师的审核吗？`,
    '批量拒绝确认',
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
      
      selectedCompanions.value.forEach(companion => {
        if (companion.verifyStatus !== 'rejected') {
          companion.verifyStatus = 'rejected'
        }
      })
      
      ElMessage.success(`成功拒绝 ${selectedCompanions.value.length} 个陪诊师的审核`)
      selectedCompanions.value = []
      fetchStats() // 刷新统计信息
    } catch (error) {
      ElMessage.error('批量拒绝失败：' + error.message)
    } finally {
      loading.value = false
    }
  }).catch(() => {
    // 用户取消操作
  })
}

const clearSelection = () => {
  selectedCompanions.value = []
}

// 分页处理
const handleSizeChange = (size) => {
  pagination.pageSize = size
  fetchCompanionList()
}

const handleCurrentChange = (page) => {
  pagination.currentPage = page
  fetchCompanionList()
}

// 工具函数
const getVerifyStatusText = (status) => {
  return verifyStatusMap[status]?.text || status
}

const getVerifyStatusTag = (status) => {
  return verifyStatusMap[status]?.type || 'info'
}

const getWorkStatusText = (status) => {
  return workStatusMap[status]?.text || status
}

const getWorkStatusTag = (status) => {
  return workStatusMap[status]?.type || 'info'
}

const getGenderText = (gender) => {
  return genderMap[gender]?.text || gender
}

const getGenderTag = (gender) => {
  return genderMap[gender]?.type || 'info'
}

const formatDateTime = (dateString) => {
  if (!dateString) return ''
  const date = new Date(dateString)
  return date.toLocaleString('zh-CN')
}
</script>

<style scoped>
.companions-container {
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

.stat-icon.total {
  background: linear-gradient(135deg, #409eff, #337ecc);
}

.stat-icon.approved {
  background: linear-gradient(135deg, #67c23a, #529b2e);
}

.stat-icon.pending {
  background: linear-gradient(135deg, #e6a23c, #b88230);
}

.stat-icon.online {
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

.companion-info {
  display: flex;
  align-items: center;
  gap: 12px;
}

.companion-info .avatar {
  flex-shrink: 0;
}

.companion-info .info {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.name-row {
  display: flex;
  align-items: center;
  gap: 8px;
}

.name-row .name {
  font-weight: 600;
  color: #303133;
  font-size: 14px;
}

.name-row .age {
  font-size: 12px;
  color: #909399;
}

.rating-row {
  display: flex;
  align-items: center;
  gap: 8px;
}

.rating-row .review-count {
  font-size: 12px;
  color: #909399;
}

.contact-info {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.contact-info .phone {
  font-weight: 500;
  color: #303133;
}

.contact-info .wechat {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 12px;
  color: #909399;
}

.specialties {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
}

.specialty-tag {
  margin: 2px;
}

.certificates {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
}

.cert-tag {
  margin: 2px;
}

.experience {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.experience .years {
  font-weight: 500;
  color: #303133;
}

.experience .service-count {
  font-size: 12px;
  color: #909399;
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