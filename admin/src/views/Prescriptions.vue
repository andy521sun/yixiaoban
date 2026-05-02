<template>
  <div class="prescriptions">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>处方管理</span>
          <div class="header-actions">
            <el-button type="primary" @click="loadData" :icon="Refresh">刷新</el-button>
          </div>
        </div>
      </template>
      <el-table :data="list" v-loading="loading" stripe style="width:100%">
        <el-table-column prop="prescription_no" label="处方编号" width="160" />
        <el-table-column prop="doctor_name" label="医生" width="110" />
        <el-table-column prop="patient_name" label="患者" width="110" />
        <el-table-column prop="diagnosis" label="诊断" min-width="180" show-overflow-tooltip />
        <el-table-column label="药品数" width="80">
          <template #default="{row}">{{ row.items?.length || 0 }}项</template>
        </el-table-column>
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

    <el-dialog v-model="detailVisible" title="处方详情" width="600px">
      <template v-if="currentRow">
        <el-descriptions :column="2" border style="margin-bottom:16px">
          <el-descriptions-item label="处方编号" :span="2">{{ currentRow.prescription_no || currentRow.id }}</el-descriptions-item>
          <el-descriptions-item label="医生">{{ currentRow.doctor_name }}</el-descriptions-item>
          <el-descriptions-item label="患者">{{ currentRow.patient_name }}</el-descriptions-item>
          <el-descriptions-item label="诊断" :span="2">{{ currentRow.diagnosis }}</el-descriptions-item>
          <el-descriptions-item label="状态" :span="2">
            <el-tag :type="statusType(currentRow.status)" size="small">{{ statusLabel(currentRow.status) }}</el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="医嘱" v-if="currentRow.notes" :span="2">{{ currentRow.notes }}</el-descriptions-item>
        </el-descriptions>
        <el-table :data="currentRow.items || []" border size="small" style="width:100%">
          <el-table-column type="index" label="#" width="40" />
          <el-table-column prop="drug_name" label="药品名称" min-width="140" />
          <el-table-column prop="specification" label="规格" width="120" />
          <el-table-column prop="dosage" label="用量" width="80" />
          <el-table-column prop="frequency" label="频次" width="80" />
          <el-table-column prop="duration_days" label="天数" width="60" />
          <el-table-column prop="total_quantity" label="数量" width="60" />
        </el-table>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import api from '../api/index.js'

const loading = ref(false)
const list = ref([])
const total = ref(0)
const page = ref(1)
const pageSize = ref(20)
const detailVisible = ref(false)
const currentRow = ref(null)

async function loadData() {
  loading.value = true
  try {
    const res = await api.get('/admin/prescriptions', { page: page.value, page_size: pageSize.value })
    list.value = res.data || []
    total.value = res.pagination?.total || 0
  } catch (e) { console.error(e) }
  loading.value = false
}

async function showDetail(row) {
  try {
    const res = await api.get(`/admin/prescriptions/${row.id}`)
    currentRow.value = res.data || row
  } catch (_) { currentRow.value = row }
  detailVisible.value = true
}

function statusType(status) {
  switch (status) {
    case 'active': return 'success'
    case 'dispensed': return 'primary'
    case 'cancelled': return 'info'
    default: return ''
  }
}

function statusLabel(status) {
  switch (status) {
    case 'active': return '有效'
    case 'dispensed': return '已取药'
    case 'cancelled': return '已作废'
    default: return status
  }
}

onMounted(() => loadData())
</script>

<style scoped>
.card-header { display: flex; justify-content: space-between; align-items: center; }
.header-actions { display: flex; align-items: center; }
.pagination-wrap { margin-top: 20px; display: flex; justify-content: flex-end; }
</style>
