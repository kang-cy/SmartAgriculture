-- ============================================================
-- 智慧农业管理平台 - 补充测试数据脚本
-- 说明：在已有种子数据（smart_agriculture.sql）基础上追加执行
--       新增 2 个管理者 + 3 个农户，以及关联的田地/设备/告警等
-- 密码均为 123456 的 BCrypt 加密结果
-- 使用方法：mysql -u root -p smart_agriculture < insert_test_data.sql
-- ============================================================

USE smart_agriculture;

-- ============================================================
-- 0. 清理旧测试数据（如需重复执行，取消下方注释即可）
-- ============================================================
-- DELETE FROM `sensor_data`       WHERE `field_id` >= 7;
-- DELETE FROM `irrigation_states`  WHERE `field_id` >= 7;
-- DELETE FROM `thresholds`         WHERE `field_id` >= 7;
-- DELETE FROM `alerts`             WHERE `field_id` >= 7;
-- DELETE FROM `devices`            WHERE `id` LIKE 'DEV-D%' OR `id` LIKE 'DEV-E%' OR `id` LIKE 'DEV-F%' OR `id` LIKE 'DEV-UNBIND-00%' OR `id` LIKE 'DEV-CAM-00%';
-- DELETE FROM `fields`             WHERE `id` >= 7;
-- DELETE FROM `bind_requests`      WHERE `farmer_id` >= 6;
-- DELETE FROM `manager_applications` WHERE `farmer_id` >= 6;
-- DELETE FROM `farmer_manager_relations` WHERE `farmer_id` >= 6 OR `manager_id` >= 6;
-- DELETE FROM `users`              WHERE `id` >= 6;

-- ============================================================
-- 1. 新增用户（2 个管理者 + 3 个农户）
-- ============================================================
-- ID 6 : manager_zhao  — 独立农场主（金穗智慧农场），parent_manager_id = NULL
-- ID 7 : manager_sun   — admin(1) 的子管理者，parent_manager_id = 1
-- ID 8 : farmer_wang   — 已绑定 manager_zhao(6)
-- ID 9 : farmer_zhou   — 已绑定 admin(1)
-- ID 10: farmer_lin    — 未绑定任何管理者（有待审批申请）
INSERT INTO `users` (`id`, `username`, `password`, `role`, `parent_manager_id`, `farm_name`, `phone`, `status`) VALUES
(6,  'manager_zhao', '$2b$10$jjR5TOz.XFI2ftgMf7whrONUx5PNT8pDEkdLSfBRNlXVC8zr5xz/S', 'manager', NULL, '金穗智慧农场',   '13900001111', 1),
(7,  'manager_sun',  '$2b$10$jjR5TOz.XFI2ftgMf7whrONUx5PNT8pDEkdLSfBRNlXVC8zr5xz/S', 'manager', 1,    '协管-南区农田', '13900002222', 1),
(8,  'farmer_wang',  '$2b$10$jjR5TOz.XFI2ftgMf7whrONUx5PNT8pDEkdLSfBRNlXVC8zr5xz/S', 'farmer',  NULL, NULL,            '13900003333', 1),
(9,  'farmer_zhou',  '$2b$10$jjR5TOz.XFI2ftgMf7whrONUx5PNT8pDEkdLSfBRNlXVC8zr5xz/S', 'farmer',  NULL, NULL,            '13900004444', 1),
(10, 'farmer_lin',   '$2b$10$jjR5TOz.XFI2ftgMf7whrONUx5PNT8pDEkdLSfBRNlXVC8zr5xz/S', 'farmer',  NULL, NULL,            '13900005555', 1);

-- ============================================================
-- 2. 农户-管理者绑定关系
-- ============================================================
-- farmer_wang(8) → manager_zhao(6)  已生效
-- farmer_zhou(9) → admin(1)         已生效
-- farmer_lin(10) → 未绑定
INSERT INTO `farmer_manager_relations` (`farmer_id`, `manager_id`, `status`, `bound_at`) VALUES
(8, 6, 'active', '2026-08-03 09:00:00'),
(9, 1, 'active', '2026-08-02 14:30:00');

