<template>
  <div class="page-container">
    <!-- 页面头部 -->
    <h1 class="page-title">数据总览</h1>
    <p class="page-subtitle">{{ userStore.farmName || '智慧农业平台' }} · 欢迎回来，{{ userStore.username }}</p>

    <!-- 统计卡片 -->
    <div class="stats-row" v-loading="loading">
      <div v-for="card in statCards" :key="card.title" class="stat-card">
        <div class="stat-icon" :style="{ background: card.bg, color: card.color }">
          <el-icon :size="22"><component :is="card.icon" /></el-icon>
        </div>
        <div class="stat-body">
          <div class="stat-value">
            {{ formatNumber(card.value, card.decimals) }}<span class="stat-unit">{{ card.unit }}</span>
          </div>
          <div class="stat-label">{{ card.title }}</div>
        </div>
      </div>
    </div>

    <!-- 地块概览 -->
    <div class="section">
      <div class="section-header">
        <h2 class="section-title">地块概览</h2>
        <span class="section-count">共 {{ fields.length }} 块</span>
      </div>
      <div class="field-grid" v-loading="loading">
        <el-empty v-if="!loading && fields.length === 0" description="暂无地块数据，请先绑定农场管理者" :image-size="80" />
        <div
          v-for="field in fields"
          :key="field.id"
          class="field-card"
          @click="goToMonitor(field)"
        >
          <div class="field-card-header">
            <span class="field-name">{{ field.name }}</span>
            <el-tag :type="getStatusInfo(field.status).type" size="small" effect="light">
              {{ getStatusInfo(field.status).label }}
            </el-tag>
          </div>
          <div class="field-card-info">
            <span>{{ field.crop }}</span>
            <span class="info-divider">·</span>
            <span>{{ field.area }} ㎡</span>
          </div>
          <div class="field-moisture">
            <div class="moisture-label">
              <span>土壤湿度</span>
              <span class="moisture-value" :style="{ color: getStatusInfo(field.status).color }">
                {{ field.status === 'offline' ? '--' : field.soilMoisture + '%' }}
              </span>
            </div>
            <el-progress
              :percentage="field.status === 'offline' ? 0 : field.soilMoisture"
              :color="getStatusInfo(field.status).color"
              :show-text="false"
              :stroke-width="6"
            />
          </div>
          <div class="field-card-footer">
            <div class="footer-item">
              <el-icon><Sunny /></el-icon>
              <span>{{ field.status === 'offline' ? '--' : formatNumber(field.temperature, 1) + '°C' }}</span>
            </div>
            <div class="footer-item">
              <el-icon><Cloudy /></el-icon>
              <span>{{ field.status === 'offline' ? '--' : field.humidity + '%' }}</span>
            </div>
            <el-icon class="footer-arrow"><ArrowRight /></el-icon>
          </div>
        </div>
      </div>
    </div>

    <!-- 底部：图表 + 告警 -->
    <div class="bottom-section">
      <!-- 7日土壤湿度趋势 -->
      <div class="chart-card" v-loading="loading">
        <div class="card-header">
          <h2 class="section-title">7日土壤湿度趋势</h2>
        </div>
        <div ref="chartRef" class="chart-container"></div>
      </div>

      <!-- 最近告警 -->
      <div class="alerts-card" v-loading="loading">
        <div class="card-header">
          <h2 class="section-title">最近告警</h2>
          <el-tag v-if="alerts.length > 0" type="danger" size="small" effect="light">{{ alerts.length }} 条</el-tag>
        </div>
        <div class="alert-list">
          <div v-for="alert in alerts" :key="alert.id" class="alert-item">
            <div class="alert-dot" :style="{ background: getStatusInfo(alert.level).color }"></div>
            <div class="alert-content">
              <div class="alert-message">{{ alert.message }}</div>
              <div class="alert-meta">
                <span class="alert-field">{{ alert.fieldName }}</span>
                <span class="alert-time">{{ alert.time }}</span>
              </div>
            </div>
            <el-tag :type="getStatusInfo(alert.level).type" size="small" effect="plain">
              {{ getStatusInfo(alert.level).label }}
            </el-tag>
          </div>
          <el-empty v-if="!loading && alerts.length === 0" description="暂无告警" :image-size="60" />
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, nextTick, computed } from 'vue'
import { useRouter } from 'vue-router'
import * as echarts from 'echarts'
import { api } from '@/api'
import { useUserStore } from '@/store/user'
import {
  MapLocation, Monitor, Bell, Drizzling,
  Sunny, Cloudy, ArrowRight,
} from '@element-plus/icons-vue'

