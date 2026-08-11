<template>
  <div class="page-container field-manage">
    <!-- 汇总统计 -->
    <div class="stats-row">
      <div class="stat-card">
        <div class="stat-icon area">
          <el-icon :size="22"><Odometer /></el-icon>
        </div>
        <div class="stat-body">
          <div class="stat-value">{{ summary.totalArea }}<span class="stat-unit">亩</span></div>
          <div class="stat-label">总面积</div>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon total">
          <el-icon :size="22"><Location /></el-icon>
        </div>
        <div class="stat-body">
          <div class="stat-value">{{ summary.totalFields }}</div>
          <div class="stat-label">地块总数</div>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon normal">
          <el-icon :size="22"><CircleCheckFilled /></el-icon>
        </div>
        <div class="stat-body">
          <div class="stat-value">{{ summary.normalCount }}</div>
          <div class="stat-label">正常地块</div>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon warning">
          <el-icon :size="22"><WarningFilled /></el-icon>
        </div>
        <div class="stat-body">
          <div class="stat-value">{{ summary.warningCount }}</div>
          <div class="stat-label">异常地块</div>
        </div>
      </div>
    </div>

    <!-- 操作栏 -->
    <div class="action-bar">
      <div class="action-title">
        <span class="title-text">农田列表</span>
        <span class="title-count">共 {{ fields.length }} 块农田</span>
      </div>
      <div class="action-btns">
        <el-button type="primary" :icon="Plus" @click="openAddDialog">新增农田</el-button>
        <el-button :icon="Refresh" @click="loadData">刷新数据</el-button>
      </div>
    </div>

    <!-- 农田卡片网格 -->
    <div v-loading="loading" class="field-grid">
      <el-empty v-if="!loading && fields.length === 0" description="暂无农田数据" />
      <div
        v-for="field in fields"
        :key="field.id"
        class="field-card"
        :class="field.status"
        @click="openDetail(field)"
      >
        <!-- 状态条 -->
        <div class="field-status-bar" :class="field.status"></div>

        <div class="field-card-body">
          <!-- 头部 -->
          <div class="field-card-header">
            <div class="field-name">
              <el-icon><Location /></el-icon>
              <span>{{ field.name }}</span>
            </div>
            <span class="status-badge" :class="field.status">
              {{ statusConfig[field.status]?.label }}
            </span>
          </div>

          <!-- 作物与面积 -->
          <div class="field-meta">
            <div class="meta-item">
              <el-icon><Coin /></el-icon>
              <span>作物：{{ field.crop }}</span>
            </div>
            <div class="meta-item">
              <el-icon><Odometer /></el-icon>
              <span>面积：{{ field.area }} 亩</span>
            </div>
          </div>

          <!-- 实时数据 -->
          <div class="field-data">
            <div class="data-block">
              <div class="data-label">土壤湿度</div>
              <div class="data-value" :class="moistureClass(field.soilMoisture, field.status)">
                {{ field.status === 'offline' ? '--' : field.soilMoisture + '%' }}
              </div>
              <div class="data-bar">
                <div class="data-bar-fill" :class="moistureClass(field.soilMoisture, field.status)"
                  :style="{ width: (field.status === 'offline' ? 0 : field.soilMoisture) + '%' }">
                </div>
              </div>
            </div>
            <div class="data-block">
              <div class="data-label">温度</div>
              <div class="data-value" :class="tempClass(field.temperature, field.status)">
                {{ field.status === 'offline' ? '--' : field.temperature + '°C' }}
              </div>
              <div class="data-bar">
                <div class="data-bar-fill temp" :class="tempClass(field.temperature, field.status)"
                  :style="{ width: (field.status === 'offline' ? 0 : Math.min(field.temperature / 40 * 100, 100)) + '%' }">
                </div>
              </div>
            </div>
          </div>

          <!-- 底部 -->
          <div class="field-card-footer">
            <span class="device-count">
              <el-icon><Cpu /></el-icon>
              {{ getDeviceCount(field.id) }} 台设备
            </span>
            <div class="footer-actions">
              <el-button type="danger" text size="small" :icon="Delete" @click.stop="handleDeleteField(field)">
                删除
              </el-button>
              <span class="view-detail">
                查看详情
                <el-icon><ArrowRight /></el-icon>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 农田详情对话框 -->
    <el-dialog
      v-model="detailDialogVisible"
      :title="currentField ? currentField.name + ' - 农田详情' : '农田详情'"
      width="720px"
      :close-on-click-modal="false"
      class="detail-dialog"
    >
      <div v-if="currentField" class="detail-content">
        <!-- 基本信息 -->
        <div class="detail-section">
          <div class="section-title">
            <el-icon><InfoFilled /></el-icon>
            基本信息
          </div>
          <el-descriptions :column="2" border>
            <el-descriptions-item label="地块名称">{{ currentField.name }}</el-descriptions-item>
            <el-descriptions-item label="种植作物">{{ currentField.crop }}</el-descriptions-item>
            <el-descriptions-item label="地块面积">{{ currentField.area }} 亩</el-descriptions-item>
            <el-descriptions-item label="当前状态">
              <el-tag :type="statusTagType(currentField.status)" size="small" effect="dark">
                {{ statusConfig[currentField.status]?.label }}
              </el-tag>
            </el-descriptions-item>
          </el-descriptions>
        </div>

        <!-- 实时数据 -->
        <div class="detail-section">
          <div class="section-title">
            <el-icon><Monitor /></el-icon>
            实时数据
          </div>
          <div class="metric-cards">
            <div class="metric-card moisture">
              <div class="metric-value">{{ currentField.status === 'offline' ? '--' : currentField.soilMoisture + '%' }}</div>
              <div class="metric-label">土壤湿度</div>
            </div>
            <div class="metric-card temp">
              <div class="metric-value">{{ currentField.status === 'offline' ? '--' : currentField.temperature + '°C' }}</div>
              <div class="metric-label">环境温度</div>
            </div>
            <div class="metric-card humidity">
              <div class="metric-value">{{ currentField.status === 'offline' ? '--' : currentField.humidity + '%' }}</div>
              <div class="metric-label">空气湿度</div>
            </div>
          </div>
        </div>

        <!-- 关联设备 -->
        <div class="detail-section">
          <div class="section-title">
            <el-icon><Cpu /></el-icon>
            关联设备
            <span class="section-count">({{ fieldDevices.length }} 台)</span>
          </div>
          <el-table
            :data="fieldDevices"
            stripe
            size="small"
            style="width: 100%"
            :header-cell-style="{ background: '#f9fafb', color: '#374151', fontWeight: 600 }"
          >
            <el-table-column label="设备名称" prop="name" min-width="150" />
            <el-table-column label="类型" width="120" align="center">
              <template #default="{ row }">
                <el-tag size="small" effect="light" :type="deviceTypeTag(row.type)">
                  {{ deviceTypeLabel(row.type) }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column label="状态" width="90" align="center">
              <template #default="{ row }">
                <el-tag :type="row.status === 'online' ? 'success' : 'info'" size="small" effect="dark">
                  {{ row.status === 'online' ? '在线' : '离线' }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column label="电量" width="80" align="center">
              <template #default="{ row }">{{ row.battery }}%</template>
            </el-table-column>
            <el-table-column label="最近上报" prop="lastReport" width="170" />
          </el-table>
          <el-empty v-if="fieldDevices.length === 0" description="暂无关联设备" :image-size="60" />
        </div>

        <!-- 阈值设置 -->
        <div class="detail-section">
          <div class="section-title">
            <el-icon><Setting /></el-icon>
            阈值设置
          </div>
          <el-form :model="thresholdForm" label-width="110px" v-loading="thresholdLoading" class="threshold-form">
            <div class="threshold-row">
              <el-form-item label="土壤湿度下限">
                <el-input-number v-model="thresholdForm.soilMoistureMin" :min="0" :max="100" controls-position="right" />
                <span class="threshold-unit">%</span>
              </el-form-item>
              <el-form-item label="土壤湿度上限">
                <el-input-number v-model="thresholdForm.soilMoistureMax" :min="0" :max="100" controls-position="right" />
                <span class="threshold-unit">%</span>
              </el-form-item>
            </div>
            <div class="threshold-row">
              <el-form-item label="温度下限">
                <el-input-number v-model="thresholdForm.tempMin" :min="-20" :max="50" controls-position="right" />
                <span class="threshold-unit">°C</span>
              </el-form-item>
              <el-form-item label="温度上限">
                <el-input-number v-model="thresholdForm.tempMax" :min="-20" :max="50" controls-position="right" />
                <span class="threshold-unit">°C</span>
              </el-form-item>
            </div>
            <div class="threshold-actions">
              <el-button type="primary" :icon="Check" :loading="thresholdSaving" @click="saveThresholds">
                保存阈值
              </el-button>
            </div>
          </el-form>
        </div>
      </div>
    </el-dialog>

    <!-- 新增农田对话框 -->
    <el-dialog v-model="addDialogVisible" title="新增农田" width="480px" :close-on-click-modal="false">
      <el-form
        ref="addFieldFormRef"
        :model="addFieldForm"
        :rules="addFieldRules"
        label-width="90px"
      >
        <el-form-item label="农田名称" prop="name">
          <el-input v-model="addFieldForm.name" placeholder="请输入农田名称" />
        </el-form-item>
        <el-form-item label="种植作物" prop="crop">
          <el-input v-model="addFieldForm.crop" placeholder="请输入作物名称" />
        </el-form-item>
        <el-form-item label="农田面积" prop="area">
          <el-input-number v-model="addFieldForm.area" :min="1" :max="99999" controls-position="right" />
          <span class="area-unit">亩</span>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="addDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="addLoading" @click="handleAddField">确定添加</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  Location, Coin, Odometer, Cpu, ArrowRight, Refresh, Monitor,
  Setting, Check, InfoFilled, CircleCheckFilled, WarningFilled,
  Plus, Delete,
} from '@element-plus/icons-vue'
import { api } from '@/api'

const deviceTypeLabels = {
  soil_sensor: '土壤传感器',
  temp_sensor: '温度传感器',
  humidity_sensor: '湿度传感器',
  irrigation_valve: '灌溉阀门',
  camera: '摄像头',
}

// 根据 type 获取显示名称，自定义类型直接返回 type 本身
function deviceTypeLabel(type) {
  return deviceTypeLabels[type] || type
}

const statusConfig = {
  normal: { label: '正常', color: '#22c55e' },
  warning: { label: '预警', color: '#f59e0b' },
  danger: { label: '告警', color: '#ef4444' },
  offline: { label: '离线', color: '#9ca3af' },
}

const loading = ref(false)
const fields = ref([])
const devices = ref([])

// ===== 新增农田 =====
const addDialogVisible = ref(false)
const addLoading = ref(false)
const addFieldFormRef = ref()
const addFieldForm = reactive({
  name: '',
  crop: '',
  area: 1000,
})
const addFieldRules = {
  name: [{ required: true, message: '请输入农田名称', trigger: 'blur' }],
  crop: [{ required: true, message: '请输入作物名称', trigger: 'blur' }],
  area: [{ required: true, message: '请输入农田面积', trigger: 'blur' }],
}

// 汇总统计
const summary = computed(() => ({
  totalArea: fields.value.reduce((sum, f) => sum + f.area, 0),
  totalFields: fields.value.length,
  normalCount: fields.value.filter((f) => f.status === 'normal').length,
  warningCount: fields.value.filter((f) => f.status !== 'normal').length,
}))

// 每个地块的设备数量
function getDeviceCount(fieldId) {
  return devices.value.filter((d) => d.fieldId === fieldId).length
}

// 湿度样式
function moistureClass(moisture, status) {
  if (status === 'offline') return 'offline'
  if (moisture < 25) return 'danger'
  if (moisture < 35) return 'warning'
  return 'normal'
}

// 温度样式
function tempClass(temp, status) {
  if (status === 'offline') return 'offline'
  if (temp > 33) return 'danger'
  if (temp > 30) return 'warning'
  return 'normal'
}

// 状态标签类型
function statusTagType(status) {
  const map = { normal: 'success', warning: 'warning', danger: 'danger', offline: 'info' }
  return map[status] || 'info'
}

// 设备类型标签
function deviceTypeTag(type) {
  const map = { soil_sensor: 'success', temp_sensor: 'warning', humidity_sensor: 'primary', irrigation_valve: 'primary', camera: 'danger' }
  return map[type] || 'info'
}

// ===== 详情对话框 =====
const detailDialogVisible = ref(false)
const currentField = ref(null)
const thresholdLoading = ref(false)
const thresholdSaving = ref(false)

const thresholdForm = reactive({
  soilMoistureMin: 30,
  soilMoistureMax: 80,
  tempMin: 5,
  tempMax: 35,
})

const fieldDevices = computed(() => {
  if (!currentField.value) return []
  return devices.value.filter((d) => d.fieldId === currentField.value.id)
})

async function openDetail(field) {
  currentField.value = field
  detailDialogVisible.value = true
  await loadThresholds(field.id)
}

async function loadThresholds(fieldId) {
  thresholdLoading.value = true
  try {
    const res = await api.getThresholds(fieldId)
    if (res.code === 200 && res.data) {
      thresholdForm.soilMoistureMin = res.data.soilMoistureMin
      thresholdForm.soilMoistureMax = res.data.soilMoistureMax
      thresholdForm.tempMin = res.data.tempMin
      thresholdForm.tempMax = res.data.tempMax
    }
  } catch {
    // 静默处理
  } finally {
    thresholdLoading.value = false
  }
}

async function saveThresholds() {
  if (!currentField.value) return
  thresholdSaving.value = true
  try {
    const res = await api.updateThresholds(currentField.value.id, { ...thresholdForm })
    if (res.code === 200) {
      ElMessage.success('阈值设置已保存')
    }
  } catch {
    // 静默处理，不弹toast
  } finally {
    thresholdSaving.value = false
  }
}

function openAddDialog() {
  addFieldForm.name = ''
  addFieldForm.crop = ''
  addFieldForm.area = 1000
  addDialogVisible.value = true
}

async function handleAddField() {
  if (!addFieldFormRef.value) return
  await addFieldFormRef.value.validate(async (valid) => {
    if (!valid) return
    addLoading.value = true
    try {
      const res = await api.addField({
        name: addFieldForm.name,
        crop: addFieldForm.crop,
        area: addFieldForm.area,
      })
      if (res.code === 200) {
        ElMessage.success('农田添加成功')
        addDialogVisible.value = false
        await loadData()
      }
    } catch {
      // 静默处理，不弹toast
    } finally {
      addLoading.value = false
    }
  })
}

async function handleDeleteField(field) {
  try {
    await ElMessageBox.confirm(
      `确定要删除农田「${field.name}」吗？该农田上的设备将自动解绑。`,
      '删除确认',
      { confirmButtonText: '确定删除', cancelButtonText: '取消', type: 'warning' },
    )
    const res = await api.deleteField(field.id)
    if (res.code === 200) {
      ElMessage.success('农田已删除')
      await loadData()
    }
  } catch (err) {
    if (err !== 'cancel') {
      // 静默处理，不弹toast
    }
  }
}

// ===== 数据加载 =====
async function loadData() {
  loading.value = true
  try {
    const [fieldsRes, devicesRes] = await Promise.all([
      api.getFields(),
      api.getDevices(),
    ])
    if (fieldsRes.code === 200) {
      fields.value = fieldsRes.data || []
    }
    if (devicesRes.code === 200) {
      devices.value = devicesRes.data || []
    }
  } catch {
    // 静默处理，页面显示空数据
    fields.value = []
    devices.value = []
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadData()
})
</script>

<style scoped>
.field-manage {
  padding: 20px 24px;
}

/* ===== 汇总统计 ===== */
.stats-row {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
  margin-bottom: 20px;
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
  transition: box-shadow 0.2s ease;
}

.stat-card:hover {
  box-shadow: var(--shadow-md);
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

.stat-icon.area {
  background: #eff6ff;
  color: #2563eb;
}

.stat-icon.total {
  background: var(--primary-bg);
  color: var(--primary);
}

.stat-icon.normal {
  background: var(--primary-bg);
  color: var(--success);
}

.stat-icon.warning {
  background: #fffbeb;
  color: var(--warning);
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
  color: var(--text-secondary);
  margin-left: 2px;
}

.stat-label {
  font-size: 13px;
  color: var(--text-secondary);
  margin-top: 2px;
}

/* ===== 操作栏 ===== */
.action-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 16px;
}

.action-title {
  display: flex;
  align-items: baseline;
  gap: 10px;
}

.title-text {
  font-size: 16px;
  font-weight: 600;
  color: var(--text-primary);
}

.title-count {
  font-size: 13px;
  color: var(--text-tertiary);
}

.action-btns {
  display: flex;
  gap: 8px;
}

/* ===== 农田卡片网格 ===== */
.field-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(340px, 1fr));
  gap: 16px;
  min-height: 200px;
}

