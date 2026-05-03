<template>
  <div class="dashboard">
    <!-- 数据概览 -->
    <el-row :gutter="20">
      <el-col :xs="12" :sm="12" :md="6" :lg="6">
        <el-card shadow="hover">
          <div class="stat-card">
            <div class="stat-icon" style="background:#e6f7ff"><el-icon><User /></el-icon></div>
            <div class="stat-content">
              <div class="stat-value">{{ stats.totalUsers }}</div>
              <div class="stat-label">总用户数</div>
              <div class="stat-sub">今日新增 {{ stats.todayNewUsers }}</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :xs="12" :sm="12" :md="6" :lg="6">
        <el-card shadow="hover">
          <div class="stat-card">
            <div class="stat-icon" style="background:#f6ffed"><el-icon><UserFilled /></el-icon></div>
            <div class="stat-content">
              <div class="stat-value">{{ stats.totalCompanions }}</div>
              <div class="stat-label">陪诊师数</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :xs="12" :sm="12" :md="6" :lg="6">
        <el-card shadow="hover">
          <div class="stat-card">
            <div class="stat-icon" style="background:#fff7e6"><el-icon><Document /></el-icon></div>
            <div class="stat-content">
              <div class="stat-value">{{ stats.totalOrders }}</div>
              <div class="stat-label">总订单数</div>
              <div class="stat-sub">今日 {{ stats.todayOrders }}</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :xs="12" :sm="12" :md="6" :lg="6">
        <el-card shadow="hover">
          <div class="stat-card">
            <div class="stat-icon" style="background:#fff0f6"><el-icon><Money /></el-icon></div>
            <div class="stat-content">
              <div class="stat-value">{{ fmtRevenue(stats.totalRevenue) }}</div>
              <div class="stat-label">总收入</div>
              <div class="stat-sub">今日 {{ fmtRevenue(stats.todayRevenue) }}</div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 图表 -->
    <el-row :gutter="20" class="chart-row">
      <el-col :xs="24" :lg="16">
        <el-card shadow="hover">
          <template #header><span>订单趋势</span></template>
          <v-chart :option="orderChartOption" style="height:280px" />
        </el-card>
      </el-col>
      <el-col :xs="24" :lg="8">
        <el-card shadow="hover">
          <template #header><span>订单状态分布</span></template>
          <v-chart :option="statusChartOption" style="height:280px" v-if="statusChartOption.series[0].data.length > 0" />
          <div v-else style="height:280px;display:flex;align-items:center;justify-content:center;color:#999">暂无数据</div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 热门医院 + 活跃陪诊师 -->
    <el-row :gutter="20" class="chart-row">
      <el-col :xs="24" :lg="12">
        <el-card shadow="hover">
          <template #header><span>热门医院</span></template>
          <el-table :data="popularHospitals" v-if="popularHospitals.length" stripe>
            <el-table-column prop="name" label="医院" min-width="150" />
            <el-table-column prop="city" label="城市" width="80" />
            <el-table-column prop="order_count" label="订单数" width="80" />
            <el-table-column label="收入" width="100"><template #default="{row}">{{ fmtRevenue(row.total_revenue) }}</template></el-table-column>
          </el-table>
          <div v-else style="text-align:center;padding:30px;color:#999">暂无数据</div>
        </el-card>
      </el-col>
      <el-col :xs="24" :lg="12">
        <el-card shadow="hover">
          <template #header><span>活跃陪诊师</span></template>
          <el-table :data="activeCompanions" v-if="activeCompanions.length" stripe>
            <el-table-column prop="name" label="姓名" width="80" />
            <el-table-column prop="completed_orders" label="完成单数" width="90" />
            <el-table-column prop="avg_rating" label="评分" width="70" />
            <el-table-column label="收入" width="100"><template #default="{row}">{{ fmtRevenue(row.total_earnings) }}</template></el-table-column>
          </el-table>
          <div v-else style="text-align:center;padding:30px;color:#999">暂无数据</div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 最近订单 -->
    <el-card shadow="hover" class="recent-orders">
      <template #header>
        <div style="display:flex;justify-content:space-between;align-items:center">
          <span>最近订单</span>
          <el-button type="primary" link @click="$router.push('/orders')">查看全部</el-button>
        </div>
      </template>
      <el-table :data="recentOrders" v-loading="loading">
        <el-table-column label="订单号" min-width="160">
          <template #default="{row}">{{ row.order_no || row.id }}</template>
        </el-table-column>
        <el-table-column label="患者" width="100"><template #default="{row}">{{ row.patient_name || row.user_name }}</template></el-table-column>
        <el-table-column label="陪诊师" width="100"><template #default="{row}">{{ row.companion_name }}</template></el-table-column>
        <el-table-column label="医院" min-width="150"><template #default="{row}">{{ row.hospital_name }}</template></el-table-column>
        <el-table-column label="金额" width="90"><template #default="{row}">{{ fmtRevenue(row.amount || row.total_amount) }}</template></el-table-column>
        <el-table-column label="状态" width="90">
          <template #default="{row}"><el-tag :type="statusType(row.status)" size="small">{{ statusText(row.status) }}</el-tag></template>
        </el-table-column>
        <el-table-column label="时间" width="160"><template #default="{row}">{{ (row.created_at||'').substring(0,16) }}</template></el-table-column>
        <el-table-column label="操作" width="80">
          <template #default="{row}"><el-button type="primary" link @click="$router.push('/orders')">查看</el-button></template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import VChart from 'vue-echarts'
