<template>
  <div class="farm-3d-container">
    <!-- 加载遮罩 -->
    <div v-if="loading" class="loading-overlay">
      <div class="loading-content">
        <div class="loading-spinner"></div>
        <span>正在加载3D农场数据...</span>
      </div>
    </div>

    <!-- 3D 画布容器 -->
    <div ref="containerRef" class="canvas-container"></div>

    <!-- 空数据提示 -->
    <div v-if="!loading && fields.length === 0" class="empty-overlay">
      <el-icon :size="56" color="#9ca3af"><View /></el-icon>
      <p class="empty-title">暂无农场数据</p>
      <p class="empty-desc">请先绑定农场管理者，绑定后即可查看3D农场全景</p>
    </div>

    <!-- 左上角：标题与操作提示 -->
    <div class="overlay overlay-tl">
      <div class="title-card">
        <h2 class="title">3D农场全景</h2>
        <p class="subtitle">拖拽旋转 · 滚轮缩放 · 点击地块查看详情</p>
      </div>
    </div>

    <!-- 顶部居中：田地管理工具栏（仅管理员可见） -->
    <div class="overlay overlay-tc" v-if="userStore.isManager">
      <div class="field-toolbar">
        <el-button type="primary" size="small" @click="handleAddField">
          <el-icon style="margin-right: 4px"><Plus /></el-icon>
          新增田地
        </el-button>
        <el-button
          type="danger"
          plain
          size="small"
          :disabled="!selectedFieldId"
          @click="handleDeleteField"
        >
          <el-icon style="margin-right: 4px"><Delete /></el-icon>
          删除田地
        </el-button>
      </div>
    </div>

    <!-- 右上角：状态图例 + 天气预报 -->
    <div class="overlay overlay-tr">
      <div class="legend-card">
        <div class="card-header">状态图例</div>
        <div class="legend-list">
          <div class="legend-row" v-for="item in legendItems" :key="item.label">
            <span class="legend-dot" :style="{ background: item.color, boxShadow: `0 0 6px ${item.color}` }"></span>
            <span class="legend-text">{{ item.label }}</span>
          </div>
        </div>
      </div>

      <!-- 天气预报卡片 -->
      <div class="weather-card-3d" v-if="weatherData">
        <div class="weather-3d-header">
          <span class="weather-3d-title">天气预报</span>
          <span class="weather-3d-update">{{ weatherData.current.conditionText }}</span>
        </div>
        <div class="weather-3d-current">
          <span class="weather-3d-icon">{{ getWeatherIcon(weatherData.current.condition) }}</span>
          <div class="weather-3d-info">
            <span class="weather-3d-temp">{{ weatherData.current.temp }}°C</span>
            <span class="weather-3d-detail">{{ weatherData.current.windDirection }} {{ weatherData.current.windSpeed }}km/h · 湿度{{ weatherData.current.humidity }}%</span>
          </div>
        </div>
        <div class="weather-3d-forecast">
          <div class="weather-3d-forecast-item" v-for="(item, idx) in weatherData.forecast.slice(0, 3)" :key="idx">
            <span class="w3d-day">{{ item.dayOfWeek }}</span>
            <span class="w3d-icon">{{ getWeatherIcon(item.condition) }}</span>
            <span class="w3d-temp">{{ item.highTemp }}°/{{ item.lowTemp }}°</span>
          </div>
        </div>
      </div>
    </div>

    <!-- 左下角：地块列表 -->
    <div class="overlay overlay-bl">
      <div class="field-list-card">
        <div class="card-header">地块列表</div>
        <div class="field-list-body">
          <div
            v-for="field in fields"
            :key="field.id"
            class="field-list-row"
            :class="{ 'field-list-active': popupField && popupField.id === field.id }"
            @click="focusField(field)"
          >
            <span class="field-dot" :style="{ background: getStatusColor(field.status) }"></span>
            <div class="field-info">
              <span class="field-list-name">{{ field.name }}</span>
              <span class="field-list-crop">{{ field.crop }} · {{ field.area }}㎡</span>
            </div>
            <span class="field-alert-icon" v-if="hasActiveAlert(field.id)">
              <el-icon><WarningFilled /></el-icon>
            </span>
          </div>
        </div>
      </div>
    </div>

    <!-- 右下角：活跃告警数 -->
    <Transition name="badge-fade">
      <div class="overlay overlay-br" v-if="activeAlerts.length > 0">
        <div class="alert-badge-card">
          <div class="alert-badge-pulse"></div>
          <div class="alert-badge-pulse alert-badge-pulse-2"></div>
          <div class="alert-badge-content">
            <el-icon class="alert-badge-icon"><Warning /></el-icon>
            <div class="alert-badge-info">
              <span class="alert-badge-count">{{ activeAlerts.length }}</span>
              <span class="alert-badge-label">活跃告警</span>
            </div>
          </div>
        </div>
      </div>
    </Transition>

    <!-- 告警/详情弹窗 -->
    <Transition name="popup-fade">
      <div
        v-if="popupField"
        class="alert-popup"
        :style="{ left: popupPosition.x + 'px', top: popupPosition.y + 'px' }"
        @click.stop
      >
        <div class="popup-arrow"></div>
        <div class="popup-header">
          <div class="popup-title-area">
            <span class="popup-status-dot" :style="{ background: getStatusColor(popupField.status) }"></span>
            <span class="popup-title">{{ popupField.name }}</span>
          </div>
          <span class="popup-close" @click="closePopup">
            <el-icon><Close /></el-icon>
          </span>
        </div>
        <div class="popup-body">
          <template v-if="popupAlert">
            <div class="popup-row">
              <span class="popup-label">告警级别</span>
              <el-tag :type="getAlertTagType(popupAlert.level)" size="small" effect="dark">
                {{ getAlertLevelText(popupAlert.level) }}
              </el-tag>
            </div>
            <div class="popup-row">
              <span class="popup-label">告警类型</span>
              <span class="popup-value">{{ getAlertTypeText(popupAlert.type) }}</span>
            </div>
            <div class="popup-row">
              <span class="popup-label">告警详情</span>
              <span class="popup-value">{{ popupAlert.message }}</span>
            </div>
            <div class="popup-row">
              <span class="popup-label">告警时间</span>
              <span class="popup-value">{{ popupAlert.time }}</span>
            </div>
          </template>
          <template v-else>
            <div class="popup-row">
              <span class="popup-label">当前状态</span>
              <el-tag :type="getStatusTagType(popupField.status)" size="small" effect="dark">
                {{ getStatusText(popupField.status) }}
              </el-tag>
            </div>
            <div class="popup-row">
              <span class="popup-label">种植作物</span>
              <span class="popup-value">{{ popupField.crop }}</span>
            </div>
            <div class="popup-row">
              <span class="popup-label">地块面积</span>
              <span class="popup-value">{{ popupField.area }} ㎡</span>
            </div>
            <div class="popup-row">
              <span class="popup-label">土壤湿度</span>
              <span class="popup-value">{{ popupField.soilMoisture }}%</span>
            </div>
            <div class="popup-row">
              <span class="popup-label">环境温度</span>
              <span class="popup-value">{{ popupField.temperature }}°C</span>
            </div>
            <div class="popup-row">
              <span class="popup-label">空气湿度</span>
              <span class="popup-value">{{ popupField.humidity }}%</span>
            </div>
          </template>

          <!-- 设备绑定管理（仅管理员可见，且非告警视图） -->
          <div class="popup-device-section" v-if="userStore.isManager && !popupAlert" v-loading="deviceLoading">
            <div class="popup-device-divider"></div>
            <div class="popup-row popup-device-title">
              <span class="popup-label">绑定设备</span>
              <span class="popup-device-count">{{ fieldDevices.length }} 台</span>
            </div>
            <div v-if="fieldDevices.length === 0" class="popup-device-empty">暂无绑定设备</div>
            <div v-else class="popup-device-list">
              <div v-for="device in fieldDevices" :key="device.id" class="popup-device-item">
                <div class="popup-device-info">
                  <span class="popup-device-name">{{ device.name }}</span>
                  <span class="popup-device-meta">
                    {{ getDeviceTypeText(device.type) }} · 电量{{ device.battery }}%
                  </span>
                </div>
                <el-button size="small" type="danger" plain @click="handleUnbindDevice(device.id)">
                  解绑
                </el-button>
              </div>
            </div>
            <div class="popup-bind-row">
              <el-select
                v-model="selectedDeviceToBind"
                size="small"
                placeholder="选择未绑定设备"
                class="popup-bind-select"
                :disabled="unboundDevices.length === 0"
              >
                <el-option
                  v-for="device in unboundDevices"
                  :key="device.id"
                  :label="device.name"
                  :value="device.id"
                />
              </el-select>
              <el-button
                size="small"
                type="primary"
                :disabled="!selectedDeviceToBind"
                @click="handleBindDevice"
              >
                绑定
              </el-button>
            </div>
            <div v-if="unboundDevices.length === 0" class="popup-device-hint">暂无可绑定的设备</div>
          </div>
        </div>
        <div class="popup-footer" v-if="popupAlert">
          <el-button
            type="primary"
            size="small"
            :loading="resolving"
            @click="resolveAlert(popupAlert.id)"
          >
            <el-icon style="margin-right: 4px"><Check /></el-icon>
            处理告警
          </el-button>
        </div>
        <div class="popup-footer popup-footer-monitor" v-if="popupField">
          <el-button
            type="primary"
            plain
            size="small"
            @click="goToMonitor(popupField.id)"
          >
            <el-icon style="margin-right: 4px"><VideoCamera /></el-icon>
            实时监控
          </el-button>
        </div>
      </div>
    </Transition>

    <!-- 新增田地对话框 -->
    <el-dialog
      v-model="showAddFieldDialog"
      title="新增田地"
      width="420px"
      :close-on-click-modal="false"
      append-to-body
    >
      <el-form :model="addFieldForm" label-width="90px" label-position="right">
        <el-form-item label="田地名称" required>
          <el-input
            v-model="addFieldForm.name"
            placeholder="请输入田地名称"
            maxlength="20"
            show-word-limit
          />
        </el-form-item>
        <el-form-item label="种植作物">
          <el-input v-model="addFieldForm.crop" placeholder="如：番茄、黄瓜" maxlength="20" />
        </el-form-item>
        <el-form-item label="面积(㎡)">
          <el-input-number
            v-model="addFieldForm.area"
            :min="100"
            :step="100"
            controls-position="right"
            style="width: 100%"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showAddFieldDialog = false">取消</el-button>
        <el-button type="primary" :loading="addFieldLoading" @click="confirmAddField">
          确认
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, nextTick } from 'vue'
import * as THREE from 'three'
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js'
import { CSS2DRenderer, CSS2DObject } from 'three/examples/jsm/renderers/CSS2DRenderer.js'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Warning, WarningFilled, Close, Check, Plus, Delete, VideoCamera, View } from '@element-plus/icons-vue'
import { api } from '@/api'
import { useUserStore } from '@/store/user'
import { useRouter } from 'vue-router'

