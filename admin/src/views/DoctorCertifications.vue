<template>
  <div class="doctor-certifications">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>医生认证审核</span>
          <div class="header-actions">
            <el-select v-model="filterStatus" placeholder="筛选状态" @change="loadData" style="width:140px;margin-right:12px">
              <el-option label="全部" value="" />
              <el-option label="待审核" value="pending" />
              <el-option label="已通过" value="approved" />
              <el-option label="已驳回" value="rejected" />
            </el-select>
            <el-button type="primary" @click="loadData" :icon="Refresh">刷新</el-button>
          </div>
        </div>
      </template>
      <el-table :data="list" v-loading="loading" stripe style="width:100%">
        <el-table-column prop="real_name" label="姓名" width="100" />
        <el-table-column prop="title" label="职称" width="120" />
        <el-table-column prop="department" label="科室" width="120" />
        <el-table-column prop="hospital_affiliation" label="所属医院" min-width="220" show-overflow-tooltip />
        <el-table-column label="状态" width="100">
          <template #default="{row}">
            <el-tag :type="statusType(row.status)" size="small">{{ statusLabel(row.status) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="提交时间" width="170">
          <template #default="{row}">{{ row.created_at?.substring(0,16) }}</template>
        </el-table-column>
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="{row}">
            <el-button size="small" @click="showDetail(row)">详情</el-button>
            <el-button size="small" type="success" @click="review(row,'approved')" v-if="row.status==='pending'" :loading="reviewingId===row.id">通过</el-button>
            <el-button size="small" type="danger" @click="review(row,'rejected')" v-if="row.status==='pending'" :loading="reviewingId===row.id">驳回</el-button>
          </template>
        </el-table-column>
      </el-table>
      <div class="pagination-wrap" v-if="total>0">
        <el-pagination
          v-model:current-page="page"
          :page-size="pageSize"
          :total="total"
          layout="total,prev,pager,next"
          @current-change="loadData"
        />
      </div>
    </el-card>

    <!-- 详情对话框 -->
    <el-dialog v-model="detailVisible" title="认证详情" width="600px">
      <template v-if="currentRow">
        <el-descriptions :column="2" border>
          <el-descriptions-item label="姓名">{{ currentRow.real_name }}</el-descriptions-item>
          <el-descriptions-item label="职称">{{ currentRow.title }}</el-descriptions-item>
          <el-descriptions-item label="科室">{{ currentRow.department }}</el-descriptions-item>
          <el-descriptions-item label="所属医院">{{ currentRow.hospital_affiliation }}</el-descriptions-item>
          <el-descriptions-item label="执业证号" :span="2">{{ currentRow.license_number || '未提交' }}</el-descriptions-item>
          <el-descriptions-item label="个人简介" :span="2">{{ currentRow.introduction || '暂无' }}</el-descriptions-item>
          <el-descriptions-item label="提交时间" :span="2">{{ currentRow.created_at }}</el-descriptions-item>
          <el-descriptions-item label="审核状态" :span="2">
            <el-tag :type="statusType(currentRow.status)">{{ statusLabel(currentRow.status) }}</el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="审核备注" :span="2" v-if="currentRow.review_remark">{{ currentRow.review_remark }}</el-descriptions-item>
        </el-descriptions>
      </template>
      <template #footer>
        <el-button @click="detailVisible=false">关闭</el-button>
        <el-button type="success" @click="review(currentRow,'approved')" v-if="currentRow?.status==='pending'">审核通过</el-button>
        <el-button type="danger" @click="review(currentRow,'rejected')" v-if="currentRow?.status==='pending'">驳回</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import api from '../api/index.js'

const loading = ref(false)
const list = ref([])
const total = ref(0)
const page = ref(1)
const pageSize = ref(20)
const filterStatus = ref('')
const reviewingId = ref(null)
const detailVisible = ref(false)
const currentRow = ref(null)

// Token（从 localStorage 获取）
function getToken() {
  return localStorage.getItem('admin_token') || ''
}

async function loadData() {
  loading.value = true
  try {
    const res = await api.get('/admin/doctors/certifications', {
      page: page.value,
      page_size: pageSize.value,
      ...(filterStatus.value ? { status: filterStatus.value } : {})
    })
    if (res.success) {
      list.value = res.data || []
      total.value = res.pagination?.total || 0
    } else {
      // fallback to mock
      list.value = res.data || []
    }
  } catch (e) {
    console.error(e)
  }
  loading.value = false
}

function showDetail(row) {
  currentRow.value = row
  detailVisible.value = true
}

async function review(row, action) {
  if (action === 'rejected') {
    try {
      const { value } = await ElMessageBox.prompt('请输入驳回原因', '驳回认证', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        inputType: 'textarea',
      })
      await doReview(row, action, value)
    } catch (_) {}
  } else {
    await doReview(row, action)
  }
}

async function doReview(row, action, remark) {
  reviewingId.value = row.id
  try {
    const res = await api.post(`/admin/doctors/certifications/${row.id}/review`, {
      action,
      ...(remark ? { admin_remark: remark } : {})
    })
    if (res.success) {
      ElMessage.success(action === 'approved' ? '审核通过' : '已驳回')
      detailVisible.value = false
      loadData()
    } else {
      ElMessage.error(res.message || '操作失败')
    }
  } catch (e) {
    ElMessage.error('网络错误')
  }
  reviewingId.value = null
}

function statusType(status) {
  switch (status) {
    case 'approved': return 'success'
    case 'rejected': return 'danger'
    default: return 'warning'
  }
}

function statusLabel(status) {
  switch (status) {
    case 'approved': return '已通过'
    case 'rejected': return '已驳回'
    default: return '待审核'
  }
}

onMounted(() => loadData())
</script>

<style scoped>
.card-header {
  display: flex; justify-content: space-between; align-items: center;
}
.header-actions { display: flex; align-items: center; }
.pagination-wrap { margin-top: 20px; display: flex; justify-content: flex-end; }
</style>
