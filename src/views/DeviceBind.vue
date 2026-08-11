<template>
  <div class="page-container device-bind">
    <!-- 统计卡片 -->
    <div class="stats-row">
      <div class="stat-card">
        <div class="stat-icon total">
          <el-icon :size="22"><Cpu /></el-icon>
        </div>
        <div class="stat-body">
          <div class="stat-value">{{ stats.total }}</div>
          <div class="stat-label">设备总数</div>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon bound">
          <el-icon :size="22"><Connection /></el-icon>
        </div>
        <div class="stat-body">
          <div class="stat-value">{{ stats.bound }}</div>
          <div class="stat-label">已绑定</div>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon unbound">
          <el-icon :size="22"><Switch /></el-icon>
        </div>
        <div class="stat-body">
          <div class="stat-value">{{ stats.unbound }}</div>
          <div class="stat-label">未绑定</div>
        </div>
      </div>
    </div>

    <!-- 操作栏 -->
    <div class="action-bar">
      <el-tabs v-model="activeTab" class="bind-tabs">
        <el-tab-pane name="unbound">
          <template #label>
            <span class="tab-label">
              未绑定设备
              <el-badge :value="stats.unbound" :max="99" class="tab-badge" />
            </span>
          </template>
        </el-tab-pane>
        <el-tab-pane name="bound">
          <template #label>
            <span class="tab-label">
              已绑定设备
              <el-badge :value="stats.bound" :max="99" type="success" class="tab-badge" />
            </span>
          </template>
        </el-tab-pane>
      </el-tabs>
      <div class="action-btns">
        <el-button :icon="Refresh" @click="loadDevices">刷新</el-button>
        <el-button type="primary" :icon="Plus" @click="openAddDialog">添加设备</el-button>
      </div>
    </div>

    <!-- 未绑定设备 - 卡片网格 -->
    <div v-loading="loading" v-show="activeTab === 'unbound'" class="unbound-grid">
      <el-empty v-if="!loading && unboundDevices.length === 0" description="暂无未绑定设备" />
      <div v-for="device in unboundDevices" :key="device.id" class="device-card">
        <div class="device-card-header">
          <div class="device-name">{{ device.name }}</div>
          <el-tag size="small" :type="deviceTypeTag(device.type)" effect="light">
            {{ deviceTypeLabel(device.type) }}
          </el-tag>
        </div>
        <div class="device-card-body">
          <div class="device-info-row">
            <el-icon><Cellphone /></el-icon>
            <span>设备编号：{{ device.id }}</span>
          </div>
          <div class="device-info-row">
            <el-icon><Lightning /></el-icon>
            <span>电量：
              <span class="battery-text" :class="batteryClass(device.battery)">{{ device.battery }}%</span>
            </span>
            <div class="battery-bar">
              <div class="battery-fill" :class="batteryClass(device.battery)" :style="{ width: device.battery + '%' }"></div>
            </div>
          </div>
          <div class="device-info-row">
            <el-icon><Clock /></el-icon>
            <span>最近上报：{{ device.lastReport }}</span>
          </div>
        </div>
        <div class="device-card-footer">
          <el-button type="primary" plain size="small" :icon="Link" @click="openBindDialog(device)">
            绑定到地块
          </el-button>
          <el-button type="danger" plain size="small" :icon="Delete" @click="handleDeleteDevice(device)">
            删除
          </el-button>
        </div>
      </div>
    </div>

    <!-- 已绑定设备 - 表格 -->
    <div v-loading="loading" v-show="activeTab === 'bound'" class="bound-table-wrap">
      <el-empty v-if="!loading && boundDevices.length === 0" description="暂无已绑定设备" />
      <el-table
        v-else
        :data="boundDevices"
        stripe
        style="width: 100%"
        :header-cell-style="{ background: '#f9fafb', color: '#374151', fontWeight: 600 }"
      >
        <el-table-column label="序号" type="index" width="70" align="center" />
        <el-table-column label="设备名称" prop="name" min-width="160" />
        <el-table-column label="设备类型" width="130" align="center">
          <template #default="{ row }">
            <el-tag size="small" :type="deviceTypeTag(row.type)" effect="light">
              {{ deviceTypeLabel(row.type) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="绑定地块" prop="fieldName" min-width="160" />
        <el-table-column label="状态" width="100" align="center">
          <template #default="{ row }">
            <el-tag :type="row.status === 'online' ? 'success' : 'info'" size="small" effect="dark">
              {{ row.status === 'online' ? '在线' : '离线' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="电量" width="160" align="center">
          <template #default="{ row }">
            <div class="battery-cell">
              <span :class="batteryClass(row.battery)">{{ row.battery }}%</span>
              <div class="battery-bar small">
                <div class="battery-fill" :class="batteryClass(row.battery)" :style="{ width: row.battery + '%' }"></div>
              </div>
            </div>
          </template>
        </el-table-column>
        <el-table-column label="最近上报" prop="lastReport" width="180" />
        <el-table-column label="操作" width="160" align="center" fixed="right">
          <template #default="{ row }">
            <el-button type="danger" text size="small" :icon="Unlock" @click="handleUnbind(row)">
              解绑
            </el-button>
            <el-button type="danger" text size="small" :icon="Delete" @click="handleDeleteDevice(row)">
              删除
            </el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <!-- 绑定对话框 -->
    <el-dialog v-model="bindDialogVisible" title="绑定设备到地块" width="480px" :close-on-click-modal="false">
      <div v-if="currentDevice" class="bind-dialog-content">
        <div class="bind-device-preview">
          <el-icon :size="28" class="preview-icon"><Cpu /></el-icon>
          <div class="preview-info">
            <div class="preview-name">{{ currentDevice.name }}</div>
            <el-tag size="small" :type="deviceTypeTag(currentDevice.type)" effect="light">
              {{ deviceTypeLabel(currentDevice.type) }}
            </el-tag>
          </div>
        </div>
        <el-divider />
        <el-form label-width="80px">
          <el-form-item label="选择地块" required>
            <el-select
              v-model="selectedFieldId"
              placeholder="请选择要绑定的地块"
              style="width: 100%"
              filterable
            >
              <el-option
                v-for="field in fields"
                :key="field.id"
                :label="`${field.name}（${field.crop}）`"
                :value="field.id"
              />
            </el-select>
          </el-form-item>
        </el-form>
      </div>
      <template #footer>
        <el-button @click="bindDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="bindLoading" @click="confirmBind">确认绑定</el-button>
      </template>
    </el-dialog>

    <!-- 添加设备对话框 -->
    <el-dialog v-model="addDialogVisible" title="添加新设备" width="480px" :close-on-click-modal="false">
      <el-form :model="addForm" label-width="80px" ref="addFormRef" :rules="addRules">
        <el-form-item label="设备名称" prop="name">
          <el-input v-model="addForm.name" placeholder="请输入设备名称，如：土壤传感器-D003" />
        </el-form-item>
        <el-form-item label="设备类型" prop="type">
          <el-select
            v-model="addForm.type"
            placeholder="请选择或输入设备类型"
            style="width: 100%"
            filterable
            allow-create
            default-first-option
            :loading="typeLoading"
            @change="handleTypeChange"
          >
            <el-option
              v-for="t in deviceTypes"
              :key="t.value"
              :label="t.label"
              :value="t.value"
            />
          </el-select>
          <div class="type-hint">可从列表选择，或直接输入自定义类型名称</div>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="addDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="addLoading" @click="confirmAdd">确认添加</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  Cpu, Connection, Switch, Plus, Refresh, Link, Unlock, Delete,
  Cellphone, Clock, Lightning,
} from '@element-plus/icons-vue'
import { api } from '@/api'

// 设备类型列表（从后端加载，支持自定义扩展）
const deviceTypes = ref([])
const typeLoading = ref(false)

// 根据 type 值获取显示名称：优先查 deviceTypes，找不到则直接返回 type 本身
function deviceTypeLabel(type) {
  const found = deviceTypes.value.find((t) => t.value === type)
  return found ? found.label : type
}

const loading = ref(false)
const activeTab = ref('unbound')
const devices = ref([])
const fields = ref([])

// 统计
const stats = computed(() => ({
  total: devices.value.length,
  bound: devices.value.filter((d) => d.fieldId).length,
  unbound: devices.value.filter((d) => !d.fieldId).length,
}))

const unboundDevices = computed(() => devices.value.filter((d) => !d.fieldId))
const boundDevices = computed(() => devices.value.filter((d) => d.fieldId))

// 设备类型标签颜色（预设类型有专属颜色，自定义类型统一使用 info）
function deviceTypeTag(type) {
  const map = { soil_sensor: 'success', temp_sensor: 'warning', humidity_sensor: 'primary', irrigation_valve: 'primary', camera: 'danger' }
  return map[type] || 'info'
}

// 电量样式
function batteryClass(battery) {
  if (battery <= 20) return 'danger'
  if (battery <= 50) return 'warning'
  return 'success'
}

// ===== 数据加载 =====
async function loadDevices() {
  loading.value = true
  try {
    const res = await api.getDevices()
    if (res.code === 200) {
      devices.value = res.data || []
    }
  } catch {
    // 静默处理，页面显示空数据
    devices.value = []
  } finally {
    loading.value = false
  }
}

async function loadFields() {
  try {
    const res = await api.getFields()
    if (res.code === 200) {
      fields.value = res.data
    }
  } catch {
    // 静默处理
  }
}

// ===== 绑定设备 =====
const bindDialogVisible = ref(false)
const bindLoading = ref(false)
const currentDevice = ref(null)
const selectedFieldId = ref(null)

function openBindDialog(device) {
  currentDevice.value = device
  selectedFieldId.value = null
  bindDialogVisible.value = true
}

async function confirmBind() {
  if (!selectedFieldId.value) {
    ElMessage.warning('请选择要绑定的地块')
    return
  }
  bindLoading.value = true
  try {
    const res = await api.bindDevice(currentDevice.value.id, selectedFieldId.value)
    if (res.code === 200) {
      ElMessage.success('设备绑定成功')
      bindDialogVisible.value = false
      await loadDevices()
    }
  } catch {
    // 静默处理，不弹toast
  } finally {
    bindLoading.value = false
  }
}

// ===== 解绑设备 =====
async function handleUnbind(device) {
  try {
    await ElMessageBox.confirm(
      `确定要解绑设备「${device.name}」与地块「${device.fieldName}」的关联吗？`,
      '解绑确认',
      { confirmButtonText: '确定解绑', cancelButtonText: '取消', type: 'warning' },
    )
    const res = await api.unbindDevice(device.id)
    if (res.code === 200) {
      ElMessage.success('设备已解绑')
      await loadDevices()
    }
  } catch (err) {
    if (err !== 'cancel') {
      // 静默处理，不弹toast
    }
  }
}

// ===== 删除设备 =====
async function handleDeleteDevice(device) {
  try {
    await ElMessageBox.confirm(
      `确定要删除设备「${device.name}」吗？删除后不可恢复，请谨慎操作。`,
      '删除确认',
      { confirmButtonText: '确定删除', cancelButtonText: '取消', type: 'warning' },
    )
    const res = await api.deleteDevice(device.id)
    if (res.code === 200) {
      ElMessage.success('设备已删除')
      await loadDevices()
    }
  } catch (err) {
    if (err !== 'cancel') {
      // 静默处理，不弹toast
    }
  }
}

// ===== 添加设备 =====
const addDialogVisible = ref(false)
const addLoading = ref(false)
const addFormRef = ref(null)
const addForm = reactive({
  name: '',
  type: '',
})
const addRules = {
  name: [{ required: true, message: '请输入设备名称', trigger: 'blur' }],
  type: [{ required: true, message: '请选择或输入设备类型', trigger: 'change' }],
}

// 用户在 select 中输入了自定义类型时，将其保存到类型列表
async function handleTypeChange(val) {
  if (!val) return
  const exists = deviceTypes.value.some((t) => t.value === val)
  if (!exists) {
    // 自定义类型：val 即为用户输入的中文名称，同时作为 value 和 label
    try {
      const res = await api.addDeviceType(val)
      if (res.code === 200) {
        deviceTypes.value = res.data
      }
    } catch {
      // 静默处理，不影响添加流程
    }
  }
}

function openAddDialog() {
  addForm.name = ''
  addForm.type = ''
  addDialogVisible.value = true
}

async function confirmAdd() {
  if (!addFormRef.value) return
  await addFormRef.value.validate(async (valid) => {
    if (!valid) return
    addLoading.value = true
    try {
      const res = await api.addDevice({ name: addForm.name, type: addForm.type })
      if (res.code === 200) {
        ElMessage.success('设备添加成功')
        addDialogVisible.value = false
        await loadDevices()
      }
    } catch {
      // 静默处理，不弹toast
    } finally {
      addLoading.value = false
    }
  })
}

// ===== 加载设备类型 =====
async function loadDeviceTypes() {
  typeLoading.value = true
  try {
    const res = await api.getDeviceTypes()
    if (res.code === 200 && res.data) {
      deviceTypes.value = res.data
    }
  } catch {
    // 静默处理
  } finally {
    typeLoading.value = false
  }
}

onMounted(() => {
  loadDevices()
  loadFields()
  loadDeviceTypes()
})
</script>

<style scoped>
.device-bind {
  padding: 20px 24px;
}

/* ===== 统计卡片 ===== */
.stats-row {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
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

.stat-icon.total {
  background: #eff6ff;
  color: #2563eb;
}

.stat-icon.bound {
  background: var(--primary-bg);
  color: var(--primary);
}

.stat-icon.unbound {
  background: #fffbeb;
  color: var(--warning);
}

.stat-value {
  font-size: 28px;
  font-weight: 700;
  color: var(--text-primary);
  line-height: 1.2;
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

.bind-tabs {
  flex: 1;
}

.bind-tabs :deep(.el-tabs__header) {
  margin-bottom: 0;
}

.bind-tabs :deep(.el-tabs__nav-wrap::after) {
  display: none;
}

.tab-label {
  display: inline-flex;
  align-items: center;
  gap: 6px;
}

.action-btns {
  display: flex;
  gap: 10px;
  flex-shrink: 0;
}

/* ===== 未绑定设备卡片 ===== */
.unbound-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 16px;
  min-height: 200px;
}

.device-card {
  background: var(--bg-card);
  border: 1px solid var(--border-color);
  border-radius: var(--border-radius);
  box-shadow: var(--shadow-sm);
  overflow: hidden;
  transition: all 0.2s ease;
}

.device-card:hover {
  box-shadow: var(--shadow-md);
  transform: translateY(-2px);
  border-color: #bbf7d0;
}

.device-card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 14px 16px;
  background: #f9fafb;
  border-bottom: 1px solid var(--border-color);
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
  padding: 16px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.device-info-row {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  color: var(--text-secondary);
  flex-wrap: wrap;
}

.device-info-row .el-icon {
  color: var(--text-tertiary);
  font-size: 15px;
  flex-shrink: 0;
}

.battery-text {
  font-weight: 600;
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

.battery-bar {
  width: 60px;
  height: 8px;
  background: #f3f4f6;
  border-radius: 4px;
  overflow: hidden;
}

.battery-bar.small {
  width: 50px;
  height: 6px;
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

.device-card-footer {
  padding: 12px 16px;
  border-top: 1px solid var(--border-color);
  display: flex;
  justify-content: flex-end;
}

/* ===== 已绑定设备表格 ===== */
.bound-table-wrap {
  background: var(--bg-card);
  border: 1px solid var(--border-color);
  border-radius: var(--border-radius);
  box-shadow: var(--shadow-sm);
  overflow: hidden;
  min-height: 200px;
}

.battery-cell {
  display: flex;
  align-items: center;
  gap: 8px;
  justify-content: center;
}

/* ===== 绑定对话框 ===== */
.bind-device-preview {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 16px;
  background: var(--primary-bg);
  border-radius: var(--border-radius);
}

.preview-icon {
  width: 48px;
  height: 48px;
  background: var(--primary);
  color: #fff;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.preview-info {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.preview-name {
  font-size: 15px;
  font-weight: 600;
  color: var(--text-primary);
}

/* 类型提示文字 */
.type-hint {
  font-size: 12px;
  color: var(--text-tertiary);
  margin-top: 4px;
  line-height: 1.4;
}
</style>