const router = useRouter()
const userStore = useUserStore()

const loading = ref(true)
const stats = ref({})
const fields = ref([])
const alerts = ref([])
const chartRef = ref(null)
let chartInstance = null

const statusConfig = {
  normal: { label: '正常', color: '#22c55e', type: 'success' },
  warning: { label: '预警', color: '#f59e0b', type: 'warning' },
  danger: { label: '告警', color: '#ef4444', type: 'danger' },
  offline: { label: '离线', color: '#9ca3af', type: 'info' },
  info: { label: '提示', color: '#6366f1', type: 'info' },
}

const statCards = computed(() => [
  { title: '地块总数', value: stats.value.totalFields ?? 0, icon: MapLocation, color: '#16a34a', bg: '#f0fdf4', unit: '块', decimals: 0 },
  { title: '在线设备', value: stats.value.onlineDevices ?? 0, icon: Monitor, color: '#22c55e', bg: '#f0fdf4', unit: '台', decimals: 0 },
  { title: '活跃告警', value: stats.value.activeAlerts ?? 0, icon: Bell, color: '#f59e0b', bg: '#fffbeb', unit: '条', decimals: 0 },
  { title: '平均湿度', value: stats.value.avgMoisture ?? 0, icon: Drizzling, color: '#3b82f6', bg: '#eff6ff', unit: '%', decimals: 0 },
])

function formatNumber(val, decimals = 0) {
  if (val === null || val === undefined) return '--'
  return Number(val).toFixed(decimals)
}

function getStatusInfo(status) {
  return statusConfig[status] || statusConfig.normal
}

async function loadData() {
  loading.value = true
  try {
    const [statsRes, fieldsRes, alertsRes] = await Promise.all([
      api.getStats(),
      api.getFields(),
      api.getAlerts('active'),
    ])

    if (statsRes.code === 200) stats.value = statsRes.data
    if (fieldsRes.code === 200) fields.value = fieldsRes.data || []
    if (alertsRes.code === 200) alerts.value = (alertsRes.data || []).slice(0, 4)

    // 加载历史数据用于图表
    const historyRes = await api.getHistoryData(1, 7)
    if (historyRes.code === 200 && historyRes.data) {
      await nextTick()
      initChart(historyRes.data)
    }
  } catch {
    // 静默处理，页面显示空数据
    stats.value = {}
    fields.value = []
    alerts.value = []
  } finally {
    loading.value = false
  }
}

function initChart(data) {
  if (!chartRef.value) return

  if (chartInstance) {
    chartInstance.dispose()
  }

  chartInstance = echarts.init(chartRef.value)

  const dates = data.map((d) => d.date)
  const moistureValues = data.map((d) => d.soilMoisture)

  chartInstance.setOption({
    tooltip: {
      trigger: 'axis',
      formatter: '{b}<br/>土壤湿度: {c}%',
    },
    grid: { left: '3%', right: '4%', top: '5%', bottom: '3%', containLabel: true },
    xAxis: {
      type: 'category',
      boundaryGap: false,
      data: dates,
      axisLine: { lineStyle: { color: '#e5e7eb' } },
      axisLabel: { color: '#9ca3af', fontSize: 12 },
      axisTick: { show: false },
    },
    yAxis: {
      type: 'value',
      min: 0,
      max: 100,
      axisLine: { show: false },
      axisTick: { show: false },
      axisLabel: { color: '#9ca3af', fontSize: 12, formatter: '{value}%' },
      splitLine: { lineStyle: { color: '#f3f4f6' } },
    },
    series: [
      {
        name: '土壤湿度',
        type: 'line',
        smooth: true,
        symbol: 'circle',
        symbolSize: 8,
        data: moistureValues,
        lineStyle: { color: '#16a34a', width: 3 },
        itemStyle: { color: '#16a34a', borderColor: '#fff', borderWidth: 2 },
        areaStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: 'rgba(22, 163, 74, 0.25)' },
            { offset: 1, color: 'rgba(22, 163, 74, 0.01)' },
          ]),
        },
      },
    ],
  })
}

function goToMonitor(field) {
  router.push({ path: '/monitor', query: { fieldId: field.id } })
}

function handleResize() {
  chartInstance && chartInstance.resize()
}