-- ============================================================
-- 3. 绑定申请记录
-- ============================================================
INSERT INTO `bind_requests` (`bind_code`, `farmer_id`, `farmer_name`, `manager_id`, `manager_name`, `status`, `request_time`, `resolve_time`, `remark`) VALUES
-- farmer_wang(8) 申请绑定 manager_zhao(6) — 已通过
('AGZ5K3M', 8,  'farmer_wang', 6, 'manager_zhao', 'approved', '2026-08-03 08:50:00', '2026-08-03 09:00:00', '申请绑定金穗智慧农场'),
-- farmer_zhou(9) 申请绑定 admin(1) — 已通过
('AGZ4N8P', 9,  'farmer_zhou', 1, 'admin',        'approved', '2026-08-02 14:20:00', '2026-08-02 14:30:00', '申请绑定A区温室'),
-- farmer_lin(10) 申请绑定 manager_zhao(6) — 待审批
('AGL2R6T', 10, 'farmer_lin',  6, 'manager_zhao', 'pending',  '2026-08-05 10:00:00', NULL,                   '新农户申请绑定，等待审批');

-- ============================================================
-- 4. 农田地块
-- ============================================================
-- ID 7-10 : manager_zhao(6) 的地块
-- ID 11-12: manager_sun(7) 的地块（子管理者，admin 也能看到）
INSERT INTO `fields` (`id`, `name`, `crop`, `area`, `manager_id`, `status`, `soil_moisture`, `temperature`, `humidity`) VALUES
(7,  'D区-智能温室1号', '西瓜',  1500, 6, 'normal',  55.0, 27.3, 70.0),
(8,  'D区-智能温室2号', '甜瓜',  1200, 6, 'warning', 28.0, 32.1, 58.0),
(9,  'E区-露天农田1号', '玉米',  3000, 6, 'normal',  50.0, 25.0, 65.0),
(10, 'E区-露天农田2号', '水稻',  2800, 6, 'danger',  18.0, 36.5, 42.0),
(11, 'F区-果园南区1号', '苹果',  2000, 7, 'normal',  46.0, 24.5, 63.0),
(12, 'F区-果园南区2号', '葡萄',  1600, 7, 'offline',  0.0,  0.0,  0.0);

-- ============================================================
-- 5. 设备数据（绑定到新地块 + 未绑定设备）
-- ============================================================
INSERT INTO `devices` (`id`, `name`, `type`, `field_id`, `status`, `battery`, `last_report`) VALUES
-- D区设备（manager_zhao 的地块）
('DEV-D001', '土壤传感器-D001', 'soil_sensor',      7,    'online',  82, '2026-08-05 10:30:00'),
('DEV-D002', '温度传感器-D002', 'temp_sensor',      7,    'online',  76, '2026-08-05 10:29:55'),
('DEV-D003', '土壤传感器-D003', 'soil_sensor',      8,    'online',  55, '2026-08-05 10:30:02'),
('DEV-D004', '灌溉阀门-D004',   'irrigation_valve', 8,    'online',  88, '2026-08-05 10:30:00'),
-- E区设备
('DEV-E001', '土壤传感器-E001', 'soil_sensor',      9,    'online',  91, '2026-08-05 10:30:01'),
('DEV-E002', '湿度传感器-E002', 'humidity_sensor',  9,    'online',  70, '2026-08-05 10:29:58'),
('DEV-E003', '土壤传感器-E003', 'soil_sensor',      10,   'online',  30, '2026-08-05 10:29:50'),
('DEV-E004', '灌溉阀门-E004',   'irrigation_valve', 10,   'online',  85, '2026-08-05 10:30:00'),
-- F区设备（manager_sun 的地块）
('DEV-F001', '土壤传感器-F001', 'soil_sensor',      11,   'online',  89, '2026-08-05 10:30:03'),
('DEV-F002', '土壤传感器-F002', 'soil_sensor',      12,   'offline',  0, '2026-08-04 20:15:00'),
-- 摄像头（实时监控模块）
('DEV-CAM-003', '监控摄像头-D区',  'camera',  7,    'online',  86, '2026-08-05 10:30:00'),
('DEV-CAM-004', '监控摄像头-E区',  'camera',  9,    'online',  78, '2026-08-05 10:29:55'),
-- 未绑定设备
('DEV-UNBIND-003', '未绑定温度传感器', 'temp_sensor', NULL, 'online', 100, '2026-08-05 10:28:00'),
('DEV-UNBIND-004', '未绑定摄像头-002', 'camera',      NULL, 'online', 100, '2026-08-05 10:27:00');

