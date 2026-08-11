<template>
  <div class="page-container">
    <!-- 页面头部 -->
    <h1 class="page-title">实时监测</h1>
    <p class="page-subtitle">实时查看地块环境数据与设备运行状态</p>

    <!-- 地块选择器 -->
    <div class="selector-bar">
      <span class="selector-label">选择地块</span>
      <el-select
        v-model="selectedFieldId"
        placeholder="请选择地块"
        filterable
        style="width: 280px"
      >
        <el-option
          v-for="field in fields"
          :key="field.id"
          :label="`${field.name}（${field.crop}）`"
          :value="field.id"
        />
      </el-select>
    </div>

    <!-- 实时数据卡片 -->
    <div class="realtime-cards" v-loading="loading">
      <!-- 土壤湿度 -->
      <div class="rt-card">
        <div class="rt-card-header">
          <div class="rt-card-icon moisture">
            <el-icon :size="20"><Drizzling /></el-icon>
          </div>
          <span class="rt-card-title">土壤湿度</span>
          <el-tag :type="isOffline ? 'info' : 'success'" size="small" effect="light" class="rt-status-tag">
            {{ isOffline ? '设备离线' : '设备在线' }}
          </el-tag>
        </div>
        <div class="rt-card-value" :style="{ color: isOffline ? 'var(--text-tertiary)' : '#16a34a' }">
          {{ isOffline ? '--' : fieldData.soilMoisture }}<span class="rt-card-unit">%</span>
        </div>
        <el-progress
          :percentage="isOffline ? 0 : fieldData.soilMoisture"
          color="#16a34a"
          :show-text="false"
          :stroke-width="8"
        />
      </div>

      <!-- 温度 -->
      <div class="rt-card">
        <div class="rt-card-header">
          <div class="rt-card-icon temp">
            <el-icon :size="20"><Sunny /></el-icon>
          </div>
          <span class="rt-card-title">温度</span>
          <el-tag :type="isOffline ? 'info' : 'success'" size="small" effect="light" class="rt-status-tag">
            {{ isOffline ? '设备离线' : '设备在线' }}
          </el-tag>
        </div>
        <div class="rt-card-value" :style="{ color: isOffline ? 'var(--text-tertiary)' : tempColor }">
          {{ isOffline ? '--' : formatNumber(fieldData.temperature, 1) }}<span class="rt-card-unit">°C</span>
        </div>
        <el-progress
          :percentage="isOffline ? 0 : tempPercentage"
          :color="tempColor"
          :show-text="false"
          :stroke-width="8"
        />
      </div>

      <!-- 空气湿度 -->
      <div class="rt-card">
        <div class="rt-card-header">
          <div class="rt-card-icon humidity">
            <el-icon :size="20"><Cloudy /></el-icon>
          </div>
          <span class="rt-card-title">空气湿度</span>
          <el-tag :type="isOffline ? 'info' : 'success'" size="small" effect="light" class="rt-status-tag">
            {{ isOffline ? '设备离线' : '设备在线' }}
          </el-tag>
        </div>
        <div class="rt-card-value" :style="{ color: isOffline ? 'var(--text-tertiary)' : '#3b82f6' }">
          {{ isOffline ? '--' : fieldData.humidity }}<span class="rt-card-unit">%</span>
        </div>
        <el-progress
          :percentage="isOffline ? 0 : fieldData.humidity"
          color="#3b82f6"
          :show-text="false"
          :stroke-width="8"
        />
      </div>
    </div>

    <!-- 天气预报 -->
    <div class="section weather-section" v-loading="weatherLoading">
      <div class="section-header">
        <h2 class="section-title">
          <el-icon style="margin-right: 6px; vertical-align: middle;"><Sunny /></el-icon>
          天气预报
        </h2>
        <span class="weather-update-time" v-if="weatherData">更新于 {{ weatherData.current.updateTime }}</span>
      </div>
      <div class="weather-panel" v-if="weatherData">
        <!-- 当前天气 -->
        <div class="weather-current">
          <div class="weather-current-main">
            <span class="weather-icon-large">{{ getWeatherIcon(weatherData.current.condition) }}</span>
            <div class="weather-temp-area">
              <span class="weather-temp">{{ weatherData.current.temp }}°</span>
              <span class="weather-condition">{{ weatherData.current.conditionText }}</span>
            </div>
          </div>
          <div class="weather-current-details">
            <div class="weather-detail-item">
              <span class="weather-detail-label">体感温度</span>
              <span class="weather-detail-value">{{ weatherData.current.feelsLike }}°C</span>
            </div>
            <div class="weather-detail-item">
              <span class="weather-detail-label">空气湿度</span>
              <span class="weather-detail-value">{{ weatherData.current.humidity }}%</span>
            </div>
            <div class="weather-detail-item">
              <span class="weather-detail-label">{{ weatherData.current.windDirection }}</span>
              <span class="weather-detail-value">{{ weatherData.current.windSpeed }} km/h</span>
            </div>
            <div class="weather-detail-item">
              <span class="weather-detail-label">紫外线</span>
              <span class="weather-detail-value">{{ weatherData.current.uvIndex }}</span>
            </div>
          </div>
        </div>
        <!-- 5日预报 -->
        <div class="weather-forecast">
          <div class="forecast-item" v-for="(item, idx) in weatherData.forecast" :key="idx">
            <span class="forecast-day">{{ item.dayOfWeek }}</span>
            <span class="forecast-icon">{{ getWeatherIcon(item.condition) }}</span>
            <span class="forecast-text">{{ item.conditionText }}</span>
            <span class="forecast-temp">{{ item.highTemp }}° / {{ item.lowTemp }}°</span>
            <span class="forecast-wind">{{ item.wind }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- 历史趋势图表 -->
    <div class="section">
      <div class="section-header">
        <h2 class="section-title">7日历史趋势</h2>
      </div>
      <div class="charts-grid" v-loading="loading">
        <div class="chart-box">
          <div class="chart-box-title">土壤湿度趋势</div>
          <div ref="moistureChartRef" class="chart-box-container"></div>
        </div>
        <div class="chart-box">
          <div class="chart-box-title">温度趋势</div>
          <div ref="tempChartRef" class="chart-box-container"></div>
        </div>
        <div class="chart-box">
          <div class="chart-box-title">空气湿度趋势</div>
          <div ref="humidityChartRef" class="chart-box-container"></div>
        </div>
      </div>
    </div>

    <!-- 实时监控 -->
    <div class="section monitor-section">
      <div class="section-header">
        <h2 class="section-title">
          <el-icon style="margin-right: 6px; vertical-align: middle;"><VideoCamera /></el-icon>
          实时监控
        </h2>
        <el-button type="primary" size="small" :icon="Link" @click="openBindMonitorDialog">
          绑定监控
        </el-button>
      </div>
      <div class="monitor-grid">
        <!-- 已绑定的摄像头 -->
        <div v-for="cam in cameraDevices" :key="cam.id" class="monitor-card">
          <div class="monitor-screen">
            <div class="monitor-placeholder">
              <el-icon :size="48"><VideoCamera /></el-icon>
              <span class="monitor-placeholder-text">{{ cam.name }}</span>
              <span class="monitor-placeholder-hint">监控画面（占位）</span>
            </div>
            <div class="monitor-overlay">
              <span class="monitor-time">{{ currentTimeStr }}</span>
              <span class="monitor-badge">● LIVE</span>
            </div>
          </div>
          <div class="monitor-info">
            <span class="monitor-device-name">{{ cam.name }}</span>
            <el-tag :type="cam.status === 'online' ? 'success' : 'info'" size="small" effect="dark">
              {{ cam.status === 'online' ? '在线' : '离线' }}
            </el-tag>
          </div>
        </div>
        <!-- 无摄像头占位 -->
        <div v-if="cameraDevices.length === 0" class="monitor-empty">
          <el-icon :size="40"><VideoCamera /></el-icon>
          <p class="monitor-empty-text">该地块暂无绑定监控设备</p>
          <el-button type="primary" plain size="small" @click="openBindMonitorDialog">绑定监控</el-button>
        </div>
      </div>
    </div>

    <!-- 底部：阈值设置 + 设备状态 -->
    <div class="bottom-section">
      <!-- 阈值设置 -->
      <div class="panel-card">
        <div class="card-header">
          <h2 class="section-title">阈值设置</h2>
          <el-button type="primary" size="small" :loading="saving" @click="saveThresholds">保存设置</el-button>
        </div>
        <el-form :model="thresholdForm" label-position="left" label-width="72px" v-loading="loading">
          <el-form-item label="土壤湿度">
            <div class="range-input">
              <el-input-number v-model="thresholdForm.soilMoistureMin" :min="0" :max="100" size="small" controls-position="right" />
              <span class="range-dash">~</span>
              <el-input-number v-model="thresholdForm.soilMoistureMax" :min="0" :max="100" size="small" controls-position="right" />
              <span class="range-unit">%</span>
            </div>
          </el-form-item>
          <el-form-item label="温度">
            <div class="range-input">
              <el-input-number v-model="thresholdForm.tempMin" :min="-20" :max="60" size="small" controls-position="right" />
              <span class="range-dash">~</span>
              <el-input-number v-model="thresholdForm.tempMax" :min="-20" :max="60" size="small" controls-position="right" />
              <span class="range-unit">°C</span>
            </div>
          </el-form-item>
        </el-form>
        <!-- 阈值对比 -->
        <div class="threshold-compare" v-if="fieldData.id">
          <div class="compare-item">
            <span class="compare-label">当前湿度</span>
            <span class="compare-value">{{ isOffline ? '--' : fieldData.soilMoisture + '%' }}</span>
            <el-tag :type="isMoistureInRange ? 'success' : 'danger'" size="small" effect="plain">
              {{ isMoistureInRange ? '正常' : '超限' }}
            </el-tag>
          </div>
          <div class="compare-item">
            <span class="compare-label">当前温度</span>
            <span class="compare-value">{{ isOffline ? '--' : formatNumber(fieldData.temperature, 1) + '°C' }}</span>
            <el-tag :type="isTempInRange ? 'success' : 'danger'" size="small" effect="plain">
              {{ isTempInRange ? '正常' : '超限' }}
            </el-tag>
          </div>
        </div>
      </div>

      <!-- 设备状态 -->
      <div class="panel-card">
        <div class="card-header">
          <h2 class="section-title">设备状态</h2>
        </div>
        <div class="device-list" v-loading="loading">
          <div v-for="device in devices" :key="device.id" class="device-item">
            <div class="device-item-header">
              <span class="device-item-name">{{ device.name }}</span>
              <el-tag :type="device.status === 'online' ? 'success' : 'info'" size="small" effect="dark">
                {{ device.status === 'online' ? '在线' : '离线' }}
              </el-tag>
            </div>
            <div class="device-item-body">
              <div class="device-info-row">
                <span class="device-info-label">电量</span>
                <div class="battery-bar">
                  <div class="battery-fill" :class="batteryClass(device.battery)" :style="{ width: device.battery + '%' }"></div>
                </div>
                <span class="battery-text" :class="batteryClass(device.battery)">{{ device.battery }}%</span>
              </div>
              <div class="device-info-row">
                <span class="device-info-label">最近上报</span>
                <span class="device-info-value">{{ device.lastReport }}</span>
              </div>
            </div>
          </div>
          <el-empty v-if="!loading && devices.length === 0" description="该地块暂无绑定设备" :image-size="60" />
        </div>
      </div>
    </div>

    <!-- 绑定监控对话框 -->
    <el-dialog v-model="monitorDialogVisible" title="绑定监控设备" width="460px" :close-on-click-modal="false">
      <div v-if="allCameraDevices.length === 0" style="text-align: center; padding: 20px;">
        <el-empty description="暂无可绑定的摄像头设备" :image-size="60" />
      </div>
      <el-form v-else label-width="80px">
        <el-form-item label="选择设备">
          <el-select v-model="selectedCameraId" placeholder="请选择摄像头" style="width: 100%" filterable>
            <el-option
              v-for="cam in allCameraDevices"
              :key="cam.id"
              :label="`${cam.name}${cam.fieldId ? '（已绑定）' : ''}`"
              :value="cam.id"
            />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="monitorDialogVisible = false">取消</el-button>
        <el-button type="primary" :disabled="!selectedCameraId" @click="handleBindMonitor">确定绑定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, computed, watch, onMounted, onUnmounted, nextTick } from 'vue'
