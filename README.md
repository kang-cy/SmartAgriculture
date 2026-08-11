# 智慧农业管理平台 - 前端项目

## 项目简介

基于 Vue 3 + Vite 构建的智慧农业管理平台前端原型，支持农户和管理者双角色登录，包含实时数据监测、设备控制、3D农场可视化、智能问答、设备绑定、告警管理等功能。

## 技术栈

| 技术 | 版本 | 用途 |
|------|------|------|
| Vue 3 | ^3.4 | 前端框架（Composition API） |
| Vite | ^5.2 | 构建工具 |
| Vue Router | ^4.3 | 路由管理 |
| Pinia | ^2.1 | 状态管理 |
| Element Plus | ^2.7 | UI 组件库 |
| ECharts | ^5.5 | 数据可视化图表 |
| Three.js | ^0.164 | 3D 农场渲染 |
| Axios | ^1.6 | HTTP 请求 |

## 在 IDEA 中导入和运行

### 第一步：用 IDEA 打开项目

1. 打开 IntelliJ IDEA
2. 选择 `File` → `Open`
3. 选择 `smart-agriculture-frontend` 文件夹
4. IDEA 会识别为前端项目（确保已安装 Vue.js 插件：`File` → `Settings` → `Plugins` → 搜索 "Vue"）

### 第二步：配置 Node.js 环境

1. 确保已安装 Node.js（建议 v18 以上）
2. 在 IDEA 终端（`View` → `Tool Windows` → `Terminal`）中运行：
   ```bash
   node -v
   npm -v
   ```