-- ============================================================
-- 6. 告警数据（新地块的告警）
-- ============================================================
INSERT INTO `alerts` (`field_id`, `field_name`, `type`, `level`, `message`, `status`, `created_at`, `resolved_at`) VALUES
(8,  'D区-智能温室2号', 'low_moisture',   'warning', '土壤湿度低于阈值 (当前: 28%, 阈值: 30%)',     'active',   '2026-08-05 08:30:00', NULL),
(10, 'E区-露天农田2号', 'low_moisture',   'danger',  '土壤湿度严重偏低 (当前: 18%, 阈值: 30%)',     'active',   '2026-08-05 07:45:00', NULL),
(10, 'E区-露天农田2号', 'high_temp',      'danger',  '温度超过警戒值 (当前: 36.5°C, 阈值: 35°C)',   'active',   '2026-08-05 07:45:02', NULL),
(12, 'F区-果园南区2号', 'device_offline', 'warning', '设备 DEV-F002 已离线超过14小时',               'active',   '2026-08-05 06:00:00', NULL),
(8,  'D区-智能温室2号', 'low_battery',    'info',    '设备 DEV-D003 电量低于60%',                    'active',   '2026-08-05 09:00:00', NULL),
(10, 'E区-露天农田2号', 'low_battery',    'warning', '设备 DEV-E003 电量低于35%',                    'active',   '2026-08-05 09:30:00', NULL),
(8,  'D区-智能温室2号', 'low_moisture',   'warning', '土壤湿度低于阈值 (当前: 25%, 阈值: 30%)',     'resolved', '2026-08-04 16:00:00', '2026-08-04 18:00:00');

-- ============================================================
-- 7. 阈值配置（新地块）
-- ============================================================
INSERT INTO `thresholds` (`field_id`, `soil_moisture_min`, `soil_moisture_max`, `temp_min`, `temp_max`) VALUES
(7,  35.0, 85.0, 5.0, 35.0),
(8,  30.0, 80.0, 5.0, 35.0),
(9,  25.0, 75.0, 5.0, 38.0),
(10, 30.0, 80.0, 5.0, 35.0),
(11, 35.0, 85.0, 5.0, 32.0),
(12, 35.0, 85.0, 5.0, 32.0);

-- ============================================================
-- 8. 灌溉状态（新地块，含自定义时长）
-- ============================================================
INSERT INTO `irrigation_states` (`field_id`, `is_active`, `duration_minutes`, `started_at`) VALUES
(7,  0, NULL, NULL),
(8,  1, 30,   '2026-08-05 10:00:00'),  -- 灌溉中，自定义30分钟
(9,  0, NULL, NULL),
(10, 1, 45,   '2026-08-05 09:30:00'),  -- 灌溉中，自定义45分钟
(11, 0, NULL, NULL),
(12, 0, NULL, NULL);