import { useRoute } from 'vue-router'
import * as echarts from 'echarts'
import { ElMessage } from 'element-plus'
import { api } from '@/api'
import { Drizzling, Sunny, Cloudy, VideoCamera, Link } from '@element-plus/icons-vue'

const route = useRoute()

const loading = ref(false)
const saving = ref(false)
const fields = ref([])
const selectedFieldId = ref(null)
const fieldData = ref({})
const historyData = ref([])
const devices = ref([])
const cameraDevices = ref([])
const currentTimeStr = ref('')
const monitorDialogVisible = ref(false)
const allCameraDevices = ref([]) // all unbound cameras
const selectedCameraId = ref('')
let clockTimer = null

// ===== 天气预报 =====
const weatherData = ref(null)
const weatherLoading = ref(false)

const thresholdForm = reactive({
  soilMoistureMin: 0,
  soilMoistureMax: 0,
  tempMin: 0,
  tempMax: 0,
})

// 图表 DOM 引用与实例
const moistureChartRef = ref(null)
const tempChartRef = ref(null)
const humidityChartRef = ref(null)
let moistureChart = null
let tempChart = null
let humidityChart = null

// ===== 计算属性 =====
const isOffline = computed(() => fieldData.value?.status === 'offline')

const tempPercentage = computed(() => {
  const temp = fieldData.value?.temperature
  if (!temp && temp !== 0) return 0
  return Math.min(100, Math.max(0, (temp / 50) * 100))
})