// ========== 常量定义 ==========
const STATUS_COLORS = {
  normal: 0x22c55e,
  warning: 0xf59e0b,
  danger: 0xef4444,
  offline: 0x9ca3af,
}

const STATUS_COLORS_CSS = {
  normal: '#22c55e',
  warning: '#f59e0b',
  danger: '#ef4444',
  offline: '#9ca3af',
}

const legendItems = [
  { label: '正常', color: '#22c55e' },
  { label: '警告', color: '#f59e0b' },
  { label: '危险', color: '#ef4444' },
  { label: '离线', color: '#9ca3af' },
]

// 地块网格参数
const FIELD_COLS = 3
const FIELD_ROWS = 2
const FIELD_SPACING = 14
const BLOCK_W = 10
const BLOCK_H = 1.5
const BLOCK_D = 10

// ========== 响应式状态 ==========
const containerRef = ref(null)
const fields = ref([])
const alerts = ref([])
const popupField = ref(null)
const popupAlert = ref(null)
const popupPosition = ref({ x: 0, y: 0 })
const loading = ref(true)
const resolving = ref(false)
const weatherData = ref(null)

// ========== 用户角色与田地管理状态 ==========
const userStore = useUserStore()
const router = useRouter()
const selectedFieldId = ref(null)
const showAddFieldDialog = ref(false)
const addFieldLoading = ref(false)
const addFieldForm = ref({ name: '', crop: '', area: 1000 })

// ========== 设备绑定状态 ==========
const fieldDevices = ref([])
const unboundDevices = ref([])
const selectedDeviceToBind = ref(null)
const deviceLoading = ref(false)

