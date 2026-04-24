<template>
  <div class="order-detail">
    <!-- 加载状态 -->
    <div v-if="loading" class="loading-container">
      <el-skeleton :rows="10" animated />
    </div>

    <!-- 订单详情内容 -->
    <div v-else class="detail-content">
      <!-- 订单基本信息 -->
      <el-card class="info-card">
        <template #header>
          <div class="card-header">
            <span class="card-title">订单基本信息</span>
            <el-tag :type="getStatusTag(orderData.status)" size="large">
              {{ getStatusText(orderData.status) }}
            </el-tag>
          </div>
        </template>
        
        <el-descriptions :column="2" border>
          <el-descriptions-item label="订单号">
            <span class="important-text">{{ orderData.orderNo }}</span>
          </el-descriptions-item>
          <el-descriptions-item label="订单金额">
            <span class="important-text">¥{{ orderData.amount?.toFixed(2) }}</span>
          </el-descriptions-item>
          <el-descriptions-item label="创建时间">
            {{ formatDateTime(orderData.createdAt) }}
          </el-descriptions-item>
          <el-descriptions-item label="支付时间">
            {{ formatDateTime(orderData.paidAt) || '未支付' }}
          </el-descriptions-item>
          <el-descriptions-item label="预约时间">
            {{ formatDateTime(orderData.appointmentTime) }}
          </el-descriptions-item>
          <el-descriptions-item label="服务时长">
            {{ orderData.serviceHours || 2 }} 小时
          </el-descriptions-item>
          <el-descriptions-item label="服务类型">
            <el-tag :type="getServiceTypeTag(orderData.serviceType)">
              {{ getServiceTypeText(orderData.serviceType) }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="支付方式">
            {{ getPaymentMethodText(orderData.paymentMethod) }}
          </el-descriptions-item>
        </el-descriptions>
      </el-card>

      <!-- 患者信息 -->
      <el-card class="info-card">
        <template #header>
          <div class="card-header">
            <span class="card-title">患者信息</span>
            <el-button
              v-if="canContactPatient"
              type="primary"
              size="small"
              @click="handleContactPatient"
            >
              <el-icon><ChatDotRound /></el-icon>
              联系患者
            </el-button>
          </div>
        </template>
        
        <el-descriptions :column="2" border>
          <el-descriptions-item label="患者姓名">
            {{ orderData.patientName }}
          </el-descriptions-item>
          <el-descriptions-item label="手机号码">
            {{ orderData.patientPhone }}
          </el-descriptions-item>
          <el-descriptions-item label="性别">
            {{ getGenderText(orderData.patientGender) }}
          </el-descriptions-item>
          <el-descriptions-item label="年龄">
            {{ orderData.patientAge || '未填写' }}
          </el-descriptions-item>
          <el-descriptions-item label="身份证号">
            {{ orderData.patientIdCard || '未填写' }}
          </el-descriptions-item>
          <el-descriptions-item label="紧急联系人">
            {{ orderData.emergencyContact || '未填写' }}
          </el-descriptions-item>
          <el-descriptions-item label="紧急联系电话">
            {{ orderData.emergencyPhone || '未填写' }}
          </el-descriptions-item>
          <el-descriptions-item label="健康状况">
            {{ orderData.healthCondition || '未填写' }}
          </el-descriptions-item>
        </el-descriptions>
      </el-card>

      <!-- 陪诊师信息 -->
      <el-card class="info-card">
        <template #header>
          <div class="card-header">
            <span class="card-title">陪诊师信息</span>
            <el-button
              v-if="canContactCompanion"
              type="primary"
              size="small"
              @click="handleContactCompanion"
            >
              <el-icon><ChatDotRound /></el-icon>
              联系陪诊师
            </el-button>
          </div>
        </template>
        
        <el-descriptions :column="2" border>
          <el-descriptions-item label="陪诊师姓名">
            {{ orderData.companionName }}
          </el-descriptions-item>
          <el-descriptions-item label="手机号码">
            {{ orderData.companionPhone }}
          </el-descriptions-item>
          <el-descriptions-item label="性别">
            {{ getGenderText(orderData.companionGender) }}
          </el-descriptions-item>
          <el-descriptions-item label="年龄">
            {{ orderData.companionAge || '未填写' }}
          </el-descriptions-item>
          <el-descriptions-item label="从业年限">
            {{ orderData.experienceYears || 0 }} 年
          </el-descriptions-item>
          <el-descriptions-item label="服务评分">
            <el-rate
              v-model="orderData.companionRating"
              disabled
              show-score
              text-color="#ff9900"
              score-template="{value}分"
            />
          </el-descriptions-item>
          <el-descriptions-item label="专长科室">
            {{ orderData.specialties?.join('、') || '未填写' }}
          </el-descriptions-item>
          <el-descriptions-item label="资格证书">
            {{ orderData.certificates?.join('、') || '无' }}
          </el-descriptions-item>
        </el-descriptions>
      </el-card>

      <!-- 医院信息 -->
      <el-card class="info-card">
        <template #header>
          <div class="card-header">
            <span class="card-title">医院信息</span>
            <el-button
              type="primary"
              size="small"
              @click="handleViewHospital"
            >
              <el-icon><Location /></el-icon>
              查看医院详情
            </el-button>
          </div>
        </template>
        
        <el-descriptions :column="2" border>
          <el-descriptions-item label="医院名称">
            {{ orderData.hospitalName }}
          </el-descriptions-item>
          <el-descriptions-item label="医院等级">
            {{ orderData.hospitalLevel || '未填写' }}
          </el-descriptions-item>
          <el-descriptions-item label="医院地址">
            {{ orderData.hospitalAddress }}
          </el-descriptions-item>
          <el-descriptions-item label="联系电话">
            {{ orderData.hospitalPhone || '未填写' }}
          </el-descriptions-item>
          <el-descriptions-item label="科室">
            {{ orderData.department || '未填写' }}
          </el-descriptions-item>
          <el-descriptions-item label="医生">
            {{ orderData.doctorName || '未填写' }}
          </el-descriptions-item>
          <el-descriptions-item label="就诊类型">
            {{ orderData.visitType || '未填写' }}
          </el-descriptions-item>
          <el-descriptions-item label="备注">
            {{ orderData.hospitalNotes || '无' }}
          </el-descriptions-item>
        </el-descriptions>
      </el-card>

      <!-- 服务详情 -->
      <el-card class="info-card">
        <template #header>
          <div class="card-header">
            <span class="card-title">服务详情</span>
          </div>
        </template>
        
        <div class="service-details">
          <div class="service-item" v-if="orderData.serviceItems">
            <h4>服务项目：</h4>
            <ul>
              <li v-for="(item, index) in orderData.serviceItems" :key="index">
                {{ item }}
              </li>
            </ul>
          </div>
          
          <div class="service-item" v-if="orderData.specialRequirements">
            <h4>特殊要求：</h4>
            <p>{{ orderData.specialRequirements }}</p>
          </div>
          
          <div class="service-item" v-if="orderData.notes">
            <h4>订单备注：</h4>
            <p>{{ orderData.notes }}</p>
          </div>
        </div>
      </el-card>

      <!-- 时间线 -->
      <el-card class="info-card">
        <template #header>
          <div class="card-header">
            <span class="card-title">订单时间线</span>
          </div>
        </template>
        
        <el-timeline>
          <el-timeline-item
            v-for="(event, index) in timelineEvents"
            :key="index"
            :timestamp="formatDateTime(event.timestamp)"
            :type="event.type"
            :size="event.size"
          >
            <div class="timeline-content">
              <strong>{{ event.title }}</strong>
              <p v-if="event.description">{{ event.description }}</p>
              <p v-if="event.operator" class="operator">操作人：{{ event.operator }}</p>
            </div>
          </el-timeline-item>
        </el-timeline>
      </el-card>

      <!-- 操作记录 -->
      <el-card class="info-card" v-if="operationLogs.length > 0">
        <template #header>
          <div class="card-header">
            <span class="card-title">操作记录</span>
          </div>
        </template>
        
        <el-table :data="operationLogs" border stripe>
          <el-table-column prop="operator" label="操作人" width="120" />
          <el-table-column prop="action" label="操作类型" width="120" />
          <el-table-column prop="description" label="操作描述" />
          <el-table-column prop="timestamp" label="操作时间" width="180">
            <template #default="{ row }">
              {{ formatDateTime(row.timestamp) }}
            </template>
          </el-table-column>
          <el-table-column prop="ip" label="IP地址" width="150" />
        </el-table>
      </el-card>
    </div>

    <!-- 底部操作栏 -->
    <div class="action-bar" v-if="!loading">
      <el-button @click="handleClose">关闭</el-button>
      <el-button
        type="primary"
        @click="handleEdit"
        :disabled="!canEdit"
      >
        编辑订单
      </el-button>
      <el-button
        type="warning"
        @click="handleChangeStatus"
        :disabled="!canChangeStatus"
      >
        变更状态
      </el-button>
      <el-button
        type="danger"
        @click="handleCancel"
        :disabled="!canCancel"
      >
        取消订单
      </el-button>
      <el-button
        type="success"
        @click="handlePrint"
      >
        打印订单
      </el-button>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { ChatDotRound, Location } from '@element-plus/icons-vue'

const props = defineProps({
  orderId: {
    type: String,
    required: true
  }
})

const emit = defineEmits(['close'])

// 响应式数据
const loading = ref(true)
const orderData = ref({})
const operationLogs = ref([])

// 状态映射
const statusMap = {
  pending_payment: { text: '待支付', type: 'warning' },
  waiting_accept: { text: '待接单', type: 'info' },
  in_progress: { text: '进行中', type: 'primary' },
  completed: { text: '已完成', type: 'success' },
  cancelled: { text: '已取消', type: 'danger' },
  refunded: { text: '已退款', type: 'info' }
}

const serviceTypeMap = {
  consultation: { text: '门诊陪诊', type: 'primary' },
  hospitalization: { text: '住院陪护', type: 'success' },
  examination: { text: '检查陪同', type: 'warning' },
  surgery: { text: '手术陪同', type: 'danger' }
}

const paymentMethodMap = {
  wechat: '微信支付',
  alipay: '支付宝',
  balance: '余额支付',
  cash: '现金支付'
}

const genderMap = {
  male: '男',
  female: '女',
  unknown: '未知'
}

// 计算属性
const timelineEvents = computed(() => {
  const events = []
  
  if (orderData.value.createdAt) {
    events.push({
      title: '订单创建',
      timestamp: orderData.value.createdAt,
      type: 'primary',
      size: 'large',
      operator: '系统'
    })
  }
  
  if (orderData.value.paidAt) {
    events.push({
      title: '支付成功',
      timestamp: orderData.value.paidAt,
      type: 'success',
      operator: orderData.value.patientName
    })
  }
  
  if (orderData.value.acceptedAt) {
    events.push({
      title: '陪诊师接单',
      timestamp: orderData.value.acceptedAt,
      type: 'success',
      operator: orderData.value.companionName
    })
  }
  
  if (orderData.value.startedAt) {
    events.push({
      title: '服务开始',
      timestamp: orderData.value.startedAt,
      type: 'primary',
      operator: orderData.value.companionName
    })
  }
  
  if (orderData.value.completedAt) {
    events.push({
      title: '服务完成',
      timestamp: orderData.value.completedAt,
      type: 'success',
      operator: orderData.value.companionName
    })
  }
  
  if (orderData.value.cancelledAt) {
    events.push({
      title: '订单取消',
      timestamp: orderData.value.cancelledAt,
      type: 'danger',
      operator: orderData.value.cancelledBy
    })
  }
  
  return events
})

const canEdit = computed(() => {
  return ['pending_payment', 'waiting_accept'].includes(orderData.value.status)
})

const canCancel = computed(() => {
  return ['pending_payment', 'waiting_accept', 'in_progress'].includes(orderData.value.status)
})

const canChangeStatus = computed(() => {
  return orderData.value.status !== 'cancelled' && orderData.value.status !== 'refunded'
})

const canContactPatient = computed(() => {
  return orderData.value.patientPhone && orderData.value.status !== 'cancelled'
})

const canContactCompanion = computed(() => {
  return orderData.value.companionPhone && orderData.value.status !== 'cancelled'
})

// 生命周期钩子
onMounted(() => {
  fetchOrderDetail()
})

// 获取订单详情
const fetchOrderDetail = async () => {
  loading.value = true
  try {
    // 模拟API调用
    await new Promise(resolve => setTimeout(resolve, 800))
    
    // 模拟数据
    orderData.value = {
      id: props.orderId,
      orderNo: props.orderId,
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
    }
    
    // 模拟操作记录
    operationLogs.value = [
      {
        operator: '管理员',
        action: '创建订单',
        description: '手动创建订单',
        timestamp: new Date(Date.now() - 86400000).toISOString(),
        ip: '192.168.1.100'
      },
      {
        operator: '张先生',
        action: '支付',
        description: '微信支付成功',
        timestamp: new Date(Date.now() - 86300000).toISOString(),
        ip: '192.168.1.101'
      },
      {
        operator: '王陪诊师',
        action: '接单',
        description: '接受订单',
        timestamp: new Date(Date.now() - 86200000).toISOString(),
        ip: '192.168.1.102'
      }
    ]
    
  } catch (error) {
    ElMessage.error('获取订单详情失败：' + error.message)
  } finally {
    loading.value = false
  }
}

// 事件处理
const handleClose = () => {
  emit('close')
}

const handleEdit = () => {
  ElMessage.info('编辑订单功能开发中...')
}

const handleChangeStatus = () => {
  ElMessage.info('变更状态功能开发中...')
}

const handleCancel = () => {
  ElMessage.info('取消订单功能开发中...')
}

const handlePrint = () => {
  ElMessage.success('打印功能已触发，请使用浏览器打印功能')
  window.print()
}

const handleContactPatient = () => {
  if (orderData.value.patientPhone) {
    ElMessage.info(`联系患者：${orderData.value.patientPhone}`)
    // 在实际应用中，这里可以跳转到聊天页面或拨打电话
  }
}

const handleContactCompanion = () => {
  if (orderData.value.companionPhone) {
    ElMessage.info(`联系陪诊师：${orderData.value.companionPhone}`)
    // 在实际应用中，这里可以跳转到聊天页面或拨打电话
  }
}

const handleViewHospital = () => {
  ElMessage.info('查看医院详情功能开发中...')
}

// 工具函数
const getStatusText = (status) => {
  return statusMap[status]?.text || status
}

const getStatusTag = (status) => {
  return statusMap[status]?.type || 'info'
}

const getServiceTypeText = (type) => {
  return serviceTypeMap[type]?.text || type
}

const getServiceTypeTag = (type) => {
  return serviceTypeMap[type]?.type || 'info'
}

const getPaymentMethodText = (method) => {
  return paymentMethodMap[method] || method
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
.order-detail {
  padding: 0;
}

.loading-container {
  padding: 40px;
}

.detail-content {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.info-card {
  margin-bottom: 0;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.card-title {
  font-size: 16px;
  font-weight: 600;
  color: #303133;
}

.important-text {
  font-weight: 600;
  color: #409eff;
}

.service-details {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.service-item h4 {
  margin: 0 0 8px 0;
  font-size: 14px;
  font-weight: 600;
  color: #303133;
}

.service-item ul {
  margin: 0;
  padding-left: 20px;
}

.service-item li {
  margin-bottom: 4px;
  color: #606266;
}

.service-item p {
  margin: 0;
  color: #606266;
  line-height: 1.6;
}

.timeline-content {
  line-height: 1.6;
}

.timeline-content strong {
  color: #303133;
}

.timeline-content p {
  margin: 4px 0;
  color: #606266;
}

.timeline-content .operator {
  font-size: 12px;
  color: #909399;
}

.action-bar {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  padding: 20px 0;
  border-top: 1px solid #ebeef5;
  margin-top: 20px;
}

:deep(.el-descriptions) {
  margin-top: 0;
}

:deep(.el-descriptions__title) {
  font-size: 14px;
}

:deep(.el-descriptions__label) {
  width: 120px;
  font-weight: 500;
}

:deep(.el-timeline) {
  padding-left: 10px;
}

:deep(.el-timeline-item__timestamp) {
  font-size: 13px;
  color: #909399;
}

@media print {
  .action-bar {
    display: none;
  }
  
  .info-card {
    break-inside: avoid;
  }
}
</style>