const tempColor = computed(() => {
  const temp = fieldData.value?.temperature
  if (temp == null) return '#9ca3af'
  if (temp < 5) return '#3b82f6'
  if (temp > 35) return '#ef4444'
  if (temp > 30) return '#f59e0b'
  return '#22c55e'
})

const isMoistureInRange = computed(() => {
  const v = fieldData.value?.soilMoisture
  if (v == null) return true
  return v >= thresholdForm.soilMoistureMin && v <= thresholdForm.soilMoistureMax
})

const isTempInRange = computed(() => {
  const v = fieldData.value?.temperature
  if (v == null) return true
  return v >= thresholdForm.tempMin && v <= thresholdForm.tempMax
})

// ===== 工具函数 =====
function formatNumber(val, decimals = 0) {
  if (val === null || val === undefined) return '--'
  return Number(val).toFixed(decimals)
}

function batteryClass(battery) {
  if (battery <= 20) return 'danger'
  if (battery <= 50) return 'warning'
  return 'success'
}

// ===== 图表 =====
function buildLineOption(data, valueKey, color, unit, name, yAxisMax) {
  return {
    tooltip: {
      trigger: 'axis',
      formatter: `{b}<br/>${name}: {c}${unit}`,
    },
    grid: { left: '3%', right: '4%', top: '8%', bottom: '3%', containLabel: true },
    xAxis: {
      type: 'category',
      boundaryGap: false,
      data: data.map((d) => d.date),
      axisLine: { lineStyle: { color: '#e5e7eb' } },
      axisLabel: { color: '#9ca3af', fontSize: 11 },
      axisTick: { show: false },
    },
    yAxis: {
      type: 'value',
      max: yAxisMax,
      axisLine: { show: false },
      axisTick: { show: false },
      axisLabel: { color: '#9ca3af', fontSize: 11, formatter: `{value}${unit}` },
      splitLine: { lineStyle: { color: '#f3f4f6' } },
    },
    series: [
      {
        name,
        type: 'line',
        smooth: true,
        symbol: 'circle',
        symbolSize: 6,
        data: data.map((d) => d[valueKey]),
        lineStyle: { color, width: 2 },
        itemStyle: { color, borderColor: '#fff', borderWidth: 1 },
      },
    ],
  }
}