// ========== 计算属性 ==========
const activeAlerts = computed(() => alerts.value.filter((a) => a.status === 'active'))

// ========== 辅助函数 ==========
function getStatusColor(status) {
  return STATUS_COLORS_CSS[status] || '#22c55e'
}

function getStatusText(status) {
  const map = { normal: '正常', warning: '警告', danger: '危险', offline: '离线' }
  return map[status] || status
}

function getStatusTagType(status) {
  const map = { normal: 'success', warning: 'warning', danger: 'danger', offline: 'info' }
  return map[status] || 'info'
}

function getAlertLevelText(level) {
  const map = { warning: '警告', danger: '严重', info: '信息' }
  return map[level] || level
}

function getAlertTagType(level) {
  const map = { warning: 'warning', danger: 'danger', info: 'info' }
  return map[level] || 'info'
}

function getAlertTypeText(type) {
  const map = {
    low_moisture: '湿度不足',
    high_temp: '温度过高',
    device_offline: '设备离线',
    low_battery: '电量低',
  }
  return map[type] || type
}

function hasActiveAlert(fieldId) {
  return alerts.value.some((a) => a.fieldId === fieldId && a.status === 'active')
}

// 获取地块最严重的活跃告警
function getFieldAlert(fieldId) {
  const fieldAlerts = alerts.value.filter((a) => a.fieldId === fieldId && a.status === 'active')
  if (fieldAlerts.length === 0) return null
  const priority = { danger: 3, warning: 2, info: 1 }
  fieldAlerts.sort((a, b) => (priority[b.level] || 0) - (priority[a.level] || 0))
  return fieldAlerts[0]
}

// ========== Three.js 变量（非响应式）==========
let scene = null
let camera = null
let renderer = null
let labelRenderer = null
let controls = null
let raycaster = null
let pointer = null
let clock = null
const fieldDataMap = new Map()
let animationId = null
let resizeHandler = null
let pointerDownHandler = null
let pointerUpHandler = null
let pointerDownPos = null

// ========== Three.js 初始化 ==========
function initThree() {
  const container = containerRef.value
  if (!container) return
  const width = container.clientWidth
  const height = container.clientHeight
  if (width === 0 || height === 0) return

  // 场景
  scene = new THREE.Scene()
  scene.background = new THREE.Color(0x87ceeb)
  scene.fog = new THREE.Fog(0x87ceeb, 70, 180)

  // 相机
  camera = new THREE.PerspectiveCamera(50, width / height, 0.1, 500)
  camera.position.set(30, 28, 30)
  camera.lookAt(0, 0, 0)

  // WebGL 渲染器
  renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true })
  renderer.setSize(width, height)
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2))
  renderer.shadowMap.enabled = true
  renderer.shadowMap.type = THREE.PCFSoftShadowMap
  container.appendChild(renderer.domElement)

  // CSS2D 标签渲染器
  labelRenderer = new CSS2DRenderer()
  labelRenderer.setSize(width, height)
  labelRenderer.domElement.style.position = 'absolute'
  labelRenderer.domElement.style.top = '0'
  labelRenderer.domElement.style.left = '0'
  labelRenderer.domElement.style.pointerEvents = 'none'
  container.appendChild(labelRenderer.domElement)

  // 轨道控制器
  controls = new OrbitControls(camera, renderer.domElement)
  controls.enableDamping = true
  controls.dampingFactor = 0.06
  controls.maxPolarAngle = Math.PI / 2.1
  controls.minDistance = 12
  controls.maxDistance = 80
  controls.target.set(0, 0, 0)

  // 光照系统
  const ambient = new THREE.AmbientLight(0xffffff, 0.55)
  scene.add(ambient)

  const directional = new THREE.DirectionalLight(0xffffff, 1.0)
  directional.position.set(25, 40, 20)
  directional.castShadow = true
  directional.shadow.mapSize.width = 2048
  directional.shadow.mapSize.height = 2048
  directional.shadow.camera.near = 1
  directional.shadow.camera.far = 120
  directional.shadow.camera.left = -40
  directional.shadow.camera.right = 40
  directional.shadow.camera.top = 40
  directional.shadow.camera.bottom = -40
  directional.shadow.bias = -0.0005
  scene.add(directional)

  const hemi = new THREE.HemisphereLight(0x87ceeb, 0x4ade80, 0.3)
  scene.add(hemi)

  // 创建场景元素
  createGround()
  createPaths()
  createFields()
  createTrees()

  // 射线检测器
  raycaster = new THREE.Raycaster()
  pointer = new THREE.Vector2()
  clock = new THREE.Clock()

  // 事件监听
  resizeHandler = () => onResize()
  window.addEventListener('resize', resizeHandler)

  pointerDownHandler = (event) => {
    pointerDownPos = { x: event.clientX, y: event.clientY }
  }
  pointerUpHandler = (event) => {
    if (!pointerDownPos) return
    const dx = event.clientX - pointerDownPos.x
    const dy = event.clientY - pointerDownPos.y
    const dist = Math.sqrt(dx * dx + dy * dy)
    pointerDownPos = null
    if (dist < 5) {
      onCanvasClick(event)
    }
  }
  renderer.domElement.addEventListener('pointerdown', pointerDownHandler)
  renderer.domElement.addEventListener('pointerup', pointerUpHandler)

  // 启动渲染循环
  animate()
}

// ========== 场景元素创建 ==========

function createGround() {
  const groundGeo = new THREE.PlaneGeometry(200, 200)
  const groundMat = new THREE.MeshStandardMaterial({ color: 0x4ade80, roughness: 0.95 })
  const ground = new THREE.Mesh(groundGeo, groundMat)
  ground.rotation.x = -Math.PI / 2
  ground.position.y = -0.01
  ground.receiveShadow = true
  scene.add(ground)
}

function createPaths() {
  const pathMat = new THREE.MeshStandardMaterial({ color: 0xd4b896, roughness: 0.95 })

  // 水平路径（两行地块之间）
  const hPathGeo = new THREE.PlaneGeometry(50, 3)
  const hPath = new THREE.Mesh(hPathGeo, pathMat)
  hPath.rotation.x = -Math.PI / 2
  hPath.position.set(0, 0.02, 0)
  hPath.receiveShadow = true
  scene.add(hPath)

  // 垂直路径（三列地块之间）
  const vPathGeo = new THREE.PlaneGeometry(3, 28)
  ;[-7, 7].forEach((x) => {
    const vPath = new THREE.Mesh(vPathGeo, pathMat)
    vPath.rotation.x = -Math.PI / 2
    vPath.position.set(x, 0.02, 0)
    vPath.receiveShadow = true
    scene.add(vPath)
  })
}

