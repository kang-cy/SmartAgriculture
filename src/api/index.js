/**
 * API 统一出口
 * 当前使用 Mock 数据，后端开发完成后将 USE_MOCK 设为 false
 */
import { mockApi } from './mock'
import request from './request'

const USE_MOCK = false

// 真实接口定义（后端开发完成后启用）
const realApi = {
  login: (data) => request.post('/auth/login', data),
  register: (data) => request.post('/auth/register', data),
  getFields: () => request.get('/fields'),
  getField: (id) => request.get(`/fields/${id}`),
  addField: (data) => request.post('/fields', data),
  deleteField: (id) => request.delete(`/fields/${id}`),
  getDevices: () => request.get('/devices'),
  bindDevice: (deviceId, fieldId) => request.post('/devices/bind', { deviceId, fieldId }),
  unbindDevice: (deviceId) => request.post('/devices/unbind', { deviceId }),
  deleteDevice: (deviceId) => request.delete(`/devices/${deviceId}`),
  addDevice: (data) => request.post('/devices', data),
  getDeviceTypes: () => request.get('/device-types'),
  addDeviceType: (label) => request.post('/device-types', { label }),
  getAlerts: (status) => request.get('/alerts', { params: { status } }),
  resolveAlert: (id) => request.put(`/alerts/${id}/resolve`),
  getThresholds: (fieldId) => request.get(`/thresholds/${fieldId}`),
  updateThresholds: (fieldId, data) => request.put(`/thresholds/${fieldId}`, data),
  getIrrigationState: (fieldId) => request.get(`/irrigation/${fieldId}/state`),
  controlIrrigation: (fieldId, action, durationMinutes) => request.post(`/irrigation/${fieldId}/control`, { action, durationMinutes }),
  getHistoryData: (fieldId, days) => request.get(`/data/history/${fieldId}`, { params: { days } }),
  aiChat: (message) => request.post('/ai/chat', { message }),
  getStats: () => request.get('/stats'),
  // 绑定申请-审批流程
  submitBindRequest: (bindCode, farmerName) => request.post('/bind/request', { bindCode, farmerName }),
  getMyBindRequest: () => request.get('/bind/my-request'),
  getBindRequests: (status) => request.get('/bind/requests', { params: { status } }),
  approveBindRequest: (requestId) => request.put(`/bind/requests/${requestId}/approve`),
  rejectBindRequest: (requestId, reason) => request.put(`/bind/requests/${requestId}/reject`, { reason }),
  // 农户申请成为管理员
  applyManager: (data) => request.post('/auth/apply-manager', data),
  getMyManagerApplication: () => request.get('/auth/my-manager-application'),
  // 取消管理员申请
  cancelManagerApplication: () => request.delete('/auth/my-manager-application'),
  // 农场主审批管理者申请
  getManagerApplications: (status) => request.get('/auth/manager-applications', { params: { status } }),
  approveManagerApplication: (appId) => request.put(`/auth/manager-applications/${appId}/approve`),
  rejectManagerApplication: (appId, reason) => request.put(`/auth/manager-applications/${appId}/reject`, { reason }),
  // 农场主管理手下管理者（查看/撤销）
  getSubManagers: () => request.get('/auth/sub-managers'),
  revokeManager: (managerId) => request.delete(`/auth/sub-managers/${managerId}`),
  // 更新农场名称（仅管理者）
  updateFarmName: (name) => request.put('/users/farm-name', { name }),
  // 天气预报
  getWeatherForecast: () => request.get('/weather/forecast'),
}

export const api = USE_MOCK ? mockApi : realApi
