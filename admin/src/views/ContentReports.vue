<template>
  <div class="content-reports">
    <el-row :gutter="16" style="margin-bottom:16px">
      <el-col :span="6" v-for="s in statItems" :key="s.label">
        <el-card shadow="hover" :body-style="{padding:'14px'}">
          <div class="stat-item">
            <div class="stat-value" :style="{color:s.color}">{{ s.value }}</div>
            <div class="stat-label">{{ s.label }}</div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <el-card>
      <template #header>
        <div class="card-header">
          <span>内容举报列表</span>
          <div class="header-actions">
            <el-select v-model="filterStatus" placeholder="状态" @change="loadData" style="width:130px;margin-right:12px">
              <el-option label="全部" value="" />
              <el-option label="待审核" value="pending" />
              <el-option label="已处理" value="resolved" />
              <el-option label="已驳回" value="dismissed" />
            </el-select>
            <el-button type="primary" @click="loadData" :icon="Refresh">刷新</el-button>
          </div>
        </div>
      </template>
      <el-table :data="list" v-loading="loading" stripe style="width:100%">
        <el-table-column prop="id" label="ID" width="60" />
        <el-table-column prop="reporter_name" label="举报人" width="100" />
        <el-table-column label="类型" width="80">
          <template #default="{row}">{{ typeLabel(row.target_type) }}</template>
        </el-table-column>
        <el-table-column label="举报原因" width="120">
          <template #default="{row}">{{ reasonLabel(row.reason) }}</template>
        </el-table-column>
        <el-table-column label="描述" min-width="200" show-overflow-tooltip>
          <template #default="{row}">{{ row.description || row.content_preview || '-' }}</template>
        </el-table-column>
        <el-table-column label="状态" width="90">
          <template #default="{row}">
            <el-tag :type="row.status==='pending'?'warning':row.status==='resolved'?'danger':'info'" size="small">
              {{ {pending:'待审核',resolved:'已处理',dismissed:'已驳回'}[row.status]||row.status }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="举报时间" width="150">
          <template #default="{row}">{{ row.created_at?.substring(0,16) }}</template>
        </el-table-column>
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="{row}">
            <el-button size="small" type="primary" @click="showDetail(row)" v-if="row.status==='pending'">审核</el-button>
            <el-button size="small" @click="showDetail(row)" v-else>详情</el-button>
          </template>
        </el-table-column>
      </el-table>
      <div class="pagination-wrap" v-if="total>0">
        <el-pagination v-model:current-page="page" :page-size="pageSize" :total="total" layout="total,prev,pager,next" @current-change="loadData" />
      </div>
    </el-card>

    <el-dialog v-model="detailVisible" :title="currentRow?'举报详情':''" width="600px">
      <template v-if="currentRow">
        <el-descriptions :column="2" border>
          <el-descriptions-item label="举报人">{{ currentRow.reporter_name }}</el-descriptions-item>
          <el-descriptions-item label="类型">{{ typeLabel(currentRow.target_type) }}</el-descriptions-item>
          <el-descriptions-item label="原因">{{ reasonLabel(currentRow.reason) }}</el-descriptions-item>
          <el-descriptions-item label="状态">
            <el-tag :type="currentRow.status==='pending'?'warning':currentRow.status==='resolved'?'danger':'info'" size="small">
              {{ {pending:'待审核',resolved:'已处理',dismissed:'已驳回'}[currentRow.status]||currentRow.status }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="目标ID">{{ currentRow.target_id }}</el-descriptions-item>
          <el-descriptions-item label="举报时间">{{ currentRow.created_at }}</el-descriptions-item>
        </el-descriptions>
        <div style="margin-top:12px">
          <label style="font-weight:600;font-size:14px">举报描述</label>
          <p style="margin-top:8px;color:#666;background:#f5f7fa;padding:12px;border-radius:8px">
            {{ currentRow.description || '无详细描述' }}
          </p>
        </div>
        <div v-if="currentRow.content_preview" style="margin-top:12px">
          <label style="font-weight:600;font-size:14px">违规内容预览</label>
          <p style="margin-top:8px;color:#666;background:#fff3e0;padding:12px;border-radius:8px">
            {{ currentRow.content_preview }}
          </p>
        </div>
        <div style="margin-top:16px" v-if="currentRow.status==='pending'">
          <label style="font-weight:600;font-size:14px">审核意见</label>
          <el-input v-model="reviewNote" type="textarea" :rows="3" placeholder="输入审核意见（可选）" style="margin-top:8px" />
          <div style="margin-top:16px;display:flex;gap:12px;justify-content:flex-end">
            <el-button @click="handleReview('dismissed')" type="info">驳回</el-button>
            <el-button @click="handleReview('resolved')" type="danger">确认违规并屏蔽</el-button>
          </div>
        </div>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { Refresh } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'
import api from '../api/index.js'

const list = ref([])
const loading = ref(false)
const total = ref(0)
const page = ref(1)
const pageSize = ref(20)
const filterStatus = ref('')
const detailVisible = ref(false)
const currentRow = ref(null)
const reviewNote = ref('')
const statItems = ref([
  { label: '待审核', value: 0, color: '#E6A23C' },
  { label: '已处理', value: 0, color: '#F56C6C' },
  { label: '已驳回', value: 0, color: '#909399' },
  { label: '总计', value: 0, color: '#1A73E8' },
])

function typeLabel(type) {
  return { consultation: '问诊', message: '消息', review: '评价' }[type] || type
}
function reasonLabel(reason) {
  return { spam: '垃圾广告', harassment: '人身攻击', medical_misinfo: '医疗误导', porn: '色情', illegal: '违法违规', other: '其他' }[reason] || reason
}

async function loadStats() {
  const res = await api.get('/content/reports/stats')
  if (res?.success) {
    const s = res.data
    statItems.value = [
      { label: '待审核', value: s.pending || 0, color: '#E6A23C' },
      { label: '已处理', value: s.resolved || 0, color: '#F56C6C' },
      { label: '已驳回', value: s.dismissed || 0, color: '#909399' },
      { label: '总计', value: s.total || 0, color: '#1A73E8' },
    ]
  }
}

async function loadData() {
  loading.value = true
  try {
    const params = { page: page.value, pageSize: pageSize.value }
    if (filterStatus.value) params.status = filterStatus.value
    const res = await api.get('/content/reports', params)
    if (res?.success) {
      list.value = res.data || []
      total.value = res.total || 0
    }
  } catch (e) {
    console.error('加载失败', e)
  }
  loading.value = false
}

function showDetail(row) {
  currentRow.value = row
  detailVisible.value = true
  reviewNote.value = ''
}

async function handleReview(action) {
  if (!currentRow.value) return
  try {
    await api.post(`/content/reports/${currentRow.value.id}/review`, { action, note: reviewNote.value })
    ElMessage.success(action === 'resolved' ? '已确认违规' : '已驳回')
    detailVisible.value = false
    loadData()
    loadStats()
  } catch (e) {
    ElMessage.error('操作失败')
  }
}

onMounted(() => { loadData(); loadStats() })
</script>

<style scoped>
.card-header { display: flex; justify-content: space-between; align-items: center; }
.header-actions { display: flex; align-items: center; }
.stat-item { text-align: center; }
.stat-value { font-size: 22px; font-weight: bold; }
.stat-label { font-size: 12px; color: #999; margin-top: 4px; }
.pagination-wrap { margin-top: 20px; display: flex; justify-content: flex-end; }
</style>