3. 如果未安装 Node.js，前往 [Node.js 官网](https://nodejs.org/) 下载安装

### 第三步：安装依赖

在 IDEA 终端中执行：
```bash
npm install
```

### 第四步：启动开发服务器

```bash
npm run dev
```

启动后浏览器会自动打开 `http://localhost:5173`

### 第五步：构建生产版本

```bash
npm run build
```

构建产物输出到 `dist/` 目录，可部署到 Nginx 或其他静态服务器。

## 在 IDEA 中创建新前端项目（从零复刻）

如果你想从零创建一个相同结构的项目，按以下步骤操作：

```bash
# 1. 创建项目
npm create vite@latest smart-agriculture-frontend -- --template vue

# 2. 进入项目目录
cd smart-agriculture-frontend

# 3. 安装核心依赖
npm install vue-router@4 pinia element-plus @element-plus/icons-vue echarts axios three

# 4. 安装开发依赖
npm install -D unplugin-auto-import unplugin-vue-components

# 5. 用 IDEA 打开项目文件夹
# 6. 按照本项目目录结构创建文件
```

## 项目结构

```
smart-agriculture-frontend/
├── public/
│   └── favicon.svg              # 网站图标
├── src/
│   ├── api/
│   │   ├── index.js             # API 统一出口（Mock/真实切换）
│   │   ├── request.js           # Axios 请求封装（拦截器）
│   │   └── mock.js              # Mock 数据（模拟后端接口）
│   ├── assets/
│   │   └── styles/
│   │       └── main.css         # 全局样式 + CSS 变量主题
│   ├── layout/
│   │   └── MainLayout.vue       # 主布局（侧边栏 + 顶部栏）
│   ├── router/
│   │   └── index.js             # 路由配置（含权限守卫）
│   ├── store/
│   │   └── user.js              # 用户状态管理（Pinia）
│   ├── views/
│   │   ├── Login.vue            # 登录页（农户/管理者切换 + 绑定）
│   │   ├── Dashboard.vue        # 数据总览
│   │   ├── DataMonitor.vue      # 实时监测（温湿度 + 历史趋势 + 阈值）
│   │   ├── DeviceControl.vue    # 设备控制（灌溉开关）
│   │   ├── Farm3D.vue           # 3D农场可视化（Three.js）
│   │   ├── AlertManage.vue      # 告警管理
│   │   ├── AIChat.vue           # 智能问答（农户）
│   │   ├── DeviceBind.vue       # 设备绑定管理（管理者）
│   │   ├── AlertLog.vue         # 告警日志（管理者）
│   │   └── FieldManage.vue      # 农田管理（管理者）
│   ├── App.vue                  # 根组件
│   └── main.js                  # 应用入口
├── .env.development             # 开发环境变量
├── .env.production              # 生产环境变量
├── .gitignore
├── index.html
├── package.json
├── vite.config.js               # Vite 配置（含 API 代理）
└── README.md
```

## 功能清单与需求对应

| 需求 | 实现文件 | 说明 |
|------|----------|------|
| 登录界面农户/管理者切换 | `Login.vue` | Tab 切换角色，不同角色登录后看到不同菜单 |
| 农户和管理者通过绑定连接 | `Login.vue` | 管理者生成绑定码，农户输入绑定码完成关联 |
| 设备绑定到农田 | `DeviceBind.vue` | 管理者可将设备绑定/解绑到对应地块 |
| 3D农场 + 告警弹窗 | `Farm3D.vue` | Three.js 3D 场景，告警地块有红色脉冲标记，点击弹出告警详情 |
| 页面布局精美 | `main.css` + 所有页面 | 绿色农业主题，CSS 变量统一设计语言 |
| 实时数据监测 | `DataMonitor.vue` | 土壤湿度、温度、湿度实时展示 + 历史趋势图 |
| 历史数据趋势 | `DataMonitor.vue` | ECharts 7 天数据折线图 |
| 灌溉开关控制 | `DeviceControl.vue` | 远程开启/关闭灌溉，带计时器 |
| 阈值告警 | `AlertManage.vue` | 告警列表 + 处理功能 |
| 设备状态监控 | `DataMonitor.vue` | 设备在线/离线状态 + 电量 |
| 智能体灌溉问答 | `AIChat.vue` | 聊天界面，获取灌溉建议 |
| 多地块总览 | `Dashboard.vue` | 管理者查看所有地块数据 |
| 告警日志查看 | `AlertLog.vue` | 历史告警记录列表 + 筛选 |

## 前后端对接指南

### 1. Mock / 真实接口切换

打开 `src/api/index.js`，修改 `USE_MOCK` 变量：

```javascript
// 当前使用 Mock 数据（前端独立运行）
const USE_MOCK = true

// 后端开发完成后，改为 false 即可切换到真实接口
const USE_MOCK = false
```

### 2. API 代理配置

`vite.config.js` 中已配置开发环境代理：

```javascript
server: {
  proxy: {
    '/api': {
      target: 'http://localhost:8080',  // ← 改为你的后端地址
      changeOrigin: true,
      rewrite: (path) => path.replace(/^\/api/, ''),
    },
  },
}
```

前端所有请求以 `/api` 开头，Vite 会自动代理到 `http://localhost:8080`（Spring Boot 默认端口）。

### 3. 后端接口规范

前端期望的后端响应格式（统一返回体）：

```json
{
  "code": 200,
  "message": "success",
  "data": {}
}
```

需要实现的 API 接口清单：

| 接口 | 方法 | 路径 | 请求参数 | 返回数据 |
|------|------|------|----------|----------|
| 登录 | POST | `/auth/login` | `{ username, password, role }` | `{ token, role, username, userId, farmName }` |
| 地块列表 | GET | `/fields` | - | `[{ id, name, crop, area, status, soilMoisture, temperature, humidity, deviceId }]` |
| 地块详情 | GET | `/fields/{id}` | - | 同上单个对象 |
| 设备列表 | GET | `/devices` | - | `[{ id, name, type, fieldId, fieldName, status, battery, lastReport }]` |
| 绑定设备 | POST | `/devices/bind` | `{ deviceId, fieldId }` | - |
| 解绑设备 | POST | `/devices/unbind` | `{ deviceId }` | - |
| 添加设备 | POST | `/devices` | `{ name, type }` | 新设备对象 |
| 告警列表 | GET | `/alerts` | `?status=active` | `[{ id, fieldId, fieldName, type, level, message, time, status }]` |
| 处理告警 | PUT | `/alerts/{id}/resolve` | - | - |
| 阈值配置 | GET | `/thresholds/{fieldId}` | - | `{ soilMoistureMin, soilMoistureMax, tempMin, tempMax }` |
| 更新阈值 | PUT | `/thresholds/{fieldId}` | 阈值对象 | - |
| 灌溉状态 | GET | `/irrigation/{fieldId}/state` | - | `{ active: boolean }` |
| 控制灌溉 | POST | `/irrigation/{fieldId}/control` | `{ action: "on"/"off" }` | - |
| 历史数据 | GET | `/data/history/{fieldId}` | `?days=7` | `[{ date, soilMoisture, temperature, humidity }]` |
| 智能问答 | POST | `/ai/chat` | `{ message }` | `{ reply: string }` |
| 统计数据 | GET | `/stats` | - | `{ totalFields, totalDevices, onlineDevices, activeAlerts, ... }` |
| 农户绑定管理者 | POST | `/bind/farmer-manager` | `{ farmerCode, managerCode }` | - |

### 4. Spring Boot 后端对接要点

#### 4.1 跨域配置

在后端添加 CORS 配置（如果不用 Vite 代理）：

```java
@Configuration
public class CorsConfig implements WebMvcConfigurer {
    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/**")
                .allowedOrigins("http://localhost:5173")
                .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                .allowedHeaders("*")
                .allowCredentials(true);
    }
}
```

#### 4.2 统一返回体

```java
@Data
public class Result<T> {
    private int code;
    private String message;
    private T data;

    public static <T> Result<T> success(T data) {
        Result<T> r = new Result<>();
        r.setCode(200);
        r.setMessage("success");
        r.setData(data);
        return r;
    }
}
```

#### 4.3 JWT 认证

前端登录后会在请求头携带 Token：
```
Authorization: Bearer <token>
```

后端需要实现 JWT 拦截器验证 Token。

#### 4.4 MySQL 数据库表设计建议

```sql
-- 用户表
CREATE TABLE sys_user (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role ENUM('farmer', 'manager') NOT NULL,
    farm_name VARCHAR(100),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 地块表
CREATE TABLE field (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    crop VARCHAR(50),
    area DECIMAL(10, 2),
    manager_id BIGINT,
    status ENUM('normal', 'warning', 'danger', 'offline') DEFAULT 'normal',
    soil_moisture DECIMAL(5, 2),
    temperature DECIMAL(5, 2),
    humidity DECIMAL(5, 2),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 设备表
CREATE TABLE device (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    type ENUM('soil_sensor', 'temp_sensor', 'irrigation_valve') NOT NULL,
    field_id BIGINT,
    status ENUM('online', 'offline') DEFAULT 'online',
    battery INT DEFAULT 100,
    last_report DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 告警表
CREATE TABLE alert (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    field_id BIGINT NOT NULL,
    type VARCHAR(50) NOT NULL,
    level ENUM('info', 'warning', 'danger') NOT NULL,
    message TEXT,
    status ENUM('active', 'resolved') DEFAULT 'active',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    resolved_at DATETIME
);

-- 阈值配置表
CREATE TABLE threshold (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    field_id BIGINT NOT NULL,
    soil_moisture_min DECIMAL(5, 2),
    soil_moisture_max DECIMAL(5, 2),
    temp_min DECIMAL(5, 2),
    temp_max DECIMAL(5, 2)
);

-- 灌溉状态表
CREATE TABLE irrigation_state (
    field_id BIGINT PRIMARY KEY,
    active BOOLEAN DEFAULT FALSE,
    started_at DATETIME
);

-- 农户-管理者绑定关系表
CREATE TABLE farmer_manager_bind (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    farmer_id BIGINT NOT NULL,
    manager_id BIGINT NOT NULL,
    bind_code VARCHAR(20),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

## 演示说明

当前项目使用 Mock 数据，可直接运行无需后端：

1. **登录**：任意账号 + 密码（≥3位）即可登录
2. **农户角色**：可访问数据总览、实时监测、3D农场、设备控制、告警管理、智能问答
3. **管理者角色**：可访问数据总览、实时监测、3D农场、告警管理、农田管理、设备绑定、告警日志
4. **绑定功能**：管理者登录页生成绑定码，农户登录页输入绑定码完成关联