onMounted(() => {
  loadData()
  window.addEventListener('resize', handleResize)
})

onUnmounted(() => {
  window.removeEventListener('resize', handleResize)
  if (chartInstance) {
    chartInstance.dispose()
    chartInstance = null
  }
})
</script>

<style scoped>
/* ===== 统计卡片 ===== */
.stats-row {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
  margin-bottom: 24px;
}

.stat-card {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 20px;
  background: var(--bg-card);
  border: 1px solid var(--border-color);
  border-radius: var(--border-radius);
  box-shadow: var(--shadow-sm);
  transition: box-shadow 0.2s ease, transform 0.2s ease;
}

.stat-card:hover {
  box-shadow: var(--shadow-md);
  transform: translateY(-2px);
}

.stat-icon {
  width: 48px;
  height: 48px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.stat-body {
  flex: 1;
  min-width: 0;
}

.stat-value {
  font-size: 28px;
  font-weight: 700;
  color: var(--text-primary);
  line-height: 1.2;
}

.stat-unit {
  font-size: 14px;
  font-weight: 500;
  color: var(--text-tertiary);
  margin-left: 4px;
}

.stat-label {
  font-size: 13px;
  color: var(--text-secondary);
  margin-top: 2px;
}

/* ===== 地块概览 ===== */
.section {
  margin-bottom: 24px;
}

.section-count {
  font-size: 13px;
  color: var(--text-tertiary);
}

.field-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 16px;
  min-height: 120px;
}

.field-card {
  background: var(--bg-card);
  border: 1px solid var(--border-color);
  border-radius: var(--border-radius);
  box-shadow: var(--shadow-sm);
  padding: 16px;
  cursor: pointer;
  transition: all 0.2s ease;
}

.field-card:hover {
  box-shadow: var(--shadow-md);
  transform: translateY(-2px);
  border-color: #bbf7d0;
}

.field-card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 8px;
}

.field-name {
  font-size: 15px;
  font-weight: 600;
  color: var(--text-primary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.field-card-info {
  font-size: 13px;
  color: var(--text-secondary);
  margin-bottom: 14px;
}

.info-divider {
  margin: 0 6px;
  color: var(--text-tertiary);
}

.field-moisture {
  margin-bottom: 14px;
}

.moisture-label {
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-size: 12px;
  color: var(--text-tertiary);
  margin-bottom: 6px;
}

.moisture-value {
  font-size: 14px;
  font-weight: 600;
}

.field-card-footer {
  display: flex;
  align-items: center;
  gap: 16px;
  padding-top: 12px;
  border-top: 1px solid var(--border-color);
}

.footer-item {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
  color: var(--text-secondary);
}

.footer-item .el-icon {
  color: var(--text-tertiary);
  font-size: 15px;
}

.footer-arrow {
  margin-left: auto;
  color: var(--text-tertiary);
  font-size: 14px;
  transition: transform 0.2s ease;
}

.field-card:hover .footer-arrow {
  transform: translateX(3px);
  color: var(--primary);
}

/* ===== 底部区域 ===== */
.bottom-section {
  display: grid;
  grid-template-columns: 1.5fr 1fr;
  gap: 16px;
}

.chart-card,
.alerts-card {
  background: var(--bg-card);
  border: 1px solid var(--border-color);
  border-radius: var(--border-radius);
  box-shadow: var(--shadow-sm);
  padding: 20px;
}

.card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 16px;
}

.chart-container {
  height: 280px;
}

/* ===== 告警列表 ===== */
.alert-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
  min-height: 200px;
}

.alert-item {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  padding: 12px;
  background: #f9fafb;
  border-radius: 8px;
  transition: background 0.2s ease;
}

.alert-item:hover {
  background: #f3f4f6;
}

.alert-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  margin-top: 5px;
  flex-shrink: 0;
}

.alert-content {
  flex: 1;
  min-width: 0;
}

.alert-message {
  font-size: 13px;
  color: var(--text-primary);
  line-height: 1.5;
  margin-bottom: 4px;
}

.alert-meta {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 12px;
  color: var(--text-tertiary);
}

.alert-field {
  color: var(--text-secondary);
}

/* ===== 响应式 ===== */
@media (max-width: 1200px) {
  .stats-row {
    grid-template-columns: repeat(2, 1fr);
  }

  .bottom-section {
    grid-template-columns: 1fr;
  }
}
</style>
