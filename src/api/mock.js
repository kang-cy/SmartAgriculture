/**
 * Mock 数据层 - 模拟后端接口返回
 * 后端开发完成后，将 USE_MOCK 设为 false 即可切换到真实接口
 */

// ===== 模拟数据 =====

const mockFields = [
  { id: 1, name: 'A区-温室大棚1号', crop: '番茄', area: 1200, managerId: 'M001', managerName: '张管理', status: 'normal', soilMoisture: 45, temperature: 26.5, humidity: 68, deviceId: 'DEV-A001' },
  { id: 2, name: 'A区-温室大棚2号', crop: '黄瓜', area: 980, managerId: 'M001', managerName: '张管理', status: 'warning', soilMoisture: 22, temperature: 31.2, humidity: 55, deviceId: 'DEV-A002' },
  { id: 3, name: 'B区-露天菜地1号', crop: '白菜', area: 2400, managerId: 'M001', managerName: '张管理', status: 'normal', soilMoisture: 52, temperature: 24.8, humidity: 72, deviceId: 'DEV-B001' },
  { id: 4, name: 'B区-露天菜地2号', crop: '辣椒', area: 1800, managerId: 'M001', managerName: '张管理', status: 'danger', soilMoisture: 15, temperature: 35.6, humidity: 40, deviceId: 'DEV-B002' },
  { id: 5, name: 'C区-果园1号', crop: '草莓', area: 1500, managerId: 'M001', managerName: '张管理', status: 'normal', soilMoisture: 48, temperature: 25.3, humidity: 65, deviceId: 'DEV-C001' },
  { id: 6, name: 'C区-果园2号', crop: '蓝莓', area: 1100, managerId: 'M001', managerName: '张管理', status: 'offline', soilMoisture: 0, temperature: 0, humidity: 0, deviceId: 'DEV-C002' },
]

// 预设设备类型（value 为标识，label 为显示名称，可扩展）
const mockDeviceTypes = [
  { value: 'soil_sensor', label: '土壤传感器' },
  { value: 'temp_sensor', label: '温度传感器' },
  { value: 'humidity_sensor', label: '湿度传感器' },
  { value: 'irrigation_valve', label: '灌溉阀门' },
  { value: 'camera', label: '摄像头' },
]

const mockDevices = [
  { id: 'DEV-A001', name: '土壤传感器-A001', type: 'soil_sensor', fieldId: 1, fieldName: 'A区-温室大棚1号', status: 'online', battery: 85, lastReport: '2026-08-04 10:30:00' },
  { id: 'DEV-A002', name: '土壤传感器-A002', type: 'soil_sensor', fieldId: 2, fieldName: 'A区-温室大棚2号', status: 'online', battery: 62, lastReport: '2026-08-04 10:29:55' },
  { id: 'DEV-A003', name: '温度传感器-A003', type: 'temp_sensor', fieldId: 1, fieldName: 'A区-温室大棚1号', status: 'online', battery: 90, lastReport: '2026-08-04 10:30:02' },
  { id: 'DEV-B001', name: '土壤传感器-B001', type: 'soil_sensor', fieldId: 3, fieldName: 'B区-露天菜地1号', status: 'online', battery: 78, lastReport: '2026-08-04 10:30:01' },
  { id: 'DEV-B002', name: '土壤传感器-B002', type: 'soil_sensor', fieldId: 4, fieldName: 'B区-露天菜地2号', status: 'online', battery: 35, lastReport: '2026-08-04 10:29:58' },
  { id: 'DEV-B003', name: '灌溉阀门-B003', type: 'irrigation_valve', fieldId: 3, fieldName: 'B区-露天菜地1号', status: 'online', battery: 95, lastReport: '2026-08-04 10:30:00' },
  { id: 'DEV-C001', name: '土壤传感器-C001', type: 'soil_sensor', fieldId: 5, fieldName: 'C区-果园1号', status: 'online', battery: 88, lastReport: '2026-08-04 10:30:03' },
  { id: 'DEV-C002', name: '土壤传感器-C002', type: 'soil_sensor', fieldId: 6, fieldName: 'C区-果园2号', status: 'offline', battery: 0, lastReport: '2026-08-03 18:22:14' },
  { id: 'DEV-UNBIND-001', name: '未绑定传感器-001', type: 'soil_sensor', fieldId: null, fieldName: null, status: 'online', battery: 100, lastReport: '2026-08-04 10:28:00' },
  { id: 'DEV-UNBIND-002', name: '未绑定灌溉阀-002', type: 'irrigation_valve', fieldId: null, fieldName: null, status: 'online', battery: 100, lastReport: '2026-08-04 10:27:00' },
  { id: 'DEV-CAM-001', name: '监控摄像头-A区1号', type: 'camera', fieldId: 1, fieldName: 'A区-温室大棚1号', status: 'online', battery: 92, lastReport: '2026-08-04 10:30:00' },
  { id: 'DEV-CAM-002', name: '监控摄像头-B区1号', type: 'camera', fieldId: 3, fieldName: 'B区-露天菜地1号', status: 'online', battery: 80, lastReport: '2026-08-04 10:29:50' },
  { id: 'DEV-UNBIND-CAM-001', name: '未绑定摄像头-001', type: 'camera', fieldId: null, fieldName: null, status: 'online', battery: 100, lastReport: '2026-08-04 10:25:00' },
]