-- ============================================================
-- 9. 传感器历史数据（新地块近7天，用于趋势图表）
-- ============================================================
INSERT INTO `sensor_data` (`field_id`, `soil_moisture`, `temperature`, `humidity`, `recorded_at`) VALUES
-- D区-智能温室1号 (field_id=7) — 湿度稳定
(7, 52.0, 26.5, 68.0, '2026-07-30 10:00:00'),
(7, 54.0, 27.0, 70.0, '2026-07-31 10:00:00'),
(7, 56.0, 27.5, 72.0, '2026-08-01 10:00:00'),
(7, 53.0, 26.8, 69.0, '2026-08-02 10:00:00'),
(7, 55.0, 27.2, 71.0, '2026-08-03 10:00:00'),
(7, 57.0, 27.8, 73.0, '2026-08-04 10:00:00'),
(7, 55.0, 27.3, 70.0, '2026-08-05 10:00:00'),
-- D区-智能温室2号 (field_id=8) — 湿度持续下降（触发告警）
(8, 38.0, 30.0, 62.0, '2026-07-30 10:00:00'),
(8, 35.0, 30.5, 60.0, '2026-07-31 10:00:00'),
(8, 32.0, 31.0, 58.0, '2026-08-01 10:00:00'),
(8, 30.0, 31.5, 56.0, '2026-08-02 10:00:00'),
(8, 29.0, 31.8, 55.0, '2026-08-03 10:00:00'),
(8, 28.0, 32.0, 54.0, '2026-08-04 10:00:00'),
(8, 28.0, 32.1, 58.0, '2026-08-05 10:00:00'),
-- E区-露天农田1号 (field_id=9) — 正常波动
(9, 48.0, 24.0, 63.0, '2026-07-30 10:00:00'),
(9, 50.0, 24.5, 65.0, '2026-07-31 10:00:00'),
(9, 52.0, 25.0, 67.0, '2026-08-01 10:00:00'),
(9, 49.0, 24.8, 64.0, '2026-08-02 10:00:00'),
(9, 51.0, 25.2, 66.0, '2026-08-03 10:00:00'),
(9, 50.0, 24.5, 65.0, '2026-08-04 10:00:00'),
(9, 50.0, 25.0, 65.0, '2026-08-05 10:00:00');

-- ============================================================
-- 10. 管理者申请记录（农户申请成为管理者）
-- ============================================================
-- farmer_lin(10) 申请成为独立管理者，待 admin(1) 审批
INSERT INTO `manager_applications` (`farmer_id`, `farmer_name`, `farm_owner_id`, `reason`, `status`, `request_time`, `resolve_time`, `remark`) VALUES
(10, 'farmer_lin', 1, '拥有5亩农田，希望成为独立管理者自主管理农田数据和设备', 'pending', '2026-08-05 09:00:00', NULL, '');


-- ============================================================
-- ==================== 数据汇总 ================================
-- ============================================================
--
-- 【新增用户】
--   管理者：
--     manager_zhao (ID=6)  — 独立农场主，金穗智慧农场
--     manager_sun  (ID=7)  — admin的子管理者，协管-南区农田
--   农户：
--     farmer_wang  (ID=8)  — 已绑定 manager_zhao
--     farmer_zhou  (ID=9)  — 已绑定 admin
--     farmer_lin   (ID=10) — 未绑定（有待审批申请）
--
-- 【绑定关系】
--   farmer_wang(8)  → manager_zhao(6)  已绑定
--   farmer_zhou(9)  → admin(1)         已绑定
--   farmer_lin(10)  → 未绑定（申请待审批）
--
-- 【地块分布】
--   admin(1)        → 1~6 号地块（基础数据）
--   manager_zhao(6) → 7~10 号地块
--   manager_sun(7)  → 11~12 号地块（admin 作为农场主也能看到）
--
-- 【测试账号】（密码均为 123456）
--   ┌───────────────┬────────┬──────────────────────────────────────┐
--   │ 账号           │ 角色    │ 可见地块                              │
--   ├───────────────┼────────┼──────────────────────────────────────┤
--   │ admin         │ 管理者  │ 1~6 + 11~12（含子管理者地块）          │
--   │ manager_zhao  │ 管理者  │ 7~10                                  │
--   │ manager_sun   │ 子管理者 │ 11~12                                 │
--   │ farmer_wang   │ 农户    │ 7~10（绑定 manager_zhao）              │
--   │ farmer_zhou   │ 农户    │ 1~6 + 11~12（绑定 admin）              │
--   │ farmer_lin    │ 农户    │ 无（未绑定任何管理者）                  │
--   └───────────────┴────────┴──────────────────────────────────────┘
--
-- 【数据隔离验证要点】
--   1. manager_zhao 登录 → 只看到 7~10 号地块，看不到 admin 的 1~6 号
--   2. farmer_wang 登录  → 看到 manager_zhao 的 7~10 号地块
--   3. farmer_lin 登录   → 看不到任何地块数据（空白页面，无报错）
--   4. admin 登录        → 看到 1~6 + 11~12 号地块（子管理者 manager_sun 的）
-- ============================================================
