<template>
  <div class="dashboard">
    <el-row :gutter="20">
      <!-- 数据概览 -->
      <el-col :xs="24" :sm="12" :md="6" :lg="6">
        <el-card shadow="hover">
          <div class="stat-card">
            <div class="stat-icon" style="background-color: #e6f7ff;">
              <el-icon><User /></el-icon>
            </div>
            <div class="stat-content">
              <div class="stat-value">{{ stats.totalUsers }}</div>
              <div class="stat-label">总用户数</div>
            </div>
          </div>
        </el-card>
      </el-col>
      
      <el-col :xs="24" :sm="12" :md="6" :lg="6">
        <el-card shadow="hover">
          <div class="stat-card">
            <div class="stat-icon" style="background-color: #f6ffed;">
              <el-icon><UserFilled /></el-icon>
            </div>
            <div class="stat-content">
              <div class="stat-value">{{ stats.totalCompanions }}</div>
              <div class="stat-label">陪诊师数</div>
            </div>
          </div>
        </el-card>
      </el-col>
      
      <el-col :xs="24" :sm="12" :md="6" :lg="6">
        <el-card shadow="hover">
          <div class="stat-card">
            <div class="stat-icon" style="background-color: #fff7e6;">
              <el-icon><Document /></el-icon>
            </div>
            <div class="stat-content">
              <div class="stat-value">{{ stats.totalOrders }}</div>
              <div class="stat-label">总订单数</div>
            </div>
          </div>
        </el-card>
      </el-col>
      
      <el-col :xs="24" :sm="12" :md="6" :lg="6">
        <el-card shadow="hover">
          <div class="stat-card">
            <div class="stat-icon" style="background-color: #fff0f6;">
              <el-icon><Money /></el-icon>
            </div>
            <div class="stat-content">
              <div class="stat-value">¥{{ stats.totalRevenue }}</div>
              <div class="stat-label">总收入</div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>
    
    <!-- 图表区域 -->
    <el-row :gutter="20" class="chart-row">
      <el-col :xs="24" :lg="16">
        <el-card shadow="hover">
          <template #header>
            <span>订单趋势</span>
          </template>
          <v-chart :option="orderChartOption" style="height: 300px;" />
        </el-card>
      </el-col>
      
      <el-col :xs="24" :lg="8">
        <el-card shadow="hover">
          <template #header>
            <span>订单状态分布</span>
          </template>
          <v-chart :option="statusChartOption" style="height: 300px;" />
        </el-card>
      </el-col>
    </el-row>
    
    <!-- 最近订单 -->
    <el-card shadow="hover" class="recent-orders">
      <template #header>
        <span>最近订单</span>
        <el-button type="primary" link @click="$router.push('/orders')">
          查看全部
        </el-button>
      </template>
      
      <el-table :data="recentOrders" style="width: 100%">
        <el-table-column prop="order_no" label="订单号" width="180" />
        <el-table-column prop="patient_name" label="患者" width="120" />
        <el-table-column prop="companion_name" label="陪诊师" width="120" />
        <el-table-column prop="hospital_name" label="医院" />
        <el-table-column prop="amount" label="金额" width="100">
          <template #default="{ row }">
            ¥{{ row.amount }}
          </template>
        </el-table-column>
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="getStatusType(row.status)">
              {{ getStatusText(row.status) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="created_at" label="创建时间" width="180" />
        <el-table-column label="操作" width="100">
          <template #default="{ row }">
            <el-button type="primary" link @click="viewOrder(row.order_no)">
              查看
            </el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { User, UserFilled, Document, Money } from '@element-plus/icons-vue'
import VChart from 'vue-echarts'
import { use } from 'echarts/core'
import { CanvasRenderer } from 'echarts/renderers'
import { LineChart, PieChart } from 'echarts/charts'
import {
  TitleComponent,
  TooltipComponent,
  LegendComponent,
  GridComponent
} from 'echarts/components'
import api from '@/api'

use([
  CanvasRenderer,
  LineChart,
  PieChart,
  TitleComponent,
  TooltipComponent,
  LegendComponent,
  GridComponent
])

const router = useRouter()

const stats = ref({
  totalUsers: 0,
  totalCompanions: 0,
  totalOrders: 0,
  totalRevenue: 0
})

const recentOrders = ref([])

const orderChartOption = ref({
  tooltip: {
    trigger: 'axis'
  },
  xAxis: {
    type: 'category',
    data: ['1月', '2月', '3月', '4月', '5月', '6月', '7月']
  },
  yAxis: {
    type: 'value'
  },
  series: [{
    data: [120, 200, 150, 80, 70, 110, 130],
    type: 'line',
    smooth: true,
    itemStyle: {
      color: '#409EFF'
    }
  }]
})

const statusChartOption = ref({
  tooltip: {
    trigger: 'item'
  },
  legend: {
    orient: 'vertical',
    left: 'left'
  },
  series: [{
    type: 'pie',
    radius: '50%',
    data: [
      { value: 1048, name: '待接单' },
      { value: 735, name: '进行中' },
      { value: 580, name: '已完成' },
      { value: 484, name: '已取消' }
    ],
    emphasis: {
      itemStyle: {
        shadowBlur: 10,
        shadowOffsetX: 0,
        shadowColor: 'rgba(0, 0, 0, 0.5)'
      }
    }
  }]
})

const getStatusType = (status: string) => {
  const types: Record<string, string> = {
    pending: 'info',
    accepted: 'warning',
    ongoing: 'primary',
    completed: 'success',
    cancelled: 'danger'
  }
  return types[status] || 'info'
}

const getStatusText = (status: string) => {
  const texts: Record<string, string> = {
    pending: '待接单',
    accepted: '已接单',
    ongoing: '进行中',
    completed: '已完成',
    cancelled: '已取消'
  }
  return texts[status] || status
}

const viewOrder = (orderNo: string) => {
  router.push(`/orders/${orderNo}`)
}

const loadDashboardData = async () => {
  try {
    // 加载统计数据
    const statsRes = await api.get('/admin/dashboard/stats')
    stats.value = statsRes.data
    
    // 加载最近订单
    const ordersRes = await api.get('/admin/orders/recent')
    recentOrders.value = ordersRes.data
  } catch (error) {
    ElMessage.error('加载数据失败')
  }
}

onMounted(() => {
  loadDashboardData()
})
</script>

<style scoped>
.dashboard {
  padding: 20px;
}

.stat-card {
  display: flex;
  align-items: center;
}

.stat-icon {
  width: 48px;
  height: 48px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-right: 16px;
}

.stat-icon .el-icon {
  font-size: 24px;
  color: #1890ff;
}

.stat-content {
  flex: 1;
}

.stat-value {
  font-size: 24px;
  font-weight: 600;
  color: #1f2d3d;
  margin-bottom: 4px;
}

.stat-label {
  font-size: 14px;
  color: #8492a6;
}

.chart-row {
  margin-top: 20px;
  margin-bottom: 20px;
}

.recent-orders {
  margin-top: 20px;
}
</style>