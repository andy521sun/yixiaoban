<template>
  <div class="orders-container">
    <!-- 页面标题和操作栏 -->
    <div class="page-header">
      <h1>订单管理</h1>
      <div class="header-actions">
        <el-button type="primary" @click="handleCreateOrder">
          <el-icon><Plus /></el-icon>
          新建订单
        </el-button>
        <el-button @click="refreshData">
          <el-icon><Refresh /></el-icon>
          刷新
        </el-button>
      </div>
    </div>

    <!-- 筛选条件 -->
    <div class="filter-container">
      <el-form :inline="true" :model="filterForm">
        <el-form-item label="订单号">
          <el-input
            v-model="filterForm.orderNo"
            placeholder="请输入订单号"
            clearable
            style="width: 200px"
          />
        </el-form-item>
        
        <el-form-item label="患者姓名">
          <el-input
            v-model="filterForm.patientName"
            placeholder="请输入患者姓名"
            clearable
            style="width: 200px"
          />
        </el-form-item>
        
        <el-form-item label="陪诊师">
          <el-input
            v-model="filterForm.companionName"
            placeholder="请输入陪诊师姓名"
            clearable
            style="width: 200px"
          />
        </el-form-item>
        
        <el-form-item label="订单状态">
          <el-select
            v-model="filterForm.status"
            placeholder="请选择状态"
            clearable
            style="width: 150px"
          >
            <el-option label="待支付" value="pending_payment" />
            <el-option label="待接单" value="waiting_accept" />
            <el-option label="进行中" value="in_progress" />
            <el-option label="已完成" value="completed" />
            <el-option label="已取消" value="cancelled" />
            <el-option label="已退款" value="refunded" />
          </el-select>
        </el-form-item>
        
        <el-form-item label="创建时间">
          <el-date-picker
            v-model="filterForm.dateRange"
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

    <!-- 订单表格 -->
    <div class="table-container">
      <el-table
        :data="orderList"
        v-loading="loading"
        border
        stripe
        style="width: 100%"
      >
        <el-table-column prop="orderNo" label="订单号" width="180" />
        <el-table-column prop="patientName" label="患者" width="120">
          <template #default="{ row }">
            <div class="patient-info">
              <div class="name">{{ row.patientName }}</div>
              <div class="phone">{{ row.patientPhone }}</div>
            </div>
          </template>
        </el-table-column>
        <el-table-column prop="companionName" label="陪诊师" width="120">
          <template #default="{ row }">
            <div class="companion-info">
              <div class="name">{{ row.companionName }}</div>
              <div class="phone">{{ row.companionPhone }}</div>
            </div>
          </template>
        </el-table-column>
        <el-table-column prop="hospitalName" label="医院" width="200" />
        <el-table-column prop="serviceType" label="服务类型" width="100">
          <template #default="{ row }">
            <el-tag :type="getServiceTypeTag(row.serviceType)">
              {{ getServiceTypeText(row.serviceType) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="amount" label="金额" width="100" align="right">
          <template #default="{ row }">
            ¥{{ row.amount.toFixed(2) }}
          </template>
        </el-table-column>
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="getStatusTag(row.status)">
              {{ getStatusText(row.status) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="createdAt" label="创建时间" width="180">
          <template #default="{ row }">
            {{ formatDateTime(row.createdAt) }}
          </template>
        </el-table-column>
        <el-table-column prop="appointmentTime" label="预约时间" width="180">
          <template #default="{ row }">
            {{ formatDateTime(row.appointmentTime) }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200" fixed="right">
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
              @click="handleEditOrder(row)"
              :disabled="!canEdit(row)"
            >
              编辑
            </el-button>
            <el-button
              size="small"
              type="danger"
              @click="handleCancelOrder(row)"
              :disabled="!canCancel(row)"
            >
              取消
            </el-button>
          </template>
        </el-table-column>
      </el-table>
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

    <!-- 订单详情对话框 -->
    <el-dialog
      v-model="detailDialogVisible"
      title="订单详情"
      width="800px"
      :close-on-click-modal="false"
    >
      <order-detail
        v-if="detailDialogVisible"
        :order-id="currentOrderId"
        @close="detailDialogVisible = false"
      />
    </el-dialog>

    <!-- 创建/编辑订单对话框 -->
    <el-dialog
      v-model="editDialogVisible"
      :title="isEditMode ? '编辑订单' : '新建订单'"
      width="600px"
      :close-on-click-modal="false"
    >
      <order-edit-form
        v-if="editDialogVisible"
        :order-data="currentOrderData"
        :is-edit="isEditMode"
        @success="handleEditSuccess"
        @cancel="editDialogVisible = false"
      />
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Refresh, Search } from '@element-plus/icons-vue'
import OrderDetail from '../components/OrderDetail.vue'
import OrderEditForm from '../components/OrderEditForm.vue'

// 响应式数据
const loading = ref(false)
const orderList = ref([])
const detailDialogVisible = ref(false)
const editDialogVisible = ref(false)
const currentOrderId = ref('')
const currentOrderData = ref({})
const isEditMode = ref(false)

// 筛选表单
const filterForm = reactive({
  orderNo: '',
  patientName: '',
  companionName: '',
  status: '',
  dateRange: []
})

// 分页配置
const pagination = reactive({
  currentPage: 1,
  pageSize: 20,
  total: 0
})

// 状态映射
const statusMap = {
  pending_payment: { text: '待支付', type: 'warning' },
  waiting_accept: { text: '待接单', type: 'info' },
  in_progress: { text: '进行中', type: 'primary' },
  completed: { text: '已完成', type: 'success' },
  cancelled: { text: '已取消', type: 'danger' },
  refunded: { text: '已退款', type: 'info' }
}

// 服务类型映射
const serviceTypeMap = {
  consultation: { text: '门诊陪诊', type: 'primary' },
  hospitalization: { text: '住院陪护', type: 'success' },
  examination: { text: '检查陪同', type: 'warning' },
  surgery: { text: '手术陪同', type: 'danger' }
}

// 生命周期钩子
onMounted(() => {
  fetchOrderList()
})

// 获取订单列表
const fetchOrderList = async () => {
  loading.value = true
  try {
    // 模拟API调用
    await new Promise(resolve => setTimeout(resolve, 500))
    
    // 模拟数据
    orderList.value = Array.from({ length: 50 }, (_, index) => ({
      id: `ORD${String(index + 1).padStart(6, '0')}`,
      orderNo: `ORD${String(index + 1).padStart(6, '0')}`,
      patientName: `患者${index + 1}`,
      patientPhone: `138${String(index + 1).padStart(8, '0')}`,
      companionName: `陪诊师${index + 1}`,
      companionPhone: `139${String(index + 1).padStart(8, '0')}`,
      hospitalName: `第${(index % 5) + 1}人民医院`,
      serviceType: Object.keys(serviceTypeMap)[index % 4],
      amount: 100 + (index % 10) * 50,
      status: Object.keys(statusMap)[index % 6],
      createdAt: new Date(Date.now() - index * 3600000).toISOString(),
      appointmentTime: new Date(Date.now() + (index + 1) * 86400000).toISOString()
    }))
    
    pagination.total = orderList.value.length
  } catch (error) {
    ElMessage.error('获取订单列表失败：' + error.message)
  } finally {
    loading.value = false
  }
}

// 搜索处理
const handleSearch = () => {
  pagination.currentPage = 1
  fetchOrderList()
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
  fetchOrderList()
}

// 刷新数据
const refreshData = () => {
  fetchOrderList()
}

// 查看详情
const handleViewDetail = (row) => {
  currentOrderId.value = row.id
  detailDialogVisible.value = true
}

// 创建订单
const handleCreateOrder = () => {
  isEditMode.value = false
  currentOrderData.value = {}
  editDialogVisible.value = true
}

// 编辑订单
const handleEditOrder = (row) => {
  isEditMode.value = true
  currentOrderData.value = { ...row }
  editDialogVisible.value = true
}

// 取消订单
const handleCancelOrder = (row) => {
  ElMessageBox.confirm(
    `确定要取消订单 ${row.orderNo} 吗？`,
    '取消订单确认',
    {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    }
  ).then(async () => {
    try {
      // 模拟API调用
      await new Promise(resolve => setTimeout(resolve, 300))
      ElMessage.success('订单取消成功')
      fetchOrderList()
    } catch (error) {
      ElMessage.error('取消订单失败：' + error.message)
    }
  }).catch(() => {
    // 用户取消操作
  })
}

// 编辑成功处理
const handleEditSuccess = () => {
  editDialogVisible.value = false
  fetchOrderList()
}

// 分页处理
const handleSizeChange = (size) => {
  pagination.pageSize = size
  fetchOrderList()
}

const handleCurrentChange = (page) => {
  pagination.currentPage = page
  fetchOrderList()
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

const formatDateTime = (dateString) => {
  if (!dateString) return ''
  const date = new Date(dateString)
  return date.toLocaleString('zh-CN')
}

const canEdit = (row) => {
  return ['pending_payment', 'waiting_accept'].includes(row.status)
}

const canCancel = (row) => {
  return ['pending_payment', 'waiting_accept', 'in_progress'].includes(row.status)
}
</script>

<style scoped>
.orders-container {
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

.pagination-container {
  display: flex;
  justify-content: flex-end;
  background-color: #fff;
  padding: 20px;
  border-radius: 4px;
  box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.1);
}

.patient-info,
.companion-info {
  line-height: 1.4;
}

.patient-info .name,
.companion-info .name {
  font-weight: 500;
  color: #303133;
}

.patient-info .phone,
.companion-info .phone {
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
</style>