function updateCharts() {
  const data = historyData.value
  if (!data || data.length === 0) return

  // 土壤湿度图表（绿色面积线图）
  if (moistureChartRef.value) {
    if (!moistureChart) {
      moistureChart = echarts.init(moistureChartRef.value)
    }
    const option = buildLineOption(data, 'soilMoisture', '#16a34a', '%', '土壤湿度', 100)
    option.series[0].areaStyle = {
      color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
        { offset: 0, color: 'rgba(22, 163, 74, 0.25)' },
        { offset: 1, color: 'rgba(22, 163, 74, 0.01)' },
      ]),
    }
    moistureChart.setOption(option, true)
  }

  // 温度图表（橙色线图）
  if (tempChartRef.value) {
    if (!tempChart) {
      tempChart = echarts.init(tempChartRef.value)
    }
    tempChart.setOption(buildLineOption(data, 'temperature', '#f59e0b', '°C', '温度', 50), true)
  }

  // 空气湿度图表（蓝色线图）
  if (humidityChartRef.value) {
    if (!humidityChart) {
      humidityChart = echarts.init(humidityChartRef.value)
    }
    humidityChart.setOption(buildLineOption(data, 'humidity', '#3b82f6', '%', '空气湿度', 100), true)
  }
}

function handleResize() {
  moistureChart && moistureChart.resize()
  tempChart && tempChart.resize()
  humidityChart && humidityChart.resize()
}