import { use } from 'echarts/core'
import { CanvasRenderer } from 'echarts/renderers'
import { LineChart, PieChart } from 'echarts/charts'
import { TooltipComponent, LegendComponent, GridComponent } from 'echarts/components'
import api from '@/api'

use([CanvasRenderer, LineChart, PieChart, TooltipComponent, LegendComponent, GridComponent])

const loading = ref(false)
const recentOrders = ref([])
const popularHospitals = ref([])
const activeCompanions = ref([])
const stats = ref({
  totalUsers: 0, totalCompanions: 0, totalOrders: 0, totalRevenue: 0,
  todayNewUsers: 0, pendingOrders: 0, todayOrders: 0, todayRevenue: 0,
})

const orderChartOption = ref({
  tooltip: { trigger: 'axis' },
  xAxis: { type: 'category', data: [] },
  yAxis: { type: 'value' },
  grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
  series: [{ data: [], type: 'line', smooth: true, itemStyle: { color: '#409EFF' } }]
})

const statusChartOption = ref({
  tooltip: { trigger: 'item' },
  legend: { orient: 'vertical', left: 'left' },
  series: [{ type: 'pie', radius: ['30%', '55%'], data: [], emphasis: { itemStyle: { shadowBlur: 10 } } }]
})

function fmtRevenue(v) { return v ? '¥' + Number(v).toFixed(2) : '¥0.00' }
function statusType(s) {
  return ({ pending: 'info', accepted: 'warning', ongoing: 'primary', completed: 'success', cancelled: 'danger' })[s] || 'info'
}
function statusText(s) {
  return ({ pending: '待接单', accepted: '已接单', ongoing: '进行中', completed: '已完成', cancelled: '已取消' })[s] || s
}

async function loadData() {
  loading.value = true
  try {
    const res = await api.get('/admin/dashboard/stats')
    if (res.success) {
      const d = res.data
      const u = d.user_stats || {};
      const o = d.order_stats || {};
      stats.value = {
        totalUsers: u.total_users || 0, totalCompanions: u.total_companions || 0,
        totalOrders: o.total_orders || 0, totalRevenue: o.total_revenue || 0,
        todayNewUsers: u.today_new_users || 0, pendingOrders: o.pending_orders || 0,
        todayOrders: o.today_orders || 0, todayRevenue: o.today_revenue || 0,
      }

      const trend = d.order_trend || []
      if (trend.length) {
        orderChartOption.value = {
          ...orderChartOption.value,
          xAxis: { type: 'category', data: trend.map(t => t.month) },
          series: [{ data: trend.map(t => t.count), type: 'line', smooth: true, itemStyle: { color: '#409EFF' } }]
        }
      }

      const statusData = [
        { value: o.pending_orders || 0, name: '待接单' },
        { value: o.confirmed_orders || 0, name: '已接单' },
        { value: o.completed_orders || 0, name: '已完成' },
        { value: o.cancelled_orders || 0, name: '已取消' },
      ].filter(s => s.value > 0)
      if (statusData.length) statusChartOption.value.series[0].data = statusData

      popularHospitals.value = d.popular_hospitals || []
      activeCompanions.value = d.active_companions || []
    }

    const ordersRes = await api.get('/admin/orders/recent')
    if (ordersRes.success) recentOrders.value = ordersRes.data || []
  } catch (e) {
    ElMessage.error('加载数据失败')
  }
  loading.value = false
}

onMounted(loadData)
</script>

<style scoped>
.dashboard { padding: 16px; }
.stat-card { display: flex; align-items: center; }
.stat-icon { width: 44px; height: 44px; border-radius: 8px; display: flex; align-items: center; justify-content: center; margin-right: 14px; }
.stat-icon .el-icon { font-size: 22px; color: #1890ff; }
.stat-content { flex: 1; }
.stat-value { font-size: 22px; font-weight: 600; color: #1f2d3d; line-height: 1.2; }
.stat-label { font-size: 13px; color: #8492a6; }
.stat-sub { font-size: 11px; color: #c0c4cc; margin-top: 2px; }
.chart-row { margin-top: 16px; margin-bottom: 4px; }
.recent-orders { margin-top: 16px; }
</style>