function createFields() {
  const offsetX = (-(FIELD_COLS - 1) * FIELD_SPACING) / 2
  const offsetZ = (-(FIELD_ROWS - 1) * FIELD_SPACING) / 2

  for (let i = 0; i < fields.value.length && i < FIELD_COLS * FIELD_ROWS; i++) {
    const field = fields.value[i]
    const col = i % FIELD_COLS
    const row = Math.floor(i / FIELD_COLS)
    const x = offsetX + col * FIELD_SPACING
    const z = offsetZ + row * FIELD_SPACING
    const color = STATUS_COLORS[field.status] || STATUS_COLORS.normal

    const fieldGroup = new THREE.Group()

    // --- 地块主体（多材质：顶面亮色，侧面暗色）---
    const topColor = new THREE.Color(color)
    const sideColor = new THREE.Color(color).multiplyScalar(0.65)
    const bottomColor = new THREE.Color(color).multiplyScalar(0.45)
    const blockGeo = new THREE.BoxGeometry(BLOCK_W, BLOCK_H, BLOCK_D)
    const blockMats = [
      new THREE.MeshStandardMaterial({ color: sideColor, roughness: 0.85 }),
      new THREE.MeshStandardMaterial({ color: sideColor, roughness: 0.85 }),
      new THREE.MeshStandardMaterial({ color: topColor, roughness: 0.7 }),
      new THREE.MeshStandardMaterial({ color: bottomColor, roughness: 0.85 }),
      new THREE.MeshStandardMaterial({ color: sideColor, roughness: 0.85 }),
      new THREE.MeshStandardMaterial({ color: sideColor, roughness: 0.85 }),
    ]
    const block = new THREE.Mesh(blockGeo, blockMats)
    block.position.set(x, BLOCK_H / 2, z)
    block.castShadow = true
    block.receiveShadow = true
    block.userData = { fieldId: field.id, isField: true }
    fieldGroup.add(block)

    // --- 作物行（地表纹理装饰）---
    const cropColor = new THREE.Color(color).multiplyScalar(0.5)
    const cropMat = new THREE.MeshStandardMaterial({ color: cropColor, roughness: 0.8 })
    const rowCount = 4
    const rowSpacing = (BLOCK_D - 3) / (rowCount - 1)
    for (let r = 0; r < rowCount; r++) {
      const rowGeo = new THREE.BoxGeometry(BLOCK_W - 2, 0.3, 0.5)
      const row = new THREE.Mesh(rowGeo, cropMat)
      row.position.set(x, BLOCK_H + 0.15, z - (BLOCK_D - 3) / 2 + r * rowSpacing)
      row.castShadow = true
      row.receiveShadow = true
      fieldGroup.add(row)
    }

    // --- 传感器设备 ---
    const sensorPoleGeo = new THREE.CylinderGeometry(0.2, 0.3, 2.5, 8)
    const sensorPoleMat = new THREE.MeshStandardMaterial({ color: 0x374151, roughness: 0.5, metalness: 0.3 })
    const sensorPole = new THREE.Mesh(sensorPoleGeo, sensorPoleMat)
    sensorPole.position.set(x - 3, BLOCK_H + 1.25, z - 3)
    sensorPole.castShadow = true
    fieldGroup.add(sensorPole)

    // 传感器顶灯（颜色随状态变化）
    const sensorLightColor = field.status === 'offline'
      ? 0x6b7280
      : field.status === 'normal'
        ? 0x22c55e
        : field.status === 'warning'
          ? 0xf59e0b
          : 0xef4444
    const sensorLightGeo = new THREE.SphereGeometry(0.35, 12, 12)
    const sensorLightMat = new THREE.MeshStandardMaterial({
      color: sensorLightColor,
      emissive: sensorLightColor,
      emissiveIntensity: 0.6,
    })
    const sensorLight = new THREE.Mesh(sensorLightGeo, sensorLightMat)
    sensorLight.position.set(x - 3, BLOCK_H + 2.7, z - 3)
    fieldGroup.add(sensorLight)

    // --- CSS2D 浮动标签 ---
    const labelDiv = document.createElement('div')
    labelDiv.className = 'field-3d-label'
    const nameEl = document.createElement('div')
    nameEl.className = 'field-3d-label-name'
    nameEl.textContent = field.name
    const cropEl = document.createElement('div')
    cropEl.className = 'field-3d-label-crop'
    cropEl.textContent = field.crop
    labelDiv.appendChild(nameEl)
    labelDiv.appendChild(cropEl)
    const label = new CSS2DObject(labelDiv)
    label.position.set(x, BLOCK_H + 4, z)
    fieldGroup.add(label)

    scene.add(fieldGroup)

    // --- 告警标记 ---
    const alert = getFieldAlert(field.id)
    let marker = null
    if (alert) {
      marker = createAlertMarker(x, BLOCK_H + 5.5, z)
      scene.add(marker)
    }

    fieldDataMap.set(field.id, {
      field,
      alert,
      marker,
      block,
      group: fieldGroup,
      position: new THREE.Vector3(x, BLOCK_H, z),
    })
  }
}

function createAlertMarker(x, y, z) {
  const group = new THREE.Group()

  // 锥形告警标记
  const coneGeo = new THREE.ConeGeometry(0.7, 1.8, 8)
  const coneMat = new THREE.MeshStandardMaterial({
    color: 0xef4444,
    emissive: 0xef4444,
    emissiveIntensity: 0.5,
    roughness: 0.4,
  })
  const cone = new THREE.Mesh(coneGeo, coneMat)
  cone.castShadow = true
  group.add(cone)

  // 脉冲环（两层）
  const ringGeo = new THREE.TorusGeometry(1.0, 0.08, 8, 24)
  const rings = []
  for (let i = 0; i < 2; i++) {
    const ringMat = new THREE.MeshBasicMaterial({
      color: 0xef4444,
      transparent: true,
      opacity: 0.5,
    })
    const ring = new THREE.Mesh(ringGeo, ringMat)
    ring.rotation.x = Math.PI / 2
    ring.position.y = -1
    group.add(ring)
    rings.push(ring)
  }

  group.position.set(x, y, z)
  group.userData = { isMarker: true, rings }
  return group
}