// ===== 数据加载 =====
async function loadFields() {
  try {
    const res = await api.getFields()
    if (res.code === 200) {
      fields.value = res.data || []
    }
  } catch {
    fields.value = []
  }
}

async function loadFieldData(fieldId) {
  loading.value = true
  try {
    const [fieldRes, historyRes, thresholdsRes, devicesRes] = await Promise.all([
      api.getField(fieldId),
      api.getHistoryData(fieldId, 7),
      api.getThresholds(fieldId),
      api.getDevices(),
    ])

    if (fieldRes.code === 200) fieldData.value = fieldRes.data || {}
    if (historyRes.code === 200) {
      historyData.value = historyRes.data || []
      await nextTick()
      updateCharts()
    }
    if (thresholdsRes.code === 200 && thresholdsRes.data) {
      Object.assign(thresholdForm, thresholdsRes.data)
    }
    if (devicesRes.code === 200) {
      devices.value = (devicesRes.data || []).filter((d) => d.fieldId === Number(fieldId))
      cameraDevices.value = devices.value.filter((d) => d.type === 'camera')
    }
  } catch (error) {
    // 静默处理，页面显示空数据
    fieldData.value = {}
    historyData.value = []
    devices.value = []
    cameraDevices.value = []
  } finally {
    loading.value = false
  }
}

async function saveThresholds() {
  if (thresholdForm.soilMoistureMin >= thresholdForm.soilMoistureMax) {
    ElMessage.warning('土壤湿度下限必须小于上限')
    return
  }
  if (thresholdForm.tempMin >= thresholdForm.tempMax) {
    ElMessage.warning('温度下限必须小于上限')
    return
  }
  saving.value = true
  try {
    const res = await api.updateThresholds(selectedFieldId.value, { ...thresholdForm })
    if (res.code === 200) {
      ElMessage.success('阈值保存成功')
    }
  } catch {
    // 静默处理，不弹toast
  } finally {
    saving.value = false
  }
}