const mockAlerts = [
  { id: 1, fieldId: 2, fieldName: 'A区-温室大棚2号', type: 'low_moisture', level: 'warning', message: '土壤湿度低于阈值 (当前: 22%, 阈值: 30%)', time: '2026-08-04 09:15:22', status: 'active' },
  { id: 2, fieldId: 4, fieldName: 'B区-露天菜地2号', type: 'low_moisture', level: 'danger', message: '土壤湿度严重偏低 (当前: 15%, 阈值: 30%)', time: '2026-08-04 08:42:10', status: 'active' },
  { id: 3, fieldId: 4, fieldName: 'B区-露天菜地2号', type: 'high_temp', level: 'danger', message: '温度超过警戒值 (当前: 35.6°C, 阈值: 35°C)', time: '2026-08-04 08:42:12', status: 'active' },
  { id: 4, fieldId: 6, fieldName: 'C区-果园2号', type: 'device_offline', level: 'warning', message: '设备 DEV-C002 已离线超过12小时', time: '2026-08-04 06:30:00', status: 'active' },
  { id: 5, fieldId: 2, fieldName: 'A区-温室大棚2号', type: 'low_moisture', level: 'warning', message: '土壤湿度低于阈值 (当前: 28%, 阈值: 30%)', time: '2026-08-03 16:20:00', status: 'resolved' },
  { id: 6, fieldId: 1, fieldName: 'A区-温室大棚1号', type: 'low_battery', level: 'info', message: '设备 DEV-A002 电量低于70%', time: '2026-08-03 14:10:00', status: 'resolved' },
]

const mockThresholds = {
  1: { soilMoistureMin: 30, soilMoistureMax: 80, tempMin: 5, tempMax: 35 },
  2: { soilMoistureMin: 30, soilMoistureMax: 80, tempMin: 5, tempMax: 35 },
  3: { soilMoistureMin: 25, soilMoistureMax: 75, tempMin: 5, tempMax: 38 },
  4: { soilMoistureMin: 30, soilMoistureMax: 80, tempMin: 5, tempMax: 35 },
  5: { soilMoistureMin: 35, soilMoistureMax: 85, tempMin: 5, tempMax: 32 },
  6: { soilMoistureMin: 35, soilMoistureMax: 85, tempMin: 5, tempMax: 32 },
}

const mockIrrigationState = {
  1: false,
  2: false,
  3: false,
  4: true,
  5: false,
  6: false,
}

