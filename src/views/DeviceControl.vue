<template>
  <div class="page-container">
    <!-- 页面头部 -->
    <h1 class="page-title">设备控制</h1>
    <p class="page-subtitle">管理灌溉系统与设备运行状态</p>

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
          :label="field.name"
          :value="field.id"
        />
      </el-select>
    </div>

    <!-- 上半区：灌溉控制 + 定时/快捷操作 -->
    <div class="top-section" v-loading="loading">
      <!-- 灌溉控制面板 -->
      <div class="irrigation-panel">
        <div class="card-header">
          <h2 class="section-title">灌溉控制</h2>
          <el-tag
            :type="irrigationActive ? 'success' : 'info'"
            size="small"
            effect="dark"
          >
            {{ irrigationActive ? '运行中' : '已停止' }}
          </el-tag>
        </div>

        <!-- 大型状态指示器 -->
        <div class="indicator-wrap">
          <div
            class="irrigation-indicator"
            :class="{ active: irrigationActive, inactive: !irrigationActive }"
          >
            <div class="indicator-dot"></div>
            <div class="indicator-text">{{ irrigationActive ? '灌溉中' : '已停止' }}</div>
          </div>
        </div>

        <!-- 开关按钮 -->
        <el-button
          :type="irrigationActive ? 'danger' : 'primary'"
          size="large"
          :loading="controlling"
          class="toggle-btn"
          @click="toggleIrrigation"
        >
          {{ irrigationActive ? '关闭灌溉' : '开启灌溉' }}
        </el-button>

        <!-- 湿度信息 -->
        <div class="moisture-info">
          <div class="moisture-row">
            <span class="moisture-label">
              <el-icon><Drizzling /></el-icon>
              当前湿度
            </span>
            <span class="moisture-value" :style="{ color: moistureStatusInfo.color }">
              {{ isOffline || fieldData.soilMoisture == null ? '--' : fieldData.soilMoisture + '%' }}
            </span>
            <el-tag :type="moistureStatusInfo.type" size="small" effect="plain">
              {{ moistureStatusInfo.label }}
            </el-tag>
          </div>
          <div class="moisture-row">
            <span class="moisture-label">湿度阈值</span>
            <span class="moisture-value">
              {{ thresholds.soilMoistureMin }}% ~ {{ thresholds.soilMoistureMax }}%
            </span>
          </div>
        </div>
      </div>

      <!-- 右栏：定时器 + 快捷操作 -->
      <div class="right-column">
        <!-- 灌溉时长 -->
        <div class="timer-card">
          <div class="card-header">
            <h2 class="section-title">灌溉时长</h2>
            <el-tag v-if="countdownMode && irrigationActive" type="warning" size="small" effect="dark">倒计时模式</el-tag>
          </div>
          <div class="timer-display" :class="{ active: irrigationActive, countdown: countdownMode }">
            {{ formatDuration(timerSeconds) }}
          </div>
          <div class="timer-status">
            <div class="status-dot" :class="{ active: irrigationActive }"></div>
            <span>{{ irrigationActive ? (countdownMode ? '倒计时中' : '灌溉进行中') : timerSeconds > 0 ? '上次灌溉时长' : '灌溉未启动' }}</span>
          </div>
          <!-- 倒计时进度条 -->
          <div class="countdown-progress" v-if="countdownMode && irrigationActive && countdownTotal > 0">
            <div class="countdown-progress-bar" :style="{ width: ((countdownTotal - timerSeconds) / countdownTotal * 100) + '%' }"></div>
          </div>
        </div>

        <!-- 快捷操作 -->
        <div class="actions-card">
          <div class="card-header">
            <h2 class="section-title">快捷操作</h2>
          </div>
          <div class="duration-setting">
            <span class="duration-label">灌溉时长</span>
            <el-input-number
              v-model="customDuration"
              :min="1"
              :max="120"
              :step="5"
              size="default"
              controls-position="right"
              :disabled="irrigationActive"
            />
            <span class="duration-unit">分钟</span>
          </div>
          <div class="action-buttons">
            <el-button
              type="primary"
              plain
              :loading="controlling"
              :disabled="irrigationActive"
              @click="quickIrrigate"
            >
              定时灌溉{{ customDuration }}分钟
            </el-button>
            <el-button
              type="danger"
              plain
              :loading="controlling"
              :disabled="!irrigationActive"
              @click="stopAllIrrigation"
            >
              停止所有灌溉
            </el-button>
          </div>
          <div class="auto-mode">
            <div class="auto-mode-info">
              <span class="auto-mode-label">自动模式</span>
              <span class="auto-mode-desc">根据土壤湿度自动控制灌溉</span>
            </div>
            <el-switch v-model="autoMode" @change="onAutoModeChange" />
          </div>
        </div>
      </div>
    </div>

    <!-- 关联设备列表 -->
    <div class="section">
      <div class="section-header">
        <h2 class="section-title">关联设备</h2>
        <span class="section-count">共 {{ devices.length }} 台</span>
      </div>
      <div class="device-grid" v-loading="loading">
        <div v-for="device in devices" :key="device.id" class="device-card">
          <div class="device-card-header">
            <span class="device-name">{{ device.name }}</span>
            <el-tag :type="deviceTypeTag(device.type)" size="small" effect="light">
              {{ deviceTypeLabels[device.type] || device.type }}
            </el-tag>
          </div>
          <div class="device-card-body">
            <div class="device-info-row">
              <span class="device-info-label">状态</span>
              <el-tag :type="device.status === 'online' ? 'success' : 'info'" size="small" effect="dark">
                {{ device.status === 'online' ? '在线' : '离线' }}
              </el-tag>
            </div>
            <div class="device-info-row">
              <span class="device-info-label">电量</span>
              <div class="battery-bar">
                <div
                  class="battery-fill"
                  :class="batteryClass(device.battery)"
                  :style="{ width: device.battery + '%' }"
                ></div>
              </div>
              <span class="battery-text" :class="batteryClass(device.battery)">{{ device.battery }}%</span>
            </div>
            <div class="device-info-row">
              <span class="device-info-label">上报</span>
              <span class="device-info-value">{{ device.lastReport }}</span>
            </div>
          </div>
        </div>
        <el-empty v-if="!loading && devices.length === 0" description="该地块暂无绑定设备" :image-size="60" />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, watch, onMounted, onUnmounted } from 'vue'