// ===== 实时监控 =====
function updateClock() {
  const now = new Date()
  const y = now.getFullYear()
  const m = String(now.getMonth() + 1).padStart(2, '0')
  const d = String(now.getDate()).padStart(2, '0')
  const h = String(now.getHours()).padStart(2, '0')
  const min = String(now.getMinutes()).padStart(2, '0')
  const s = String(now.getSeconds()).padStart(2, '0')
  currentTimeStr.value = `${y}-${m}-${d} ${h}:${min}:${s}`
}

async function openBindMonitorDialog() {
  monitorDialogVisible.value = true
  selectedCameraId.value = ''
  try {
    const res = await api.getDevices()
    if (res.code === 200) {
      // 获取所有摄像头类型的设备（未绑定或绑定到当前地块的）
      allCameraDevices.value = (res.data || []).filter(
        (d) => d.type === 'camera' && (!d.fieldId || d.fieldId === Number(selectedFieldId.value))
      )
    }
  } catch {
    // 静默处理
  }
}

async function handleBindMonitor() {
  if (!selectedCameraId.value) return
  try {
    const res = await api.bindDevice(selectedCameraId.value, selectedFieldId.value)
    if (res.code === 200) {
      ElMessage.success('监控设备绑定成功')
      monitorDialogVisible.value = false
      await loadFieldData(selectedFieldId.value)
    }
  } catch {
    // 静默处理，不弹toast
  }
}

// ===== 侦听器 =====
watch(selectedFieldId, async (newId) => {
  if (newId) {
    await loadFieldData(newId)
  }
})

// ===== 天气预报 =====
function getWeatherIcon(condition) {
  const icons = { sunny: '☀️', cloudy: '⛅', rainy: '🌧️', storm: '⛈️', overcast: '☁️' }
  return icons[condition] || '☀️'
}

async function loadWeather() {
  weatherLoading.value = true
  try {
    const res = await api.getWeatherForecast()
    if (res.code === 200) {
      weatherData.value = res.data
    }
  } catch {
    // 静默处理
  } finally {
    weatherLoading.value = false
  }
}

// ===== 生命周期 =====
onMounted(async () => {
  await loadFields()
  // 从路由查询参数获取预选地块
  const queryFieldId = route.query.fieldId
  if (queryFieldId) {
    selectedFieldId.value = Number(queryFieldId)
  } else if (fields.value.length > 0) {
    selectedFieldId.value = fields.value[0].id
  }
  window.addEventListener('resize', handleResize)
  updateClock()
  clockTimer = setInterval(updateClock, 1000)
  loadWeather()
})

onUnmounted(() => {
  window.removeEventListener('resize', handleResize)
  if (clockTimer) { clearInterval(clockTimer); clockTimer = null }
  if (moistureChart) { moistureChart.dispose(); moistureChart = null }
  if (tempChart) { tempChart.dispose(); tempChart = null }
  if (humidityChart) { humidityChart.dispose(); humidityChart = null }
})
</script>

<style scoped>
/* ===== 地块选择器 ===== */
.selector-bar {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 20px;
}

.selector-label {
  font-size: 14px;
  font-weight: 600;
  color: var(--text-primary);
  white-space: nowrap;
}

/* ===== 实时数据卡片 ===== */
.realtime-cards {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 16px;
  margin-bottom: 24px;
}

.rt-card {
  background: var(--bg-card);
  border: 1px solid var(--border-color);
  border-radius: var(--border-radius);
  box-shadow: var(--shadow-sm);
  padding: 20px;
  transition: box-shadow 0.2s ease;
}

.rt-card:hover {
  box-shadow: var(--shadow-md);
}

.rt-card-header {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 16px;
}

.rt-card-icon {
  width: 40px;
  height: 40px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.rt-card-icon.moisture {
  background: #f0fdf4;
  color: #16a34a;
}

.rt-card-icon.temp {
  background: #fffbeb;
  color: #f59e0b;
}

.rt-card-icon.humidity {
  background: #eff6ff;
  color: #3b82f6;
}

.rt-card-title {
  font-size: 14px;
  font-weight: 600;
  color: var(--text-primary);
  flex: 1;
}

.rt-status-tag {
  flex-shrink: 0;
}

.rt-card-value {
  font-size: 32px;
  font-weight: 700;
  line-height: 1.2;
  margin-bottom: 12px;
}

.rt-card-unit {
  font-size: 16px;
  font-weight: 500;
  color: var(--text-tertiary);
  margin-left: 2px;
}

/* ===== 历史趋势图表 ===== */
.section {
  margin-bottom: 24px;
}

.section-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 16px;
}