// 生成历史趋势数据
function generateHistoryData(days = 7) {
  const result = []
  const now = new Date()
  for (let i = days - 1; i >= 0; i--) {
    const date = new Date(now)
    date.setDate(date.getDate() - i)
    const dateStr = `${date.getMonth() + 1}/${date.getDate()}`
    result.push({
      date: dateStr,
      soilMoisture: 35 + Math.round(Math.random() * 30),
      temperature: Math.round((20 + Math.random() * 12) * 10) / 10,
      humidity: 55 + Math.round(Math.random() * 25),
    })
  }
  return result
}

// 绑定申请记录（申请-审批流程）
const mockBindRequests = [
  { id: 1, bindCode: 'AGX8K2M', farmerName: '李农户', farmerUserId: 'F002', managerName: '张管理', managerUserId: 'M001', status: 'pending', requestTime: '2026-08-04 09:30:00', resolveTime: null, remark: '申请绑定A区温室大棚' },
  { id: 2, bindCode: 'AGP3N7Q', farmerName: '王农', farmerUserId: 'F003', managerName: '张管理', managerUserId: 'M001', status: 'approved', requestTime: '2026-08-03 14:20:00', resolveTime: '2026-08-03 16:10:00', remark: '申请绑定B区露天菜地' },
  { id: 3, bindCode: 'AGL9R4T', farmerName: '赵种植', farmerUserId: 'F004', managerName: '张管理', managerUserId: 'M001', status: 'rejected', requestTime: '2026-08-02 10:15:00', resolveTime: '2026-08-02 11:30:00', remark: '绑定码已过期，请重新生成' },
]

// 农户申请成为管理者的记录（仅农场主可审批）
// type: 'manager' = 申请成为管理者（需要农场主审批）, 'self_managed' = 自主成为农场主（注册模式，无需审批）
const mockManagerApplications = [
  { id: 101, type: 'manager', farmerName: '李农户', farmerUserId: 'F002', reason: '拥有3年农田管理经验，希望协助管理更多农田', status: 'pending', requestTime: '2026-08-04 10:00:00', resolveTime: null, remark: '' },
  { id: 102, type: 'manager', farmerName: '王农', farmerUserId: 'F003', reason: '自家农田规模扩大，需要管理者权限来管理设备', status: 'approved', requestTime: '2026-08-03 15:00:00', resolveTime: '2026-08-03 17:00:00', remark: '' },
]

// 农场主手下的管理者列表（已审批通过的管理者）
const mockSubManagers = [
  { id: 1, managerName: '王农', managerUserId: 'M002', originalFarmerId: 'F003', farmOwnerUserId: 'M001', farmOwnerName: '张管理', status: 'active', approvedTime: '2026-08-03 17:00:00' },
]

// 当前农户的绑定申请状态（模拟当前登录农户的申请）
let currentFarmerRequest = null

// 当前农户的管理者申请状态
let currentManagerApplication = null

// 当前登录用户信息
let currentUserRole = null
let currentUserId = null
let currentManagerId = null  // 农户绑定的管理者ID 或 管理者自己的ID

// 模拟智能问答
const mockAIResponses = [
  '根据当前A区-温室大棚1号的土壤湿度数据（45%），处于适宜范围。建议保持当前灌溉频率，每2天灌溉一次，每次约15分钟。',
  '当前B区-露天菜地2号土壤湿度仅为15%，严重偏低。建议立即开启灌溉系统，持续灌溉30分钟后复检湿度。同时检查是否有管道漏水情况。',
  '番茄生长的适宜土壤湿度为60%-80%，适宜温度为20-28°C。当前A区-温室大棚1号环境参数在正常范围内，继续维持当前管理即可。',
  '近期气温偏高，建议在清晨6:00-8:00或傍晚18:00-20:00进行灌溉，避免中午高温时段灌溉导致水分快速蒸发和根系受损。',
  '黄瓜在结果期需水量较大，建议土壤湿度保持在70%-85%。当前A区-温室大棚2号湿度偏低（22%），建议增加灌溉频次至每天一次。',
]