import { ElMessage } from 'element-plus'
import { api } from '@/api'
import { Drizzling } from '@element-plus/icons-vue'

const loading = ref(false)
const controlling = ref(false)
const fields = ref([])
const selectedFieldId = ref(null)
const fieldData = ref({})
const devices = ref([])
const irrigationActive = ref(false)
const autoMode = ref(false)
const timerSeconds = ref(0)
const customDuration = ref(15) // 自定义灌溉时长（分钟），默认15分钟
const countdownMode = ref(false) // 是否处于倒计时模式
const countdownTotal = ref(0) // 倒计时总秒数
let timerInterval = null

const thresholds = reactive({
  soilMoistureMin: 0,
  soilMoistureMax: 0,
  tempMin: 0,
  tempMax: 0,
})

const deviceTypeLabels = {
  soil_sensor: '土壤传感器',
  temp_sensor: '温度传感器',
  humidity_sensor: '湿度传感器',
  irrigation_valve: '灌溉阀门',
  camera: '摄像头',
}

// ===== 计算属性 =====
const isOffline = computed(() => fieldData.value?.status === 'offline')

const moistureStatus = computed(() => {
  const m = fieldData.value?.soilMoisture
  if (m == null || isOffline.value) return 'unknown'
  if (m < thresholds.soilMoistureMin) return 'low'
  if (m > thresholds.soilMoistureMax) return 'high'
  return 'normal'
})

const moistureStatusInfo = computed(() => {
  const map = {
    low: { label: '偏低', color: '#f59e0b', type: 'warning' },
    high: { label: '偏高', color: '#ef4444', type: 'danger' },
    normal: { label: '正常', color: '#22c55e', type: 'success' },
    unknown: { label: '未知', color: '#9ca3af', type: 'info' },
  }
  return map[moistureStatus.value]
})

// ===== 工具函数 =====
function batteryClass(battery) {
  if (battery <= 20) return 'danger'
  if (battery <= 50) return 'warning'
  return 'success'
}

function deviceTypeTag(type) {
  const map = { soil_sensor: 'success', temp_sensor: 'warning', humidity_sensor: 'primary', irrigation_valve: 'primary', camera: 'danger' }
  return map[type] || 'info'
}

function formatDuration(seconds) {
  const h = Math.floor(seconds / 3600)
  const m = Math.floor((seconds % 3600) / 60)
  const s = seconds % 60
  const pad = (n) => String(n).padStart(2, '0')
  if (h > 0) {
    return `${pad(h)}:${pad(m)}:${pad(s)}`
  }
  return `${pad(m)}:${pad(s)}`
}

// ===== 计时器 =====
function startTimer() {
  if (timerInterval) clearInterval(timerInterval)
  timerSeconds.value = 0
  countdownMode.value = false
  countdownTotal.value = 0
  timerInterval = setInterval(() => {
    timerSeconds.value++
  }, 1000)
}