function createTrees() {
  const positions = [
    [-32, -22], [32, -22], [-32, 22], [32, 22],
    [0, -28], [0, 28], [-28, 0], [28, 0],
    [-20, -28], [20, 28], [-28, -20], [28, 20],
  ]

  const trunkMat = new THREE.MeshStandardMaterial({ color: 0x92400e, roughness: 0.9 })
  const foliageMat = new THREE.MeshStandardMaterial({ color: 0x166534, roughness: 0.8 })

  positions.forEach(([x, z]) => {
    // 树干
    const trunkGeo = new THREE.CylinderGeometry(0.35, 0.5, 3, 8)
    const trunk = new THREE.Mesh(trunkGeo, trunkMat)
    trunk.position.set(x, 1.5, z)
    trunk.castShadow = true
    scene.add(trunk)

    // 树冠（两层圆锥）
    const foliage1Geo = new THREE.ConeGeometry(2, 3, 8)
    const foliage1 = new THREE.Mesh(foliage1Geo, foliageMat)
    foliage1.position.set(x, 4.5, z)
    foliage1.castShadow = true
    scene.add(foliage1)

    const foliage2Geo = new THREE.ConeGeometry(1.5, 2.5, 8)
    const foliage2 = new THREE.Mesh(foliage2Geo, foliageMat)
    foliage2.position.set(x, 6, z)
    foliage2.castShadow = true
    scene.add(foliage2)
  })
}

// ========== 渲染循环 ==========
function animate() {
  animationId = requestAnimationFrame(animate)
  if (!scene || !camera || !renderer) return

  const elapsed = clock.getElapsedTime()

  // 告警标记脉冲动画
  fieldDataMap.forEach((data) => {
    if (data.marker) {
      const pulse = Math.sin(elapsed * 3) * 0.15 + 1
      data.marker.scale.setScalar(pulse)
      data.marker.rotation.y = elapsed * 0.5

      // 环扩散动画
      if (data.marker.userData.rings) {
        data.marker.userData.rings.forEach((ring, idx) => {
          const phase = (elapsed * 1.5 + idx * 0.5) % 2
          const scale = 1 + phase
          ring.scale.setScalar(scale)
          ring.material.opacity = Math.max(0, 0.5 * (1 - phase / 2))
        })
      }
    }
  })

  controls.update()
  renderer.render(scene, camera)
  labelRenderer.render(scene, camera)

  // 更新弹窗屏幕位置
  if (popupField.value) {
    updatePopupPosition()
  }
}

function updatePopupPosition() {
  if (!popupField.value || !camera || !containerRef.value) return
  const data = fieldDataMap.get(popupField.value.id)
  if (!data) return

  const pos = data.position.clone()
  pos.y += 4
  pos.project(camera)

  // 点在相机后方时隐藏弹窗
  if (pos.z > 1) {
    popupPosition.value = { x: -9999, y: -9999 }
    return
  }

  const container = containerRef.value
  const width = container.clientWidth
  const height = container.clientHeight

  popupPosition.value = {
    x: (pos.x * 0.5 + 0.5) * width,
    y: (-pos.y * 0.5 + 0.5) * height,
  }
}

// ========== 事件处理 ==========
function onResize() {
  const container = containerRef.value
  if (!container || !camera || !renderer) return
  const width = container.clientWidth
  const height = container.clientHeight
  camera.aspect = width / height
  camera.updateProjectionMatrix()
  renderer.setSize(width, height)
  labelRenderer.setSize(width, height)
}

function onCanvasClick(event) {
  const container = containerRef.value
  if (!container) return
  const rect = container.getBoundingClientRect()
  pointer.x = ((event.clientX - rect.left) / rect.width) * 2 - 1
  pointer.y = -((event.clientY - rect.top) / rect.height) * 2 + 1

  raycaster.setFromCamera(pointer, camera)

  const meshes = []
  fieldDataMap.forEach((data) => meshes.push(data.block))

  const intersects = raycaster.intersectObjects(meshes, false)

  if (intersects.length > 0) {
    const mesh = intersects[0].object
    const fieldId = mesh.userData.fieldId
    const data = fieldDataMap.get(fieldId)
    if (data) {
      popupField.value = data.field
      popupAlert.value = data.alert
      selectedFieldId.value = data.field.id
      updatePopupPosition()
      // 管理员加载该田地的设备绑定信息
      if (userStore.isManager && !data.alert) {
        loadFieldDevices(data.field.id)
      }
    }
  } else {
    closePopup()
  }
}

// ========== 用户操作 ==========
function focusField(field) {
  const data = fieldDataMap.get(field.id)
  if (!data) {
    ElMessage.info('该地块暂未在3D场景中显示')
    return
  }

  // 打开弹窗
  popupField.value = field
  popupAlert.value = data.alert
  selectedFieldId.value = field.id
  updatePopupPosition()

  // 管理员加载该田地的设备绑定信息
  if (userStore.isManager && !data.alert) {
    loadFieldDevices(field.id)
  }

  // 相机平滑移动到地块
  const targetPos = data.position
  const offset = new THREE.Vector3(12, 15, 12)
  const targetCameraPos = targetPos.clone().add(offset)
  animateCamera(targetCameraPos, targetPos.clone())
}

function animateCamera(targetPos, lookAt) {
  const startPos = camera.position.clone()
  const startTarget = controls.target.clone()
  const duration = 800
  const startTime = performance.now()

  function step() {
    const now = performance.now()
    const t = Math.min((now - startTime) / duration, 1)
    const easeT = 1 - Math.pow(1 - t, 3) // ease-out cubic

    camera.position.lerpVectors(startPos, targetPos, easeT)
    controls.target.lerpVectors(startTarget, lookAt, easeT)
    controls.update()

    if (t < 1) {
      requestAnimationFrame(step)
    }
  }
  step()
}

function closePopup() {
  popupField.value = null
  popupAlert.value = null
  selectedFieldId.value = null
  fieldDevices.value = []
  unboundDevices.value = []
  selectedDeviceToBind.value = null
}

function goToMonitor(fieldId) {
  closePopup()
  router.push({ path: '/monitor', query: { fieldId: fieldId } })
}