.section-title {
  font-size: 16px;
  font-weight: 700;
  color: var(--text-primary);
  margin: 0;
}

.charts-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 16px;
}

.chart-box {
  background: var(--bg-card);
  border: 1px solid var(--border-color);
  border-radius: var(--border-radius);
  box-shadow: var(--shadow-sm);
  padding: 16px;
}

.chart-box-title {
  font-size: 13px;
  font-weight: 600;
  color: var(--text-secondary);
  margin-bottom: 8px;
}

.chart-box-container {
  height: 220px;
}

/* ===== 底部区域 ===== */
.bottom-section {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

.panel-card {
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

/* ===== 阈值表单 ===== */
.range-input {
  display: flex;
  align-items: center;
  gap: 8px;
}

.range-dash {
  color: var(--text-tertiary);
  font-size: 14px;
}

.range-unit {
  font-size: 13px;
  color: var(--text-secondary);
  margin-left: 2px;
}

.threshold-compare {
  margin-top: 16px;
  padding-top: 16px;
  border-top: 1px dashed var(--border-color);
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.compare-item {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 13px;
}

.compare-label {
  color: var(--text-secondary);
  width: 70px;
}

.compare-value {
  font-weight: 600;
  color: var(--text-primary);
}

/* ===== 设备列表 ===== */
.device-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
  min-height: 120px;
}

.device-item {
  padding: 14px;
  background: #f9fafb;
  border-radius: 8px;
  transition: background 0.2s ease;
}

.device-item:hover {
  background: #f3f4f6;
}

.device-item-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 10px;
}

.device-item-name {
  font-size: 14px;
  font-weight: 600;
  color: var(--text-primary);
}

.device-item-body {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.device-info-row {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  color: var(--text-secondary);
}

.device-info-label {
  color: var(--text-tertiary);
  width: 56px;
  flex-shrink: 0;
}

.device-info-value {
  color: var(--text-secondary);
}

.battery-bar {
  width: 80px;
  height: 8px;
  background: #f3f4f6;
  border-radius: 4px;
  overflow: hidden;
}

.battery-fill {
  height: 100%;
  border-radius: 4px;
  transition: width 0.3s ease;
}

.battery-fill.danger {
  background: var(--danger);
}

.battery-fill.warning {
  background: var(--warning);
}

.battery-fill.success {
  background: var(--success);
}

.battery-text {
  font-weight: 600;
  font-size: 13px;
}

.battery-text.danger {
  color: var(--danger);
}

.battery-text.warning {
  color: var(--warning);
}

.battery-text.success {
  color: var(--success);
}

/* ===== 实时监控 ===== */
.monitor-section {
  margin-bottom: 24px;
}

.monitor-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(360px, 1fr));
  gap: 16px;
}

.monitor-card {
  background: var(--bg-card);
  border: 1px solid var(--border-color);
  border-radius: var(--border-radius);
  box-shadow: var(--shadow-sm);
  overflow: hidden;
}

.monitor-screen {
  position: relative;
  width: 100%;
  height: 220px;
  background: #1a1a2e;
  display: flex;
  align-items: center;
  justify-content: center;
}

.monitor-placeholder {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  color: rgba(255, 255, 255, 0.3);
}

.monitor-placeholder .el-icon {
  font-size: 48px;
}

.monitor-placeholder-text {
  font-size: 14px;
  color: rgba(255, 255, 255, 0.6);
  font-weight: 500;
}

.monitor-placeholder-hint {
  font-size: 12px;
  color: rgba(255, 255, 255, 0.3);
}