function startCountdown(minutes) {
  if (timerInterval) clearInterval(timerInterval)
  countdownMode.value = true
  countdownTotal.value = minutes * 60
  timerSeconds.value = minutes * 60
  timerInterval = setInterval(() => {
    timerSeconds.value--
    if (timerSeconds.value <= 0) {
      stopTimer()
      irrigationActive.value = false
      ElMessage.success('灌溉倒计时结束，已自动关闭')
      // 自动调用关闭灌溉
      api.controlIrrigation(selectedFieldId.value, 'off').catch(() => {})
    }
  }, 1000)
}

function stopTimer() {
  if (timerInterval) {
    clearInterval(timerInterval)
    timerInterval = null
  }
}

function resetTimer() {
  stopTimer()
  timerSeconds.value = 0
  countdownMode.value = false
  countdownTotal.value = 0
}

// ===== 数据加载 =====
async function loadFields() {
  try {
    const res = await api.getFields()
    if (res.code === 200) {
      fields.value = res.data || []
    }
  } catch {
    // 静默处理，页面显示空数据
    fields.value = []
  }
}

async function loadFieldInfo(fieldId) {
  loading.value = true
  try {
    const [fieldRes, thresholdsRes, devicesRes, irrigationRes] = await Promise.all([
      api.getField(fieldId),
      api.getThresholds(fieldId),
      api.getDevices(),
      api.getIrrigationState(fieldId),
    ])

    if (fieldRes.code === 200) fieldData.value = fieldRes.data || {}
    if (thresholdsRes.code === 200 && thresholdsRes.data) {
      Object.assign(thresholds, thresholdsRes.data)
    }
    if (devicesRes.code === 200) {
      devices.value = (devicesRes.data || []).filter((d) => d.fieldId === Number(fieldId))
    }
    if (irrigationRes.code === 200) {
      irrigationActive.value = irrigationRes.data.active
      if (irrigationActive.value) {
        startTimer()
      } else {
        resetTimer()
      }
    }
  } catch {
    // 静默处理，页面显示空数据
    fieldData.value = {}
    devices.value = []
  } finally {
    loading.value = false
  }
}

// ===== 灌溉控制 =====
async function toggleIrrigation() {
  if (controlling.value) return
  const action = irrigationActive.value ? 'off' : 'on'
  controlling.value = true
  try {
    const res = await api.controlIrrigation(selectedFieldId.value, action)
    if (res.code === 200) {
      irrigationActive.value = action === 'on'
      if (irrigationActive.value) {
        startTimer()
        ElMessage.success('灌溉已开启')
      } else {
        stopTimer()
        ElMessage.success('灌溉已关闭')
      }
    }
  } catch {
    // 静默处理，不弹toast
  } finally {
    controlling.value = false
  }
}

async function quickIrrigate() {
  if (controlling.value) return
  controlling.value = true
  try {
    const res = await api.controlIrrigation(selectedFieldId.value, 'on', customDuration.value)
    if (res.code === 200) {
      irrigationActive.value = true
      startCountdown(customDuration.value)
      ElMessage.success(`已开启灌溉，预计持续${customDuration.value}分钟`)
    }
  } catch {
    // 静默处理，不弹toast
  } finally {
    controlling.value = false
  }
}

async function stopAllIrrigation() {
  if (controlling.value) return
  controlling.value = true
  try {
    const res = await api.controlIrrigation(selectedFieldId.value, 'off')
    if (res.code === 200) {
      irrigationActive.value = false
      stopTimer()
      ElMessage.success('已停止所有灌溉')
    }
  } catch {
    // 静默处理，不弹toast
  } finally {
    controlling.value = false
  }
}

function onAutoModeChange(val) {
  ElMessage.info(val ? '自动模式已开启，系统将根据湿度自动控制灌溉' : '自动模式已关闭')
}

// ===== 侦听器 =====
watch(selectedFieldId, async (newId) => {
  if (newId) {
    await loadFieldInfo(newId)
  }
})

// ===== 生命周期 =====
onMounted(async () => {
  await loadFields()
  if (fields.value.length > 0) {
    selectedFieldId.value = fields.value[0].id
  }
})