async function resolveAlert(id) {
  resolving.value = true
  try {
    const res = await api.resolveAlert(id)
    if (res.code === 200) {
      ElMessage.success('告警已处理')
      closePopup()
      await loadData()
      rebuildScene()
    }
  } catch {
    // 静默处理，不弹toast
  } finally {
    resolving.value = false
  }
}

// ========== 设备类型文本 ==========
function getDeviceTypeText(type) {
  const map = {
    soil_sensor: '土壤传感器',
    temp_sensor: '温度传感器',
    humidity_sensor: '湿度传感器',
    irrigation_valve: '灌溉阀门',
    camera: '摄像头',
  }
  return map[type] || type
}

// ========== 田地管理 ==========
function handleAddField() {
  addFieldForm.value = { name: '', crop: '', area: 1000 }
  showAddFieldDialog.value = true
}

async function confirmAddField() {
  if (!addFieldForm.value.name || !addFieldForm.value.name.trim()) {
    ElMessage.warning('请输入田地名称')
    return
  }
  addFieldLoading.value = true
  try {
    const res = await api.addField({
      name: addFieldForm.value.name.trim(),
      crop: addFieldForm.value.crop.trim(),
      area: addFieldForm.value.area,
    })
    if (res.code === 200) {
      ElMessage.success('田地新增成功')
      showAddFieldDialog.value = false
      await loadData()
      rebuildScene()
    }
  } catch {
    // 静默处理，不弹toast
  } finally {
    addFieldLoading.value = false
  }
}

async function handleDeleteField() {
  if (!selectedFieldId.value) return
  const field = fields.value.find((f) => f.id === selectedFieldId.value)
  const fieldName = field ? field.name : '该田地'
  try {
    await ElMessageBox.confirm(
      `确认删除田地「${fieldName}」？该田地上的设备将自动解绑。`,
      '删除确认',
      {
        confirmButtonText: '确认删除',
        cancelButtonText: '取消',
        type: 'warning',
      }
    )
  } catch {
    return // 用户取消
  }
  try {
    const res = await api.deleteField(selectedFieldId.value)
    if (res.code === 200) {
      ElMessage.success('田地已删除')
      closePopup()
      selectedFieldId.value = null
      await loadData()
      rebuildScene()
    }
  } catch {
    // 静默处理，不弹toast
  }
}

// ========== 设备绑定管理 ==========
async function loadFieldDevices(fieldId) {
  deviceLoading.value = true
  try {
    const res = await api.getDevices()
    if (res.code === 200 && res.data) {
      const all = res.data
      fieldDevices.value = all.filter((d) => d.fieldId === fieldId)
      unboundDevices.value = all.filter((d) => d.fieldId === null || d.fieldId === undefined)
    }
  } catch {
    // 静默处理，页面显示空数据
    fieldDevices.value = []
    unboundDevices.value = []
  } finally {
    deviceLoading.value = false
  }
  selectedDeviceToBind.value = null
}

async function handleBindDevice() {
  if (!selectedDeviceToBind.value || !popupField.value) return
  try {
    const res = await api.bindDevice(selectedDeviceToBind.value, popupField.value.id)
    if (res.code === 200) {
      ElMessage.success('设备绑定成功')
      selectedDeviceToBind.value = null
      await loadFieldDevices(popupField.value.id)
    }
  } catch {
    // 静默处理，不弹toast
  }
}

async function handleUnbindDevice(deviceId) {
  try {
    const res = await api.unbindDevice(deviceId)
    if (res.code === 200) {
      ElMessage.success('设备已解绑')
      if (popupField.value) {
        await loadFieldDevices(popupField.value.id)
      }
    }
  } catch {
    // 静默处理，不弹toast
  }
}

// ========== 数据加载 ==========
async function loadData() {
  try {
    const [fieldsRes, alertsRes] = await Promise.all([
      api.getFields(),
      api.getAlerts('active'),
    ])
    if (fieldsRes.code === 200 && fieldsRes.data) {
      fields.value = fieldsRes.data
    }
    if (alertsRes.code === 200 && alertsRes.data) {
      alerts.value = alertsRes.data
    }
  } catch {
    // 静默处理，页面显示空数据
    fields.value = []
    alerts.value = []
  }
}

// ========== 场景管理 ==========
function disposeObject(obj) {
  // 清理 CSS2DObject 的 DOM 元素（田地名称标签等）
  if (obj.isCSS2DObject && obj.element && obj.element.parentNode) {
    obj.element.parentNode.removeChild(obj.element)
  }
  if (obj.geometry) obj.geometry.dispose()
  if (obj.material) {
    if (Array.isArray(obj.material)) {
      obj.material.forEach((m) => m.dispose())
    } else {
      obj.material.dispose()
    }
  }
}

function rebuildScene() {
  fieldDataMap.forEach((data) => {
    // 释放地块组资源（含 CSS2D 标签 DOM 元素）
    data.group.traverse((obj) => disposeObject(obj))
    scene.remove(data.group)

    // 释放告警标记资源
    if (data.marker) {
      data.marker.traverse((obj) => disposeObject(obj))
      scene.remove(data.marker)
    }
  })
  fieldDataMap.clear()
  createFields()
}

function disposeThree() {
  if (animationId) {
    cancelAnimationFrame(animationId)
    animationId = null
  }

  window.removeEventListener('resize', resizeHandler)

  if (renderer && renderer.domElement) {
    renderer.domElement.removeEventListener('pointerdown', pointerDownHandler)
    renderer.domElement.removeEventListener('pointerup', pointerUpHandler)
  }

  if (scene) {
    scene.traverse((obj) => disposeObject(obj))
  }

  if (renderer) {
    renderer.dispose()
    if (renderer.domElement && renderer.domElement.parentNode) {
      renderer.domElement.parentNode.removeChild(renderer.domElement)
    }
  }

  if (labelRenderer && labelRenderer.domElement && labelRenderer.domElement.parentNode) {
    labelRenderer.domElement.parentNode.removeChild(labelRenderer.domElement)
  }

  fieldDataMap.clear()
  scene = null
  camera = null
  renderer = null
  labelRenderer = null
  controls = null
}

// ========== 天气预报 ==========
function getWeatherIcon(condition) {
  const icons = { sunny: '☀️', cloudy: '⛅', rainy: '🌧️', storm: '⛈️', overcast: '☁️' }
  return icons[condition] || '☀️'
}