.monitor-overlay {
  position: absolute;
  top: 8px;
  left: 8px;
  right: 8px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.monitor-time {
  font-size: 12px;
  color: rgba(255, 255, 255, 0.7);
  font-family: 'Courier New', monospace;
  background: rgba(0, 0, 0, 0.4);
  padding: 2px 8px;
  border-radius: 4px;
}

.monitor-badge {
  font-size: 12px;
  color: #ef4444;
  font-weight: 600;
  background: rgba(0, 0, 0, 0.4);
  padding: 2px 8px;
  border-radius: 4px;
  animation: blink-live 1.5s ease-in-out infinite;
}

@keyframes blink-live {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.5; }
}

.monitor-info {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 16px;
}

.monitor-device-name {
  font-size: 14px;
  font-weight: 600;
  color: var(--text-primary);
}

.monitor-empty {
  grid-column: 1 / -1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 12px;
  padding: 40px;
  background: var(--bg-card);
  border: 1px dashed var(--border-color);
  border-radius: var(--border-radius);
  color: var(--text-tertiary);
}

.monitor-empty-text {
  font-size: 14px;
  color: var(--text-secondary);
}

/* ===== 响应式 ===== */
@media (max-width: 1200px) {
  .realtime-cards {
    grid-template-columns: 1fr;
  }

  .charts-grid {
    grid-template-columns: 1fr;
  }

  .bottom-section {
    grid-template-columns: 1fr;
  }

  .monitor-grid {
    grid-template-columns: 1fr;
  }
}

/* ===== 天气预报 ===== */
.weather-section {
  margin-bottom: 24px;
}

.weather-update-time {
  font-size: 12px;
  color: var(--text-tertiary);
}

.weather-panel {
  display: grid;
  grid-template-columns: 1fr 2fr;
  gap: 20px;
  background: var(--bg-card);
  border: 1px solid var(--border-color);
  border-radius: var(--border-radius);
  padding: 24px;
  box-shadow: var(--shadow-sm);
}

/* 当前天气 */
.weather-current {
  display: flex;
  flex-direction: column;
  gap: 20px;
  border-right: 1px solid var(--border-color);
  padding-right: 20px;
}

.weather-current-main {
  display: flex;
  align-items: center;
  gap: 16px;
}

.weather-icon-large {
  font-size: 56px;
  line-height: 1;
}

.weather-temp-area {
  display: flex;
  flex-direction: column;
}

.weather-temp {
  font-size: 40px;
  font-weight: 700;
  color: var(--text-primary);
  line-height: 1;
}

.weather-condition {
  font-size: 16px;
  color: var(--text-secondary);
  margin-top: 4px;
}

.weather-current-details {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}

.weather-detail-item {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.weather-detail-label {
  font-size: 12px;
  color: var(--text-tertiary);
}

.weather-detail-value {
  font-size: 14px;
  font-weight: 600;
  color: var(--text-primary);
}

/* 5日预报 */
.weather-forecast {
  display: flex;
  gap: 8px;
  overflow-x: auto;
}

.forecast-item {
  flex: 1;
  min-width: 80px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
  padding: 14px 8px;
  background: var(--bg-page, #f9fafb);
  border-radius: 10px;
  transition: transform 0.2s ease;
}

.forecast-item:hover {
  transform: translateY(-2px);
}

.forecast-day {
  font-size: 13px;
  font-weight: 600;
  color: var(--text-primary);
}

.forecast-icon {
  font-size: 28px;
  line-height: 1;
}

.forecast-text {
  font-size: 12px;
  color: var(--text-secondary);
}

.forecast-temp {
  font-size: 13px;
  font-weight: 600;
  color: var(--text-primary);
}

.forecast-wind {
  font-size: 11px;
  color: var(--text-tertiary);
}

@media (max-width: 768px) {
  .weather-panel {
    grid-template-columns: 1fr;
  }

  .weather-current {
    border-right: none;
    border-bottom: 1px solid var(--border-color);
    padding-right: 0;
    padding-bottom: 20px;
  }
}
</style>
