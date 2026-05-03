<template>
  <div class="companions-page">
    <el-row :gutter="12" style="margin-bottom:16px">
      <el-col :span="6" v-for="s in stats" :key="s.label">
        <el-card shadow="hover" :body-style="{padding:'12px'}">
          <div class="stat-item">
            <div class="stat-value" :style="{color:s.color}">{{ s.value }}</div>
            <div class="stat-label">{{ s.label }}</div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <el-card>
      <template #header>
        <div class="header">
          <span>陪诊师管理</span>
          <div class="actions">
            <el-select v-model="filterCertified" placeholder="认证状态" @change="loadData" style="width:130px;margin-right:8px">
              <el-option label="全部" value="" />
              <el-option label="已认证" value="1" />
              <el-option label="未认证" value="0" />
            </el-select>
            <el-input v-model="searchText" placeholder="搜索姓名/手机号" clearable @keyup.enter="loadData" style="width:200px;margin-right:8px" />
            <el-button type="primary" @click="loadData" :icon="Search">搜索</el-button>
            <el-button @click="resetFilter">重置</el-button>
          </div>
        </div>
      </template>
      <el-table :data="list" v-loading="loading" stripe style="width:100%">
        <el-table-column label="姓名" width="90"><template #default="{row}">{{ row.real_name || row.name || '-' }}</template></el-table-column>
        <el-table-column label="手机号" width="130"><template #default="{row}">{{ row.phone || '-' }}</template></el-table-column>
        <el-table-column label="从业年限" width="80"><template #default="{row}">{{ row.experience_years }}年</template></el-table-column>
        <el-table-column label="每小时收费" width="100"><template #default="{row}">¥{{ row.hourly_rate }}</template></el-table-column>
        <el-table-column label="服务次数" width="80"><template #default="{row}">{{ row.service_count }}次</template></el-table-column>
        <el-table-column label="评分" width="80"><template #default="{row}">{{ row.average_rating }}分</template></el-table-column>
        <el-table-column label="认证" width="80">
          <template #default="{row}">
            <el-tag :type="row.is_certified ? 'success' : 'warning'" size="small">
              {{ row.is_certified ? '已认证' : '未认证' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="接单" width="70">
          <template #default="{row}">
            <el-tag :type="row.is_available ? 'success' : 'info'" size="small">
              {{ row.is_available ? '在线' : '离线' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="160" fixed="right">
          <template #default="{row}">
            <el-button size="small" @click="showDetail(row)">详情</el-button>
            <el-button v-if="!row.is_certified" size="small" type="success" @click="approveCertify(row)" :loading="certifyingId===row.id">通过</el-button>
            <el-popconfirm v-else title="取消认证?" @confirm="rejectCertify(row)">
              <template #reference>
                <el-button size="small" type="danger">取消</el-button>
              </template>
            </el-popconfirm>
          </template>
        </el-table-column>
      </el-table>
      <div class="pagination-wrap" v-if="total>0">
        <el-pagination v-model:current-page="page" :page-size="pageSize" :total="total" layout="total,prev,pager,next" @current-change="loadData" />
      </div>
    </el-card>

    <el-dialog v-model="detailVisible" title="陪诊师详情" width="600px">
      <template v-if="currentRow">
        <el-descriptions :column="2" border>
          <el-descriptions-item label="姓名">{{ currentRow.real_name || currentRow.name }}</el-descriptions-item>
          <el-descriptions-item label="手机号">{{ currentRow.phone }}</el-descriptions-item>
          <el-descriptions-item label="身份证号">{{ currentRow.id_card || '-' }}</el-descriptions-item>
          <el-descriptions-item label="从业年限">{{ currentRow.experience_years }}年</el-descriptions-item>
          <el-descriptions-item label="认证编号">{{ currentRow.certification_number || '-' }}</el-descriptions-item>
          <el-descriptions-item label="服务次数">{{ currentRow.service_count || 0 }}次</el-descriptions-item>
          <el-descriptions-item label="接单状态">{{ currentRow.is_available ? '可接单' : '离线' }}</el-descriptions-item>
          <el-descriptions-item label="评分">{{ currentRow.average_rating || '-' }}/5</el-descriptions-item>
          <el-descriptions-item label="认证状态" :span="2">
            <el-tag :type="currentRow.is_certified ? 'success' : 'warning'">
              {{ currentRow.is_certified ? '已认证' : '未认证' }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="专长" :span="2" v-if="currentRow.specialty">
            <div class="specialty-tags">
              <el-tag v-for="s in (typeof currentRow.specialty==='string'?JSON.parse(currentRow.specialty):currentRow.specialty)" :key="s" size="small" style="margin:2px">{{ s }}</el-tag>
            </div>
          </el-descriptions-item>
          <el-descriptions-item label="简介" :span="2" v-if="currentRow.introduction">{{ currentRow.introduction }}</el-descriptions-item>
          <el-descriptions-item label="入驻时间" :span="2">{{ currentRow.created_at }}</el-descriptions-item>
        </el-descriptions>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { Search } from '@element-plus/icons-vue'
import api from '../api/index.js'
import { ElMessage } from 'element-plus'

const loading = ref(false)
const list = ref([])
const total = ref(0)
const page = ref(1)
const pageSize = ref(20)
const searchText = ref('')
const filterCertified = ref('')
const detailVisible = ref(false)
const currentRow = ref(null)
const certifyingId = ref(null)
const stats = ref([
  { label:'总陪诊师', value:0, color:'#1A73E8' },
  { label:'已认证', value:0, color:'#34A853' },
  { label:'未认证', value:0, color:'#E6A23C' },
  { label:'可接单', value:0, color:'#DB4437' },
])

async function loadStats() {
  try {
    const res = await api.get('/admin/companions', { page:1, limit:1 })
    if (res.success) {
      const data = res.data || []
      const totalCount = res.pagination?.total || 0
      const certifiedCount = data.filter(d => d.is_certified).length
      // 获取总数时粗略统计
      const allRes = await api.get('/admin/companions', { page:1, limit: 999 })
      if (allRes.success) {
        const all = allRes.data || []
        const cert = all.filter(d => d.is_certified).length
        const avail = all.filter(d => d.is_available).length
        stats.value = [
          { label:'总陪诊师', value: all.length, color:'#1A73E8' },
          { label:'已认证', value: cert, color:'#34A853' },
          { label:'未认证', value: all.length - cert, color:'#E6A23C' },
          { label:'可接单', value: avail, color:'#DB4437' },
        ]
      }
    }
  } catch (e) { console.error(e) }
}

async function loadData() {
  loading.value = true
  try {
    const params = { page: page.value, page_size: pageSize.value }
    if (filterCertified.value !== '') params.is_certified = filterCertified.value
    if (searchText.value.trim()) params.search = searchText.value.trim()
    const res = await api.get('/admin/companions', params)
    if (res.success) {
      list.value = res.data || []
      total.value = res.pagination?.total || 0
    }
  } catch (e) { console.error(e) }
  loading.value = false
}

function showDetail(row) {
  currentRow.value = row
  detailVisible.value = true
}

async function approveCertify(row) {
  certifyingId.value = row.id
  try {
    const res = await api.post(`/admin/companions/${row.id}/certify`, { action:'approve' })
    if (res.success) {
      ElMessage.success('已通过认证')
      loadData()
      loadStats()
    }
  } catch (e) { ElMessage.error('操作失败') }
  certifyingId.value = null
}

async function rejectCertify(row) {
  try {
    const res = await api.post(`/admin/companions/${row.id}/certify`, { action:'reject' })
    if (res.success) {
      ElMessage.success('已取消认证')
      loadData()
      loadStats()
    }
  } catch (e) { ElMessage.error('操作失败') }
}

function resetFilter() {
  filterCertified.value = ''
  searchText.value = ''
  page.value = 1
  loadData()
}

onMounted(() => { loadData(); loadStats() })
</script>

<style scoped>
.header { display: flex; justify-content: space-between; align-items: center; }
.actions { display: flex; align-items: center; }
.stat-item { text-align: center; }
.stat-value { font-size: 22px; font-weight: bold; }
.stat-label { font-size: 12px; color: #999; margin-top: 4px; }
.pagination-wrap { margin-top: 20px; display: flex; justify-content: flex-end; }
.specialty-tags { display: flex; flex-wrap: wrap; gap: 4px; }
</style>