async function loadWeather() {
  try {
    const res = await api.getWeatherForecast()
    if (res.code === 200) {
      weatherData.value = res.data
    }
  } catch {
    // 静默处理
  }
}

// ========== 生命周期 ==========
onMounted(async () => {
  loading.value = true
  await loadData()
  await nextTick()
  initThree()
  loading.value = false
  loadWeather()
})

onUnmounted(() => {
  disposeThree()
})
</script>

<style scoped>
.farm-3d-container {
  width: 100%;
  height: 100%;
  position: relative;
  overflow: hidden;
  background: #87ceeb;
}

.canvas-container {
  width: 100%;
  height: 100%;
  position: absolute;
  top: 0;
  left: 0;
}

/* ===== 加载遮罩 ===== */
.loading-overlay {
  position: absolute;
  inset: 0;
  background: rgba(135, 206, 235, 0.92);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 2000;
}

.empty-overlay {
  position: absolute;
  inset: 0;
  background: rgba(240, 244, 248, 0.95);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 12px;
  z-index: 1500;
}

.empty-overlay .empty-title {
  font-size: 18px;
  font-weight: 600;
  color: #6b7280;
}

.empty-overlay .empty-desc {
  font-size: 14px;
  color: #9ca3af;
}

.loading-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16px;
  color: #fff;
  font-size: 15px;
  font-weight: 500;
}

.loading-spinner {
  width: 40px;
  height: 40px;
  border: 4px solid rgba(255, 255, 255, 0.3);
  border-top-color: #fff;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

/* ===== 浮层通用 ===== */
.overlay {
  position: absolute;
  z-index: 100;
  pointer-events: none;
}

.overlay > * {
  pointer-events: auto;
}

.overlay-tl {
  top: 20px;
  left: 20px;
}
.overlay-tr {
  top: 20px;
  right: 20px;
}
.overlay-bl {
  bottom: 20px;
  left: 20px;
}
.overlay-br {
  bottom: 20px;
  right: 20px;
}

/* 顶部居中浮层 */
.overlay-tc {
  top: 20px;
  left: 50%;
  transform: translateX(-50%);
}

/* 田地管理工具栏 */
.field-toolbar {
  display: flex;
  gap: 8px;
  background: rgba(255, 255, 255, 0.92);
  backdrop-filter: blur(10px);
  border-radius: var(--border-radius);
  padding: 8px 10px;
  box-shadow: var(--shadow-md);
  border: 1px solid rgba(255, 255, 255, 0.5);
}

/* ===== 标题卡片 ===== */
.title-card {
  background: rgba(255, 255, 255, 0.92);
  backdrop-filter: blur(10px);
  border-radius: var(--border-radius);
  padding: 14px 20px;
  box-shadow: var(--shadow-md);
  border: 1px solid rgba(255, 255, 255, 0.5);
}

.title {
  font-size: 18px;
  font-weight: 700;
  color: var(--primary-dark);
  margin: 0;
  letter-spacing: 0.5px;
}

.subtitle {
  font-size: 12px;
  color: var(--text-secondary);
  margin-top: 4px;
}

/* ===== 图例卡片 ===== */
.legend-card {
  background: rgba(255, 255, 255, 0.92);
  backdrop-filter: blur(10px);
  border-radius: var(--border-radius);
  padding: 14px 16px;
  box-shadow: var(--shadow-md);
  border: 1px solid rgba(255, 255, 255, 0.5);
  min-width: 130px;
}

.card-header {
  font-size: 13px;
  font-weight: 600;
  color: var(--text-primary);
  margin-bottom: 10px;
  padding-bottom: 8px;
  border-bottom: 1px solid var(--border-color);
}

.legend-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.legend-row {
  display: flex;
  align-items: center;
  gap: 8px;
}

.legend-dot {
  width: 12px;
  height: 12px;
  border-radius: 50%;
  flex-shrink: 0;
}

.legend-text {
  font-size: 13px;
  color: var(--text-primary);
}

/* ===== 地块列表 ===== */
.field-list-card {
  background: rgba(255, 255, 255, 0.92);
  backdrop-filter: blur(10px);
  border-radius: var(--border-radius);
  padding: 14px 0;
  box-shadow: var(--shadow-md);
  border: 1px solid rgba(255, 255, 255, 0.5);
  width: 240px;
  max-height: 340px;
  display: flex;
  flex-direction: column;
}

.field-list-card .card-header {
  padding: 0 16px;
  margin-bottom: 8px;
}

.field-list-body {
  overflow-y: auto;
  padding: 0 8px;
}

.field-list-row {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 10px;
  border-radius: 8px;
  cursor: pointer;
  transition: background 0.2s ease;
}

.field-list-row:hover {
  background: var(--primary-bg);
}

.field-list-active {
  background: var(--primary-bg);
}

.field-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  flex-shrink: 0;
  box-shadow: 0 0 6px currentColor;
}

.field-info {
  display: flex;
  flex-direction: column;
  flex: 1;
  min-width: 0;
}

