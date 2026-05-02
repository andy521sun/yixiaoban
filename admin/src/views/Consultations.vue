<template>
  <div class="consultations">
    <!-- 统计 -->
    <el-row :gutter="16" style="margin-bottom:16px">
      <el-col :span="4" v-for="s in statItems" :key="s.label">
        <el-card shadow="hover" :body-style="{padding:'14px'}">
          <div class="stat-item">
            <div class="stat-value">{{ s.value }}</div>
            <div class="stat-label">{{ s.label }}</div>
          </div>
        </el-card>
      </el-col>
    </el-row>
    <el-card>
      <template #header>
        <div class="card-header">
          <span>问诊管理</span>
          <div class="header-actions">
            <el-select v-model="filterStatus" placeholder="状态" @change="loadData" style="width:130px;margin-right:12px">
              <el-option label="全部" value="" />
              <el-option label="待接诊" value="pending" />
              <el-option label="进行中" value="active" />
              <el-option label="已完成" value="completed" />
              <el-option label="已取消" value="cancelled" />
            </el-select>
            <el-button type="primary" @click="loadData" :icon="Refresh">刷新</el-button>
          </div>
        </div>
      </template>
      <el-table :data="list" v-loading="loading" stripe style="width:100%">
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="patient_name" label="患者" width="110" />
        <el-table-column prop="doctor_name" label="医生" width="110" />
        <el-table-column prop="type" label="类型" width="80">
          <template #default="{row}">{{ {text:'图文',phone:'电话',video:'视频'}[row.type] || row.type }}</template>
        </el-table-column>
        <el-table-column prop="main_complaint" label="主诉" min-width="200" show-overflow-tooltip />
        <el-table-column label="状态" width="90">
          <template #default="{row}"><el-tag :type="statusType(row.status)" size="small">{{ statusLabel(row.status) }}</el-tag></template>
        </el-table-column>
        <el-table-column label="创建时间" width="160"><template #default="{row}">{{ row.created_at?.substring(0,16) }}</template></el-table-column>
        <el-table-column label="操作" width="120" fixed="right">
          <template #default="{row}">
            <el-button size="small" @click="showDetail(row)">详情</el-button>
          </template>
        </el-table-column>
      </el-table>
      <div class="pagination-wrap" v-if="total>0">
        <el-pagination v-model:current-page="page" :page-size="pageSize" :total="total" layout="total,prev,pager,next" @current-change="loadData" />
      </div>
    </el-card>

    <el-dialog v-model="detailVisible" title="问诊详情" width="700px">
      <template v-if="currentRow">
        <el-descriptions :column="2" border>
          <el-descriptions-item label="患者">{{ currentRow.patient_name }}</el-descriptions-item>
          <el-descriptions-item label="医生">{{ currentRow.doctor_name }}</el-descriptions-item>
          <el-descriptions-item label="类型">{{ {text:'图文',phone:'电话',video:'视频'}[currentRow.type] }}</el-descriptions-item>
          <el-descriptions-item label="状态"><el-tag :type="statusType(currentRow.status)" size="small">{{ statusLabel(currentRow.status) }}</el-tag></el-descriptions-item>
          <el-descriptions-item label="主诉" :span="2">{{ currentRow.main_complaint }}</el-descriptions-item>
          <el-descriptions-item label="现病史" :span="2" v-if="currentRow.present_illness">{{ currentRow.present_illness }}</el-descriptions-item>
          <el-descriptions-item label="既往史" :span="2" v-if="currentRow.past_history">{{ currentRow.past_history }}</el-descriptions-item>
          <el-descriptions-item label="诊断" :span="2" v-if="currentRow.diagnosis">{{ currentRow.diagnosis }}</el-descriptions-item>
          <el-descriptions-item label="评价" :span="2" v-if="currentRow.rating">评分: {{ currentRow.rating }}/5</el-descriptions-item>
          <el-descriptions-item label="创建时间" :span="2">{{ currentRow.created_at }}</el-descriptions-item>
        </el-descriptions>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import api from '../api/index.js'

const loading = ref(false)
const list = ref([])
const total = ref(0)
const page = ref(1)
const pageSize = ref(20)
const filterStatus = ref('')
const detailVisible = ref(false)
const currentRow = ref(null)
const stats = ref({})

const statItems = computed(() => [
  { label: '总问诊', value: stats.value.total_consultations || 0 },
  { label: '待接诊', value: stats.value.pending || 0 },
  { label: '进行中', value: stats.value.active || 0 },
  { label: '已完成', value: stats.value.completed || 0 },
  { label: '已取消', value: stats.value.cancelled || 0 },
  { label: '医生数', value: stats.value.total_doctors || 0 },
])

async function loadData() {
  loading.value = true
  try {
    const [statsRes, listRes] = await Promise.all([
      api.get('/admin/consultations/stats'),
      api.get('/admin/consultations', {
        page: page.value,
        page_size: pageSize.value,
        ...(filterStatus.value ? { status: filterStatus.value } : {})
      })
    ])
    stats.value = statsRes.data?.stats || {}
    list.value = listRes.data || []
    total.value = listRes.pagination?.total || 0
  } catch (e) { console.error(e) }
  loading.value = false
}

function showDetail(row) {
  currentRow.value = row
  detailVisible.value = true
}

function statusType(status) {
  switch (status) {
    case 'pending': return 'warning'
    case 'active': case 'in_progress': return 'primary'
    case 'completed': return 'success'
    case 'cancelled': return 'info'
    case 'rated': return 'success'
    default: return ''
  }
}

function statusLabel(status) {
  switch (status) {
    case 'pending': return '待接诊'
    case 'active': case 'in_progress': return '进行中'
    case 'completed': case 'rated': return '已完成'
    case 'cancelled': return '已取消'
    default: return status
  }
}

onMounted(() => loadData())
</script>

<style scoped>
.card-header { display: flex; justify-content: space-between; align-items: center; }
.header-actions { display: flex; align-items: center; }
.stat-item { text-align: center; }
.stat-value { font-size: 22px; font-weight: bold; color: #1A73E8; }
.stat-label { font-size: 12px; color: #999; margin-top: 4px; }
.pagination-wrap { margin-top: 20px; display: flex; justify-content: flex-end; }
</style>