// 模拟天气预报数据
const mockWeather = {
  current: {
    temp: 28.5,
    feelsLike: 31,
    humidity: 62,
    windSpeed: 12,
    windDirection: '东南风',
    condition: 'sunny',
    conditionText: '晴',
    uvIndex: 7,
    visibility: 15,
    pressure: 1013,
    updateTime: '2026-08-05 10:30:00',
  },
  forecast: [
    { date: '08-06', dayOfWeek: '周四', condition: 'cloudy', conditionText: '多云', highTemp: 32, lowTemp: 24, wind: '东南风3级' },
    { date: '08-07', dayOfWeek: '周五', condition: 'rainy', conditionText: '小雨', highTemp: 28, lowTemp: 22, wind: '东风4级' },
    { date: '08-08', dayOfWeek: '周六', condition: 'storm', conditionText: '雷阵雨', highTemp: 26, lowTemp: 21, wind: '北风5级' },
    { date: '08-09', dayOfWeek: '周日', condition: 'overcast', conditionText: '阴', highTemp: 29, lowTemp: 23, wind: '北风3级' },
    { date: '08-10', dayOfWeek: '周一', condition: 'sunny', conditionText: '晴', highTemp: 33, lowTemp: 25, wind: '南风2级' },
  ],
}

// ===== Mock API 函数 =====

function delay(ms = 300) {
  return new Promise((resolve) => setTimeout(resolve, ms))
}

// 判断当前农户是否已绑定管理者
function isFarmerBound() {
  if (currentUserRole !== 'farmer') return true
  return currentFarmerRequest && currentFarmerRequest.status === 'approved'
}

// 获取当前用户可见的田地ID集合（数据隔离：每个田地只有对应的农场主及其手下可查看）
function getVisibleFieldIds() {
  // 管理者：只能看到自己的田地
  if (currentUserRole === 'manager') {
    return mockFields.filter(f => f.managerId === currentManagerId).map(f => f.id)
  }
  // 农户：只能看到绑定管理者的田地
  if (currentUserRole === 'farmer') {
    if (!isFarmerBound()) return []
    return mockFields.filter(f => f.managerId === currentManagerId).map(f => f.id)
  }
  return []
}

// 获取当前用户可见的田地列表
function getVisibleFields() {
  return mockFields.filter(f => getVisibleFieldIds().includes(f.id))
}

// 获取当前用户可见的设备列表
function getVisibleDevices() {
  const visibleIds = getVisibleFieldIds()
  return mockDevices.filter(d => d.fieldId === null || visibleIds.includes(d.fieldId))
}

// 获取当前用户可见的告警列表
function getVisibleAlerts() {
  const visibleIds = getVisibleFieldIds()
  return mockAlerts.filter(a => visibleIds.includes(a.fieldId))
}

