<template>
  <div class="users-page">
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
          <span>用户管理</span>
          <div class="actions">
            <el-select v-model="filterRole" placeholder="角色" @change="loadData" style="width:110px;margin-right:8px">
              <el-option label="全部" value="" />
              <el-option label="患者" value="patient" />
              <el-option label="陪诊师" value="companion" />
              <el-option label="医生" value="doctor" />
              <el-option label="管理员" value="admin" />
            </el-select>
            <el-input v-model="searchText" placeholder="搜索姓名/手机号" clearable @keyup.enter="loadData" style="width:200px;margin-right:8px" />
            <el-button type="primary" @click="loadData" :icon="Search">搜索</el-button>
            <el-button @click="resetFilter">重置</el-button>
          </div>
        </div>
      </template>
      <el-table :data="list" v-loading="loading" stripe style="width:100%">
        <el-table-column label="ID" width="80"><template #default="{row}">{{ row.id }}</template></el-table-column>
        <el-table-column label="姓名" width="100"><template #default="{row}">{{ row.name || '-' }}</template></el-table-column>
        <el-table-column label="手机号" width="130"><template #default="{row}">{{ row.phone || '-' }}</template></el-table-column>
        <el-table-column label="角色" width="80">
          <template #default="{row}">
            <el-tag :type="roleType(row.role)" size="small">{{ roleLabel(row.role) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="注册时间" min-width="160"><template #default="{row}">{{ (row.created_at||'').substring(0,16) }}</template></el-table-column>
        <el-table-column label="状态" width="80">
          <template #default="{row}"><el-tag :type="row.status==='active'?'success':'info'" size="small">{{ row.status==='active'?'正常':row.status }}</el-tag></template>
        </el-table-column>
        <el-table-column label="操作" width="100">
          <template #default="{row}">
            <el-button size="small" @click="showDetail(row)">详情</el-button>
          </template>
        </el-table-column>
      </el-table>
      <div class="pagination-wrap" v-if="total>0">
        <el-pagination v-model:current-page="page" :page-size="pageSize" :total="total" layout="total,prev,pager,next" @current-change="loadData" />
      </div>
    </el-card>

    <el-dialog v-model="detailVisible" title="用户详情" width="550px">
      <template v-if="currentRow">
        <el-descriptions :column="2" border>
          <el-descriptions-item label="ID">{{ currentRow.id }}</el-descriptions-item>
          <el-descriptions-item label="姓名">{{ currentRow.name }}</el-descriptions-item>
          <el-descriptions-item label="手机号">{{ currentRow.phone }}</el-descriptions-item>
          <el-descriptions-item label="角色"><el-tag :type="roleType(currentRow.role)" size="small">{{ roleLabel(currentRow.role) }}</el-tag></el-descriptions-item>
          <el-descriptions-item label="状态"><el-tag :type="currentRow.status==='active'?'success':'info'" size="small">{{ currentRow.status==='active'?'正常':currentRow.status }}</el-tag></el-descriptions-item>
          <el-descriptions-item label="邮箱" v-if="currentRow.email">{{ currentRow.email }}</el-descriptions-item>
          <el-descriptions-item label="注册时间" :span="2">{{ currentRow.created_at }}</el-descriptions-item>
          <el-descriptions-item label="最后登录" :span="2" v-if="currentRow.last_login">{{ currentRow.last_login }}</el-descriptions-item>
        </el-descriptions>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { Search } from '@element-plus/icons-vue'
import api from '../api/index.js'

const loading = ref(false)
const list = ref([])
const total = ref(0)
const page = ref(1)
const pageSize = ref(20)
const filterRole = ref('')
const searchText = ref('')
const detailVisible = ref(false)
const currentRow = ref(null)
const stats = ref([{ label:'总用户', value:0, color:'#1A73E8' }, { label:'患者', value:0, color:'#34A853' }, { label:'医生', value:0, color:'#E6A23C' }, { label:'陪诊师', value:0, color:'#DB4437' }])

function roleType(r) { return ({ patient:'success', companion:'warning', doctor:'primary', admin:'danger' })[r] || '' }
function roleLabel(r) { return ({ patient:'患者', companion:'陪诊师', doctor:'医生', admin:'管理员' })[r] || r }

async function loadStats() {
  const res = await api.get('/admin/dashboard/stats')
  if (res.success) {
    const u = res.data.user_stats || {}
    stats.value = [
      { label:'总用户', value: u.total_users || 0, color:'#1A73E8' },
      { label:'患者', value: (u.total_patients || 0), color:'#34A853' },
      { label:'陪诊师', value: (u.total_companions || 0), color:'#E6A23C' },
      { label:'今日新增', value: u.today_new_users || 0, color:'#DB4437' },
    ]
  }
}

async function loadData() {
  loading.value = true
  try {
    const params = { page: page.value, page_size: pageSize.value }
    if (filterRole.value) params.role = filterRole.value
    if (searchText.value.trim()) params.search = searchText.value.trim()
    const res = await api.get('/admin/users', params)
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

function resetFilter() {
  filterRole.value = ''
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
</style>