.field-list-name {
  font-size: 13px;
  font-weight: 500;
  color: var(--text-primary);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.field-list-crop {
  font-size: 11px;
  color: var(--text-secondary);
  margin-top: 1px;
}

.field-alert-icon {
  color: var(--danger);
  font-size: 16px;
  flex-shrink: 0;
  animation: alert-blink 1s ease-in-out infinite;
}

@keyframes alert-blink {
  0%,
  100% {
    opacity: 1;
  }
  50% {
    opacity: 0.4;
  }
}

/* ===== 告警徽标 ===== */
.alert-badge-card {
  position: relative;
  background: var(--danger);
  border-radius: var(--border-radius);
  padding: 14px 20px;
  box-shadow: 0 4px 20px rgba(239, 68, 68, 0.4);
  display: flex;
  align-items: center;
  gap: 12px;
  overflow: hidden;
}

.alert-badge-pulse {
  position: absolute;
  top: 50%;
  left: 50%;
  width: 100%;
  height: 100%;
  border-radius: 50%;
  background: rgba(239, 68, 68, 0.4);
  transform: translate(-50%, -50%) scale(1);
  animation: badge-pulse 2s ease-out infinite;
}

.alert-badge-pulse-2 {
  animation-delay: 1s;
}

@keyframes badge-pulse {
  0% {
    transform: translate(-50%, -50%) scale(1);
    opacity: 0.6;
  }
  100% {
    transform: translate(-50%, -50%) scale(2.2);
    opacity: 0;
  }
}

.alert-badge-content {
  position: relative;
  display: flex;
  align-items: center;
  gap: 12px;
  z-index: 1;
}

.alert-badge-icon {
  font-size: 28px;
  color: #fff;
}

.alert-badge-info {
  display: flex;
  flex-direction: column;
  line-height: 1.2;
}

.alert-badge-count {
  font-size: 24px;
  font-weight: 700;
  color: #fff;
}

.alert-badge-label {
  font-size: 12px;
  color: rgba(255, 255, 255, 0.85);
}

/* ===== 告警弹窗 ===== */
.alert-popup {
  position: absolute;
  transform: translate(-50%, calc(-100% - 15px));
  background: #fff;
  border-radius: var(--border-radius);
  box-shadow: var(--shadow-lg);
  border: 1px solid var(--border-color);
  width: 280px;
  z-index: 500;
  pointer-events: auto;
}

.popup-arrow {
  position: absolute;
  bottom: -8px;
  left: 50%;
  transform: translateX(-50%) rotate(45deg);
  width: 16px;
  height: 16px;
  background: #fff;
  border-right: 1px solid var(--border-color);
  border-bottom: 1px solid var(--border-color);
}

.popup-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 16px;
  border-bottom: 1px solid var(--border-color);
}

.popup-title-area {
  display: flex;
  align-items: center;
  gap: 8px;
}

.popup-status-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  box-shadow: 0 0 6px currentColor;
}

.popup-title {
  font-size: 14px;
  font-weight: 600;
  color: var(--text-primary);
}

.popup-close {
  cursor: pointer;
  color: var(--text-tertiary);
  font-size: 16px;
  display: flex;
  align-items: center;
  transition: color 0.2s;
}

.popup-close:hover {
  color: var(--danger);
}

.popup-body {
  padding: 12px 16px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.popup-row {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  font-size: 13px;
}

.popup-label {
  color: var(--text-secondary);
  white-space: nowrap;
  min-width: 56px;
}

.popup-value {
  color: var(--text-primary);
  flex: 1;
  word-break: break-all;
}

.popup-footer {
  padding: 10px 16px;
  border-top: 1px solid var(--border-color);
  display: flex;
  justify-content: flex-end;
}

.popup-footer-monitor {
  border-top: 1px solid rgba(0, 0, 0, 0.06);
  padding-top: 10px;
  margin-top: 4px;
}

/* ===== 弹窗设备绑定区 ===== */
.popup-device-section {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin-top: 4px;
}

.popup-device-divider {
  height: 1px;
  background: var(--border-color);
  margin: 4px 0 2px;
}

.popup-device-title {
  align-items: center;
}

.popup-device-count {
  font-size: 12px;
  color: var(--text-secondary);
  margin-left: auto;
}

.popup-device-empty,
.popup-device-hint {
  font-size: 12px;
  color: var(--text-tertiary);
  padding: 4px 0;
  text-align: center;
}

.popup-device-list {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.popup-device-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  padding: 6px 8px;
  background: var(--primary-bg);
  border-radius: 6px;
}

.popup-device-info {
  display: flex;
  flex-direction: column;
  min-width: 0;
  flex: 1;
}

.popup-device-name {
  font-size: 12px;
  font-weight: 500;
  color: var(--text-primary);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.popup-device-meta {
  font-size: 11px;
  color: var(--text-secondary);
  margin-top: 1px;
}

.popup-bind-row {
  display: flex;
  align-items: center;
  gap: 8px;
}

.popup-bind-select {
  flex: 1;
}

/* ===== 过渡动画 ===== */
.popup-fade-enter-active,
.popup-fade-leave-active {
  transition: opacity 0.25s ease, transform 0.25s ease;
}

.popup-fade-enter-from,
.popup-fade-leave-to {
  opacity: 0;
  transform: translate(-50%, calc(-100% - 5px));
}

.badge-fade-enter-active,
.badge-fade-leave-active {
  transition: opacity 0.3s ease, transform 0.3s ease;
}

.badge-fade-enter-from,
.badge-fade-leave-to {
  opacity: 0;
  transform: scale(0.8);
}

/* ===== 天气预报卡片（3D模式） ===== */
.weather-card-3d {
  margin-top: 12px;
  background: rgba(255, 255, 255, 0.92);
  backdrop-filter: blur(8px);
  border-radius: 12px;
  padding: 14px 16px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.1);
  min-width: 200px;
}

.weather-3d-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 10px;
}

.weather-3d-title {
  font-size: 13px;
  font-weight: 600;
  color: #1f2937;
}

.weather-3d-update {
  font-size: 12px;
  color: #6b7280;
}

.weather-3d-current {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 10px;
}

.weather-3d-icon {
  font-size: 36px;
  line-height: 1;
}

.weather-3d-info {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.weather-3d-temp {
  font-size: 22px;
  font-weight: 700;
  color: #1f2937;
  line-height: 1;
}

.weather-3d-detail {
  font-size: 11px;
  color: #6b7280;
}

.weather-3d-forecast {
  display: flex;
  gap: 6px;
  border-top: 1px solid #e5e7eb;
  padding-top: 10px;
}

.weather-3d-forecast-item {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
}

.w3d-day {
  font-size: 11px;
  font-weight: 600;
  color: #4b5563;
}

.w3d-icon {
  font-size: 20px;
  line-height: 1;
}

.w3d-temp {
  font-size: 11px;
  color: #6b7280;
}
</style>

<!-- 非 scoped 样式：CSS2DObject 标签是动态创建的，不受 scoped 限制 -->
<style>
.field-3d-label {
  background: rgba(255, 255, 255, 0.92);
  backdrop-filter: blur(8px);
  padding: 5px 12px;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
  border: 1px solid rgba(22, 163, 74, 0.2);
  pointer-events: none;
  text-align: center;
  transform: translateY(-50%);
  white-space: nowrap;
}

.field-3d-label-name {
  font-size: 13px;
  font-weight: 600;
  color: #15803d;
  line-height: 1.3;
}

.field-3d-label-crop {
  font-size: 11px;
  color: #6b7280;
  margin-top: 1px;
}
</style>