export const mockApi = {
  // 登录
  async login({ username, password, role }) {
    await delay(500)
    // 用户名格式校验：不允许中文
    if (username && !/^[a-zA-Z0-9_]+$/.test(username)) {
      return { code: 400, message: '用户名只能包含字母、数字和下划线，不能使用中文' }
    }
    // 模拟验证
    if (password.length < 3) {
      return { code: 400, message: '密码长度不足' }
    }
    // 记录当前用户信息，登录时从模拟数据恢复绑定状态
    currentUserRole = role
    currentUserId = role === 'farmer' ? 'F001' : 'M001'
    currentManagerId = role === 'manager' ? 'M001' : null
    const existingRequest = mockBindRequests.find((r) => r.farmerUserId === 'F001')
    currentFarmerRequest = existingRequest || null
    if (currentFarmerRequest && currentFarmerRequest.status === 'approved') {
      currentManagerId = currentFarmerRequest.managerUserId
    }
    // 恢复管理者申请状态
    currentManagerApplication = mockManagerApplications.find((a) => a.farmerUserId === 'F001') || null
    return {
      code: 200,
      data: {
        token: `mock-token-${role}-${Date.now()}`,
        role,
        username,
        userId: role === 'farmer' ? 'F001' : 'M001',
        farmName: role === 'farmer' ? '张三的农场' : '绿源生态农场',
      },
    }
  },

  // 注册
  async register({ username, password, role, farmName }) {
    await delay(600)
    if (!username || username.length < 2) {
      return { code: 400, message: '用户名至少2个字符' }
    }
    // 用户名格式校验：不允许中文
    if (!/^[a-zA-Z0-9_]+$/.test(username)) {
      return { code: 400, message: '用户名只能包含字母、数字和下划线，不能使用中文' }
    }
    if (!password || password.length < 6) {
      return { code: 400, message: '密码至少6位' }
    }
    // 记录当前用户信息，注册时创建新的独立账号
    currentUserRole = role
    const newUserId = role === 'farmer' ? `F${Date.now().toString().slice(-4)}` : `M${Date.now().toString().slice(-4)}`
    currentUserId = newUserId
    currentManagerId = role === 'manager' ? newUserId : null
    currentFarmerRequest = null
    currentManagerApplication = null
    // 模拟注册成功，自动登录
    return {
      code: 200,
      data: {
        token: `mock-token-${role}-${Date.now()}`,
        role,
        username,
        userId: role === 'farmer' ? `F${Date.now().toString().slice(-4)}` : `M${Date.now().toString().slice(-4)}`,
        farmName: farmName || (role === 'farmer' ? `${username}的农场` : `${username}的农场`),
      },
      message: '注册成功',
    }
  },

  // 新增田地
  async addField(data) {
    await delay(400)
    const newId = Math.max(...mockFields.map(f => f.id)) + 1
    const newField = {
      id: newId,
      name: data.name,
      crop: data.crop || '未指定',
      area: data.area || 1000,
      managerId: currentManagerId || 'M001',
      managerName: '当前管理者',
      status: 'normal',
      soilMoisture: 50,
      temperature: 25.0,
      humidity: 65,
      deviceId: null,
    }
    mockFields.push(newField)
    // 同步添加阈值配置
    mockThresholds[newId] = { soilMoistureMin: 30, soilMoistureMax: 80, tempMin: 5, tempMax: 35 }
    return { code: 200, data: newField, message: '田地添加成功' }
  },

  // 删除田地
  async deleteField(id) {
    await delay(400)
    const idx = mockFields.findIndex(f => f.id === Number(id))
    if (idx !== -1) {
      const removed = mockFields.splice(idx, 1)[0]
      // 解绑该田地上的所有设备
      mockDevices.forEach(d => {
        if (d.fieldId === removed.id) {
          d.fieldId = null
          d.fieldName = null
        }
      })
    }
    return { code: 200, message: '田地已删除' }
  },

  // 获取地块列表（数据隔离：只返回当前用户有权查看的地块）
  async getFields() {
    await delay()
    if (!isFarmerBound()) return { code: 200, data: [] }
    return { code: 200, data: getVisibleFields() }
  },

  // 获取单个地块详情
  async getField(id) {
    await delay()
    if (!isFarmerBound()) return { code: 200, data: null }
    const visibleIds = getVisibleFieldIds()
    if (!visibleIds.includes(Number(id))) return { code: 200, data: null }
    const field = mockFields.find((f) => f.id === Number(id))
    return { code: 200, data: field }
  },

  // 获取设备列表（数据隔离）
  async getDevices() {
    await delay()
    if (!isFarmerBound()) return { code: 200, data: [] }
    return { code: 200, data: getVisibleDevices() }
  },

  // 绑定设备到地块
  async bindDevice(deviceId, fieldId) {
    await delay(400)
    const device = mockDevices.find((d) => d.id === deviceId)
    const field = mockFields.find((f) => f.id === fieldId)
    if (device && field) {
      device.fieldId = fieldId
      device.fieldName = field.name
    }
    return { code: 200, message: '设备绑定成功' }
  },

  // 解绑设备
  async unbindDevice(deviceId) {
    await delay(400)
    const device = mockDevices.find((d) => d.id === deviceId)
    if (device) {
      device.fieldId = null
      device.fieldName = null
    }
    return { code: 200, message: '设备解绑成功' }
  },

  // 删除设备
  async deleteDevice(deviceId) {
    await delay(400)
    const idx = mockDevices.findIndex((d) => d.id === deviceId)
    if (idx !== -1) {
      mockDevices.splice(idx, 1)
    }
    return { code: 200, message: '设备已删除' }
  },

  // 添加新设备
  async addDevice(data) {
    await delay(400)
    const newDevice = {
      id: `DEV-${Date.now()}`,
      name: data.name,
      type: data.type,
      fieldId: null,
      fieldName: null,
      status: 'online',
      battery: 100,
      lastReport: new Date().toLocaleString('zh-CN'),
    }
    mockDevices.push(newDevice)
    return { code: 200, data: newDevice, message: '设备添加成功' }
  },

  // 获取设备类型列表
  async getDeviceTypes() {
    await delay(200)
    return { code: 200, data: mockDeviceTypes }
  },

  // 添加自定义设备类型
  async addDeviceType(label) {
    await delay(300)
    const trimmed = label.trim()
    // 查重：label 或 value 已存在则跳过
    const exists = mockDeviceTypes.some(
      (t) => t.label === trimmed || t.value === trimmed,
    )
    if (exists) {
      return { code: 200, data: mockDeviceTypes, message: '类型已存在' }
    }
    const newType = { value: trimmed, label: trimmed }
    mockDeviceTypes.push(newType)
    return { code: 200, data: mockDeviceTypes, message: '设备类型添加成功' }
  },

  // 获取告警列表（数据隔离）
  async getAlerts(status) {
    await delay()
    if (!isFarmerBound()) return { code: 200, data: [] }
    let alerts = getVisibleAlerts()
    if (status) {
      alerts = alerts.filter((a) => a.status === status)
    }
    return { code: 200, data: alerts }
  },

  // 处理告警
  async resolveAlert(id) {
    await delay(300)
    const alert = mockAlerts.find((a) => a.id === id)
    if (alert) {
      alert.status = 'resolved'
    }
    return { code: 200, message: '告警已处理' }
  },

  // 获取阈值配置
  async getThresholds(fieldId) {
    await delay()
    return { code: 200, data: mockThresholds[fieldId] || mockThresholds[1] }
  },

  // 更新阈值
  async updateThresholds(fieldId, data) {
    await delay(400)
    mockThresholds[fieldId] = data
    return { code: 200, message: '阈值更新成功' }
  },

  // 获取灌溉状态
  async getIrrigationState(fieldId) {
    await delay()
    return { code: 200, data: { active: mockIrrigationState[fieldId] || false } }
  },

  // 控制灌溉
  async controlIrrigation(fieldId, action, durationMinutes) {
    await delay(500)
    mockIrrigationState[fieldId] = action === 'on'
    return { code: 200, message: action === 'on' ? '灌溉已开启' : '灌溉已关闭' }
  },

  // 获取历史数据
  async getHistoryData(fieldId, days = 7) {
    await delay()
    if (!isFarmerBound()) return { code: 200, data: [] }
    return { code: 200, data: generateHistoryData(days) }
  },

  // 智能问答
  async aiChat(message) {
    await delay(800)
    const response = mockAIResponses[Math.floor(Math.random() * mockAIResponses.length)]
    return { code: 200, data: { reply: response } }
  },

  // 获取统计数据（数据隔离）
  async getStats() {
    await delay()
    if (!isFarmerBound()) {
      return {
        code: 200,
        data: {
          totalFields: 0,
          totalDevices: 0,
          onlineDevices: 0,
          activeAlerts: 0,
          warningFields: 0,
          avgMoisture: 0,
          avgTemp: 0,
        },
      }
    }
    const visibleFields = getVisibleFields()
    const visibleDevices = getVisibleDevices()
    const visibleAlertsList = getVisibleAlerts()
    const onlineDevices = visibleDevices.filter((d) => d.status === 'online').length
    const activeAlerts = visibleAlertsList.filter((a) => a.status === 'active').length
    const warningFields = visibleFields.filter((f) => f.status === 'warning' || f.status === 'danger').length
    const moistureFields = visibleFields.filter(f => f.soilMoisture > 0)
    const tempFields = visibleFields.filter(f => f.temperature > 0)
    return {
      code: 200,
      data: {
        totalFields: visibleFields.length,
        totalDevices: visibleDevices.length,
        onlineDevices,
        activeAlerts,
        warningFields,
        avgMoisture: moistureFields.length > 0 ? Math.round(moistureFields.reduce((sum, f) => sum + f.soilMoisture, 0) / moistureFields.length) : 0,
        avgTemp: tempFields.length > 0 ? Math.round(tempFields.reduce((sum, f) => sum + f.temperature, 0) / tempFields.length * 10) / 10 : 0,
      },
    }
  },

  // 农户提交绑定申请（不直接绑定，需要管理者审批）
  async submitBindRequest(bindCode, farmerName) {
    await delay(500)
    // 验证绑定码格式
    if (!bindCode || bindCode.length < 4) {
      return { code: 400, message: '绑定码格式不正确' }
    }
    // 检查是否已有待审批的申请
    if (currentFarmerRequest && currentFarmerRequest.status === 'pending') {
      return { code: 400, message: '您已有一个待审批的申请，请等待管理者处理' }
    }
    // 创建申请记录
    const newRequest = {
      id: Date.now(),
      bindCode,
      farmerName: farmerName || '当前农户',
      farmerUserId: 'F001',
      managerName: '张管理',
      managerUserId: 'M001',
      status: 'pending',
      requestTime: new Date().toLocaleString('zh-CN', { hour12: false }),
      resolveTime: null,
      remark: '',
    }
    mockBindRequests.unshift(newRequest)
    currentFarmerRequest = newRequest
    return { code: 200, data: newRequest, message: '绑定申请已提交，请等待管理者审批' }
  },

  // 农户查询自己的绑定申请状态
  async getMyBindRequest() {
    await delay(300)
    return { code: 200, data: currentFarmerRequest }
  },

  // 管理者获取绑定申请列表
  async getBindRequests(status) {
    await delay()
    let requests = [...mockBindRequests]
    if (status) {
      requests = requests.filter((r) => r.status === status)
    }
    return { code: 200, data: requests }
  },

  // 管理者审批通过
  async approveBindRequest(requestId) {
    await delay(500)
    const req = mockBindRequests.find((r) => r.id === requestId)
    if (req) {
      req.status = 'approved'
      req.resolveTime = new Date().toLocaleString('zh-CN', { hour12: false })
    }
    if (currentFarmerRequest && currentFarmerRequest.id === requestId) {
      currentFarmerRequest.status = 'approved'
      currentFarmerRequest.resolveTime = req.resolveTime
    }
    return { code: 200, message: '已同意绑定申请' }
  },

  // 管理者驳回
  async rejectBindRequest(requestId, reason) {
    await delay(500)
    const req = mockBindRequests.find((r) => r.id === requestId)
    if (req) {
      req.status = 'rejected'
      req.resolveTime = new Date().toLocaleString('zh-CN', { hour12: false })
      req.remark = reason || '驳回'
    }
    if (currentFarmerRequest && currentFarmerRequest.id === requestId) {
      currentFarmerRequest.status = 'rejected'
      currentFarmerRequest.resolveTime = req.resolveTime
      currentFarmerRequest.remark = req.remark
    }
    return { code: 200, message: '已驳回绑定申请' }
  },

  // 农户申请成为管理者（提交给农场主审批，type='manager'）
  async applyManager(data) {
    await delay(500)
    if (currentManagerApplication && currentManagerApplication.status === 'pending') {
      return { code: 400, message: '您已有一个待审批的申请，请等待审核结果' }
    }
    const newApp = {
      id: Date.now(),
      type: 'manager',
      farmerName: data.farmerName || '当前农户',
      farmerUserId: currentUserId || 'F001',
      reason: data.reason || '',
      status: 'pending',
      requestTime: new Date().toLocaleString('zh-CN', { hour12: false }),
      resolveTime: null,
      remark: '',
    }
    mockManagerApplications.unshift(newApp)
    currentManagerApplication = newApp
    return { code: 200, data: newApp, message: '管理者申请已提交，请等待农场主审核' }
  },

  // 农户查询自己的管理者申请状态
  async getMyManagerApplication() {
    await delay(300)
    return { code: 200, data: currentManagerApplication }
  },

  // 取消管理者申请
  async cancelManagerApplication() {
    await delay(400)
    if (currentManagerApplication) {
      const idx = mockManagerApplications.findIndex(a => a.id === currentManagerApplication.id)
      if (idx !== -1) mockManagerApplications.splice(idx, 1)
    }
    currentManagerApplication = null
    return { code: 200, message: '已取消申请' }
  },

  // 农场主获取管理者申请列表
  async getManagerApplications(status) {
    await delay()
    let apps = [...mockManagerApplications]
    if (status) {
      apps = apps.filter((a) => a.status === status)
    }
    return { code: 200, data: apps }
  },

  // 农场主审批通过管理者申请
  async approveManagerApplication(appId) {
    await delay(500)
    const app = mockManagerApplications.find((a) => a.id === appId)
    if (!app) return { code: 400, message: '申请不存在' }
    app.status = 'approved'
    app.resolveTime = new Date().toLocaleString('zh-CN', { hour12: false })
    // 添加到管理者列表
    const newManagerId = `M${Date.now().toString().slice(-4)}`
    mockSubManagers.push({
      id: Date.now(),
      managerName: app.farmerName,
      managerUserId: newManagerId,
      originalFarmerId: app.farmerUserId,
      farmOwnerUserId: currentUserId,
      farmOwnerName: '当前农场主',
      status: 'active',
      approvedTime: app.resolveTime,
    })
    if (currentManagerApplication && currentManagerApplication.id === appId) {
      currentManagerApplication.status = 'approved'
      currentManagerApplication.resolveTime = app.resolveTime
    }
    return { code: 200, message: '已同意管理者申请' }
  },

  // 农场主驳回管理者申请
  async rejectManagerApplication(appId, reason) {
    await delay(500)
    const app = mockManagerApplications.find((a) => a.id === appId)
    if (!app) return { code: 400, message: '申请不存在' }
    app.status = 'rejected'
    app.resolveTime = new Date().toLocaleString('zh-CN', { hour12: false })
    app.remark = reason || '驳回'
    if (currentManagerApplication && currentManagerApplication.id === appId) {
      currentManagerApplication.status = 'rejected'
      currentManagerApplication.resolveTime = app.resolveTime
      currentManagerApplication.remark = app.remark
    }
    return { code: 200, message: '已驳回管理者申请' }
  },

  // 农场主获取手下管理者列表
  async getSubManagers() {
    await delay()
    return { code: 200, data: [...mockSubManagers] }
  },

  // 农场主撤销管理者身份（降级回农户）
  async revokeManager(managerId) {
    await delay(500)
    const idx = mockSubManagers.findIndex((m) => m.id === managerId)
    if (idx === -1) return { code: 400, message: '管理者不存在' }
    const removed = mockSubManagers.splice(idx, 1)[0]
    // 将其田地转移给农场主
    mockFields.forEach(f => {
      if (f.managerId === removed.managerUserId) {
        f.managerId = currentManagerId
        f.managerName = '当前农场主'
      }
    })
    return { code: 200, message: `已撤销${removed.managerName}的管理者身份` }
  },

  // 更新农场名称（仅管理者）
  async updateFarmName(name) {
    await delay(400)
    return { code: 200, message: '农场名称已更新' }
  },

  // 获取天气预报数据
  async getWeatherForecast() {
    await delay(400)
    return { code: 200, data: mockWeather }
  },
}