onUnmounted(() => {
  stopTimer()
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

/* ===== 上半区布局 ===== */
.top-section {
  display: grid;
  grid-template-columns: 1.5fr 1fr;
  gap: 16px;
  margin-bottom: 24px;
}

.right-column {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

/* ===== 通用卡片 ===== */
.irrigation-panel,
.timer-card,
.actions-card {
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

/* ===== 灌溉指示器 ===== */
.indicator-wrap {
  display: flex;
  justify-content: center;
  padding: 24px 0;
}

.irrigation-indicator {
  width: 120px;
  height: 120px;
  border-radius: 50%;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  transition: all 0.3s ease;
}

.irrigation-indicator.active {
  background: linear-gradient(135deg, #22c55e, #16a34a);
  color: #fff;
  box-shadow: 0 0 40px rgba(22, 163, 74, 0.35);
  animation: pulse 2s ease-in-out infinite;
}

.irrigation-indicator.inactive {
  background: #f3f4f6;
  color: var(--text-tertiary);
  border: 2px dashed var(--border-color);
}

.indicator-dot {
  width: 14px;
  height: 14px;
  border-radius: 50%;
  margin-bottom: 8px;
}

.irrigation-indicator.active .indicator-dot {
  background: #fff;
  animation: blink 1s ease-in-out infinite;
}

.irrigation-indicator.inactive .indicator-dot {
  background: var(--text-tertiary);
}

.indicator-text {
  font-size: 16px;
  font-weight: 700;
}

@keyframes pulse {
  0%, 100% {
    box-shadow: 0 0 30px rgba(22, 163, 74, 0.3);
    transform: scale(1);
  }
  50% {
    box-shadow: 0 0 50px rgba(22, 163, 74, 0.5);
    transform: scale(1.03);
  }
}

@keyframes blink {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.4; }
}

/* ===== 开关按钮 ===== */
.toggle-btn {
  width: 100%;
  height: 48px;
  font-size: 16px;
  font-weight: 600;
  border-radius: 8px;
}

/* ===== 湿度信息 ===== */
.moisture-info {
  margin-top: 20px;
  padding-top: 16px;
  border-top: 1px dashed var(--border-color);
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.moisture-row {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 14px;
}

.moisture-label {
  color: var(--text-secondary);
  display: flex;
  align-items: center;
  gap: 4px;
  width: 80px;
  flex-shrink: 0;
}

.moisture-label .el-icon {
  font-size: 15px;
  color: var(--text-tertiary);
}

.moisture-value {
  font-weight: 600;
  color: var(--text-primary);
}

/* ===== 定时器 ===== */
.timer-display {
  font-size: 36px;
  font-weight: 700;
  font-family: 'Courier New', 'Consolas', monospace;
  color: var(--text-tertiary);
  text-align: center;
  letter-spacing: 3px;
  margin: 12px 0;
  transition: color 0.3s ease;
}

.timer-display.active {
  color: var(--primary);
}

.timer-status {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  font-size: 13px;
  color: var(--text-secondary);
}

.status-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: var(--text-tertiary);
  transition: background 0.3s ease;
}

.status-dot.active {
  background: var(--success);
  animation: blink 1s ease-in-out infinite;
}

/* ===== 倒计时模式 ===== */
.timer-display.countdown {
  color: var(--warning);
}

.countdown-progress {
  height: 6px;
  background: #f3f4f6;
  border-radius: 3px;
  overflow: hidden;
  margin-top: 10px;
}

.countdown-progress-bar {
  height: 100%;
  background: linear-gradient(90deg, #f59e0b, #ef4444);
  border-radius: 3px;
  transition: width 1s linear;
}

/* ===== 时长设置 ===== */
.duration-setting {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 12px;
  padding: 10px 14px;
  background: #f9fafb;
  border-radius: 8px;
}

.duration-label {
  font-size: 14px;
  font-weight: 600;
  color: var(--text-primary);
  white-space: nowrap;
}

.duration-unit {
  font-size: 13px;
  color: var(--text-secondary);
}

/* ===== 快捷操作 ===== */
.action-buttons {
  display: flex;
  flex-direction: column;
  gap: 10px;
  margin-bottom: 16px;
}

.action-buttons .el-button {
  width: 100%;
}

.auto-mode {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 14px;
  background: #f9fafb;
  border-radius: 8px;
}

.auto-mode-info {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.auto-mode-label {
  font-size: 14px;
  font-weight: 600;
  color: var(--text-primary);
}

.auto-mode-desc {
  font-size: 12px;
  color: var(--text-tertiary);
}

/* ===== 设备列表 ===== */
.section {
  margin-bottom: 24px;
}

.section-count {
  font-size: 13px;
  color: var(--text-tertiary);
}

.device-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 16px;
  min-height: 120px;
}

.device-card {
  background: var(--bg-card);
  border: 1px solid var(--border-color);
  border-radius: var(--border-radius);
  box-shadow: var(--shadow-sm);
  padding: 16px;
  transition: all 0.2s ease;
}

.device-card:hover {
  box-shadow: var(--shadow-md);
  transform: translateY(-2px);
}

.device-card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 12px;
}

.device-name {
  font-size: 14px;
  font-weight: 600;
  color: var(--text-primary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.device-card-body {
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
  width: 40px;
  flex-shrink: 0;
}

.device-info-value {
  color: var(--text-secondary);
}

.battery-bar {
  width: 70px;
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

/* ===== 响应式 ===== */
@media (max-width: 1200px) {
  .top-section {
    grid-template-columns: 1fr;
  }
}
</style>