.field-card {
  background: var(--bg-card);
  border: 1px solid var(--border-color);
  border-radius: var(--border-radius);
  box-shadow: var(--shadow-sm);
  overflow: hidden;
  cursor: pointer;
  transition: all 0.25s ease;
}

.field-card:hover {
  box-shadow: var(--shadow-lg);
  transform: translateY(-3px);
  border-color: #bbf7d0;
}

.field-status-bar {
  height: 4px;
  width: 100%;
}

.field-status-bar.normal {
  background: var(--success);
}

.field-status-bar.warning {
  background: var(--warning);
}

.field-status-bar.danger {
  background: var(--danger);
}

.field-status-bar.offline {
  background: var(--text-tertiary);
}

.field-card-body {
  padding: 16px;
}

.field-card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 14px;
}

.field-name {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 15px;
  font-weight: 600;
  color: var(--text-primary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.field-name .el-icon {
  color: var(--primary);
  flex-shrink: 0;
}

.status-badge {
  display: inline-block;
  padding: 3px 10px;
  border-radius: 12px;
  font-size: 12px;
  font-weight: 500;
  flex-shrink: 0;
}

.status-badge.normal {
  background: #f0fdf4;
  color: #16a34a;
}

.status-badge.warning {
  background: #fffbeb;
  color: #d97706;
}

.status-badge.danger {
  background: #fef2f2;
  color: #dc2626;
}

.status-badge.offline {
  background: #f3f4f6;
  color: #6b7280;
}

.field-meta {
  display: flex;
  gap: 20px;
  margin-bottom: 16px;
  padding-bottom: 14px;
  border-bottom: 1px solid var(--border-color);
}

.meta-item {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
  color: var(--text-secondary);
}

.meta-item .el-icon {
  color: var(--text-tertiary);
  font-size: 15px;
}

.field-data {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
  margin-bottom: 16px;
}

.data-block {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.data-label {
  font-size: 12px;
  color: var(--text-tertiary);
}

.data-value {
  font-size: 22px;
  font-weight: 700;
  line-height: 1.2;
}

.data-value.normal {
  color: var(--success);
}

.data-value.warning {
  color: var(--warning);
}

.data-value.danger {
  color: var(--danger);
}

.data-value.offline {
  color: var(--text-tertiary);
}

.data-bar {
  height: 6px;
  background: #f3f4f6;
  border-radius: 3px;
  overflow: hidden;
}

.data-bar-fill {
  height: 100%;
  border-radius: 3px;
  transition: width 0.3s ease;
}

.data-bar-fill.normal {
  background: var(--success);
}

.data-bar-fill.warning {
  background: var(--warning);
}

.data-bar-fill.danger {
  background: var(--danger);
}

.data-bar-fill.offline {
  background: var(--text-tertiary);
}

.data-bar-fill.temp.normal {
  background: var(--success);
}

.data-bar-fill.temp.warning {
  background: var(--warning);
}

.data-bar-fill.temp.danger {
  background: var(--danger);
}

.data-bar-fill.temp.offline {
  background: var(--text-tertiary);
}

.field-card-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding-top: 14px;
  border-top: 1px solid var(--border-color);
}

.device-count {
  display: flex;
  align-items: center;
  gap: 5px;
  font-size: 13px;
  color: var(--text-secondary);
}

.device-count .el-icon {
  color: var(--text-tertiary);
}

.footer-actions {
  display: flex;
  align-items: center;
  gap: 12px;
}

.view-detail {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 13px;
  color: var(--primary);
  font-weight: 500;
  transition: gap 0.2s ease;
}

.field-card:hover .view-detail {
  gap: 8px;
}

/* ===== 详情对话框 ===== */
.detail-dialog :deep(.el-dialog__body) {
  padding: 0 24px 20px;
  max-height: 70vh;
  overflow-y: auto;
}

.detail-content {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.detail-section {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.section-title {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 15px;
  font-weight: 600;
  color: var(--text-primary);
  padding-bottom: 8px;
  border-bottom: 1px solid var(--border-color);
}

.section-title .el-icon {
  color: var(--primary);
}

.section-count {
  font-size: 13px;
  font-weight: 400;
  color: var(--text-tertiary);
}

/* 实时数据卡片 */
.metric-cards {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 12px;
}

.metric-card {
  padding: 20px;
  border-radius: var(--border-radius);
  text-align: center;
  border: 1px solid var(--border-color);
}

.metric-card.moisture {
  background: linear-gradient(135deg, #eff6ff, #dbeafe);
}

.metric-card.temp {
  background: linear-gradient(135deg, #fffbeb, #fef3c7);
}

.metric-card.humidity {
  background: linear-gradient(135deg, #f0fdf4, #dcfce7);
}

.metric-value {
  font-size: 30px;
  font-weight: 700;
  color: var(--text-primary);
  line-height: 1.2;
  margin-bottom: 6px;
}

.metric-label {
  font-size: 13px;
  color: var(--text-secondary);
}

/* 阈值表单 */
.threshold-form {
  padding-top: 4px;
}

.threshold-row {
  display: flex;
  gap: 24px;
  flex-wrap: wrap;
}

.threshold-row .el-form-item {
  flex: 1;
  min-width: 200px;
}

.threshold-unit {
  margin-left: 8px;
  font-size: 14px;
  color: var(--text-tertiary);
}

.area-unit {
  margin-left: 8px;
  font-size: 14px;
  color: var(--text-tertiary);
}

.threshold-actions {
  display: flex;
  justify-content: flex-end;
  margin-top: 8px;
}
</style>
