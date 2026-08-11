-- ============================================================
-- 智慧农业管理平台 - MySQL 数据库建表脚本
-- 数据库：smart_agriculture
-- 字符集：utf8mb4
-- ============================================================

-- 创建数据库
CREATE DATABASE IF NOT EXISTS smart_agriculture
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_general_ci;

USE smart_agriculture;

-- ============================================================
-- 1. 用户表（农户 + 管理者）
-- ============================================================
DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
  `id`                BIGINT       NOT NULL AUTO_INCREMENT COMMENT '用户ID',
  `username`          VARCHAR(50)  NOT NULL COMMENT '用户名',
  `password`          VARCHAR(255) NOT NULL COMMENT '密码（BCrypt加密存储）',
  `role`              VARCHAR(20)  NOT NULL DEFAULT 'farmer' COMMENT '角色：farmer-农户 / manager-管理者',
  `parent_manager_id` BIGINT       DEFAULT NULL COMMENT '上级农场主ID（NULL=农场主，非NULL=子管理者）',
  `farm_name`         VARCHAR(100) DEFAULT NULL COMMENT '农场名称',
  `phone`             VARCHAR(20)  DEFAULT NULL COMMENT '联系电话',
  `avatar`            VARCHAR(255) DEFAULT NULL COMMENT '头像URL',
  `status`            TINYINT      NOT NULL DEFAULT 1 COMMENT '状态：1-正常 0-禁用',
  `created_at`        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '注册时间',
  `updated_at`        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_username` (`username`),
  KEY `idx_role` (`role`),
  KEY `idx_parent_manager_id` (`parent_manager_id`),
  CONSTRAINT `fk_user_parent` FOREIGN KEY (`parent_manager_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';

-- ============================================================
-- 2. 农户-管理者绑定关系表
--    农户通过绑定码申请，管理者审批通过后建立绑定关系
-- ============================================================
DROP TABLE IF EXISTS `farmer_manager_relations`;
CREATE TABLE `farmer_manager_relations` (
  `id`          BIGINT      NOT NULL AUTO_INCREMENT COMMENT '关系ID',
  `farmer_id`   BIGINT      NOT NULL COMMENT '农户用户ID',
  `manager_id`  BIGINT      NOT NULL COMMENT '管理者用户ID',
  `status`      VARCHAR(20) NOT NULL DEFAULT 'active' COMMENT '状态：active-有效 inactive-已解除',
  `bound_at`    DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '绑定时间',
  `unbound_at`  DATETIME    DEFAULT NULL COMMENT '解除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_farmer_manager` (`farmer_id`, `manager_id`),
  KEY `idx_farmer_id` (`farmer_id`),
  KEY `idx_manager_id` (`manager_id`),
  CONSTRAINT `fk_fmr_farmer` FOREIGN KEY (`farmer_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_fmr_manager` FOREIGN KEY (`manager_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='农户-管理者绑定关系表';

-- ============================================================
-- 3. 绑定申请表（申请-审批流程）
--    农户输入绑定码提交申请，管理者审批
-- ============================================================
DROP TABLE IF EXISTS `bind_requests`;
CREATE TABLE `bind_requests` (
  `id`            BIGINT       NOT NULL AUTO_INCREMENT COMMENT '申请ID',
  `bind_code`     VARCHAR(20)  NOT NULL COMMENT '绑定码（管理者生成）',
  `farmer_id`     BIGINT       DEFAULT NULL COMMENT '农户用户ID',
  `farmer_name`   VARCHAR(50)  DEFAULT NULL COMMENT '农户名称（冗余字段）',
  `manager_id`    BIGINT       DEFAULT NULL COMMENT '管理者用户ID',
  `manager_name`  VARCHAR(50)  DEFAULT NULL COMMENT '管理者名称（冗余字段）',
  `status`        VARCHAR(20)  NOT NULL DEFAULT 'pending' COMMENT '状态：pending-待审批 approved-已通过 rejected-已驳回',
  `request_time`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '申请时间',
  `resolve_time`  DATETIME     DEFAULT NULL COMMENT '审批时间',
  `remark`        VARCHAR(500) DEFAULT NULL COMMENT '备注/驳回原因',
  `created_at`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_bind_code` (`bind_code`),
  KEY `idx_farmer_id` (`farmer_id`),
  KEY `idx_manager_id` (`manager_id`),
  KEY `idx_status` (`status`),
  CONSTRAINT `fk_br_farmer` FOREIGN KEY (`farmer_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_br_manager` FOREIGN KEY (`manager_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='绑定申请表';

-- ============================================================
-- 4. 农田/地块表
-- ============================================================
DROP TABLE IF EXISTS `fields`;
CREATE TABLE `fields` (
  `id`             BIGINT       NOT NULL AUTO_INCREMENT COMMENT '地块ID',
  `name`           VARCHAR(100) NOT NULL COMMENT '地块名称',
  `crop`           VARCHAR(50)  DEFAULT NULL COMMENT '种植作物',
  `area`           INT          NOT NULL DEFAULT 1000 COMMENT '面积（平方米）',
  `manager_id`     BIGINT       DEFAULT NULL COMMENT '管理者用户ID',
  `status`         VARCHAR(20)  NOT NULL DEFAULT 'normal' COMMENT '状态：normal-正常 warning-预警 danger-告警 offline-离线',
  `soil_moisture`  DECIMAL(5,1) NOT NULL DEFAULT 0 COMMENT '土壤湿度（%）',
  `temperature`    DECIMAL(5,1) NOT NULL DEFAULT 0 COMMENT '环境温度（°C）',
  `humidity`       DECIMAL(5,1) NOT NULL DEFAULT 0 COMMENT '空气湿度（%）',
  `created_at`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_manager_id` (`manager_id`),
  KEY `idx_status` (`status`),
  CONSTRAINT `fk_field_manager` FOREIGN KEY (`manager_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='农田地块表';

-- ============================================================
-- 5. 设备类型表（支持自定义扩展）
-- ============================================================
DROP TABLE IF EXISTS `device_types`;
CREATE TABLE `device_types` (
  `id`          BIGINT       NOT NULL AUTO_INCREMENT COMMENT '类型ID',
  `type_value`  VARCHAR(50)  NOT NULL COMMENT '类型标识（如 soil_sensor）',
  `type_label`  VARCHAR(50)  NOT NULL COMMENT '类型显示名称（如 土壤传感器）',
  `is_preset`   TINYINT      NOT NULL DEFAULT 0 COMMENT '是否预设类型：1-是 0-自定义',
  `created_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_type_value` (`type_value`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='设备类型表';

-- ============================================================
-- 6. 设备表
-- ============================================================
DROP TABLE IF EXISTS `devices`;
CREATE TABLE `devices` (
  `id`           VARCHAR(30)  NOT NULL COMMENT '设备编号（如 DEV-A001）',
  `name`         VARCHAR(100) NOT NULL COMMENT '设备名称',
  `type`         VARCHAR(50)  NOT NULL COMMENT '设备类型（对应 device_types.type_value）',
  `field_id`     BIGINT       DEFAULT NULL COMMENT '绑定的地块ID（NULL表示未绑定）',
  `status`       VARCHAR(20)  NOT NULL DEFAULT 'online' COMMENT '状态：online-在线 offline-离线',
  `battery`      INT          NOT NULL DEFAULT 100 COMMENT '电量（%）',
  `last_report`  DATETIME     DEFAULT NULL COMMENT '最近上报时间',
  `created_at`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_field_id` (`field_id`),
  KEY `idx_type` (`type`),
  KEY `idx_status` (`status`),
  CONSTRAINT `fk_dev_field` FOREIGN KEY (`field_id`) REFERENCES `fields` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='设备表';

-- ============================================================
-- 7. 告警表
-- ============================================================
DROP TABLE IF EXISTS `alerts`;
CREATE TABLE `alerts` (
  `id`           BIGINT       NOT NULL AUTO_INCREMENT COMMENT '告警ID',
  `field_id`     BIGINT       DEFAULT NULL COMMENT '关联地块ID',
  `field_name`   VARCHAR(100) DEFAULT NULL COMMENT '地块名称（冗余）',
  `type`         VARCHAR(30)  NOT NULL COMMENT '告警类型：low_moisture-湿度不足 high_temp-温度过高 device_offline-设备离线 low_battery-电量低',
  `level`        VARCHAR(20)  NOT NULL DEFAULT 'warning' COMMENT '告警级别：warning-警告 danger-严重 info-信息',
  `message`      VARCHAR(500) NOT NULL COMMENT '告警详情',
  `status`       VARCHAR(20)  NOT NULL DEFAULT 'active' COMMENT '状态：active-活跃 resolved-已处理',
  `created_at`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '告警时间',
  `resolved_at`  DATETIME     DEFAULT NULL COMMENT '处理时间',
  PRIMARY KEY (`id`),
  KEY `idx_field_id` (`field_id`),
  KEY `idx_status` (`status`),
  KEY `idx_level` (`level`),
  KEY `idx_created_at` (`created_at`),
  CONSTRAINT `fk_alert_field` FOREIGN KEY (`field_id`) REFERENCES `fields` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='告警表';

-- ============================================================
-- 8. 阈值配置表（每个地块独立配置）
-- ============================================================
DROP TABLE IF EXISTS `thresholds`;
CREATE TABLE `thresholds` (
  `id`                  BIGINT      NOT NULL AUTO_INCREMENT COMMENT '阈值ID',
  `field_id`            BIGINT      NOT NULL COMMENT '地块ID',
  `soil_moisture_min`   DECIMAL(5,1) NOT NULL DEFAULT 30.0 COMMENT '土壤湿度下限（%）',
  `soil_moisture_max`   DECIMAL(5,1) NOT NULL DEFAULT 80.0 COMMENT '土壤湿度上限（%）',
  `temp_min`            DECIMAL(5,1) NOT NULL DEFAULT 5.0 COMMENT '温度下限（°C）',
  `temp_max`            DECIMAL(5,1) NOT NULL DEFAULT 35.0 COMMENT '温度上限（°C）',
  `updated_at`          DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_field_id` (`field_id`),
  CONSTRAINT `fk_thresh_field` FOREIGN KEY (`field_id`) REFERENCES `fields` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='阈值配置表';

-- ============================================================
-- 9. 灌溉状态表
-- ============================================================
DROP TABLE IF EXISTS `irrigation_states`;
CREATE TABLE `irrigation_states` (
  `id`               BIGINT      NOT NULL AUTO_INCREMENT COMMENT '状态ID',
  `field_id`         BIGINT      NOT NULL COMMENT '地块ID',
  `is_active`        TINYINT     NOT NULL DEFAULT 0 COMMENT '灌溉是否开启：1-开启 0-关闭',
  `duration_minutes` INT         DEFAULT NULL COMMENT '灌溉时长（分钟），NULL表示手动模式无倒计时',
  `started_at`       DATETIME    DEFAULT NULL COMMENT '灌溉开始时间',
  `updated_at`       DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_field_id` (`field_id`),
  CONSTRAINT `fk_irrig_field` FOREIGN KEY (`field_id`) REFERENCES `fields` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='灌溉状态表';

-- ============================================================
-- 10. 传感器历史数据表（用于趋势图表）
-- ============================================================
DROP TABLE IF EXISTS `sensor_data`;
CREATE TABLE `sensor_data` (
  `id`             BIGINT       NOT NULL AUTO_INCREMENT COMMENT '数据ID',
  `field_id`       BIGINT       NOT NULL COMMENT '地块ID',
  `soil_moisture`  DECIMAL(5,1) NOT NULL COMMENT '土壤湿度（%）',
  `temperature`    DECIMAL(5,1) NOT NULL COMMENT '环境温度（°C）',
  `humidity`       DECIMAL(5,1) NOT NULL COMMENT '空气湿度（%）',
  `recorded_at`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录时间',
  PRIMARY KEY (`id`),
  KEY `idx_field_id` (`field_id`),
  KEY `idx_recorded_at` (`recorded_at`),
  CONSTRAINT `fk_sd_field` FOREIGN KEY (`field_id`) REFERENCES `fields` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='传感器历史数据表';

-- ============================================================
-- 11. AI对话记录表（可选）
-- ============================================================
DROP TABLE IF EXISTS `ai_chat_logs`;
CREATE TABLE `ai_chat_logs` (
  `id`          BIGINT         NOT NULL AUTO_INCREMENT COMMENT '记录ID',
  `user_id`     BIGINT         NOT NULL COMMENT '用户ID',
  `message`     VARCHAR(1000)  NOT NULL COMMENT '用户提问',
  `reply`       TEXT           NOT NULL COMMENT 'AI回复',
  `created_at`  DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '对话时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  CONSTRAINT `fk_ai_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI对话记录表';

-- ============================================================
-- 12. 管理者申请表（农户申请成为管理者，由农场主审批）
-- ============================================================
DROP TABLE IF EXISTS `manager_applications`;
CREATE TABLE `manager_applications` (
  `id`              BIGINT       NOT NULL AUTO_INCREMENT COMMENT '申请ID',
  `farmer_id`       BIGINT       NOT NULL COMMENT '申请农户的用户ID',
  `farmer_name`     VARCHAR(50)  DEFAULT NULL COMMENT '农户名称（冗余）',
  `farm_owner_id`   BIGINT       DEFAULT NULL COMMENT '审批农场主的用户ID',
  `reason`          VARCHAR(500) DEFAULT NULL COMMENT '申请理由',
  `status`          VARCHAR(20)  NOT NULL DEFAULT 'pending' COMMENT '状态：pending-待审批 approved-已通过 rejected-已驳回',
  `request_time`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '申请时间',
  `resolve_time`    DATETIME     DEFAULT NULL COMMENT '审批时间',
  `remark`          VARCHAR(500) DEFAULT NULL COMMENT '备注/驳回原因',
  PRIMARY KEY (`id`),
  KEY `idx_farmer_id` (`farmer_id`),
  KEY `idx_farm_owner_id` (`farm_owner_id`),
  KEY `idx_status` (`status`),
  CONSTRAINT `fk_ma_farmer` FOREIGN KEY (`farmer_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ma_owner` FOREIGN KEY (`farm_owner_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='管理者申请表';


-- ============================================================
-- ==================== 初始化种子数据 ==========================
-- ============================================================

-- ----- 用户数据 -----
-- 说明：密码均为 123456 的 BCrypt 加密结果；用户名仅含字母/数字/下划线
INSERT INTO `users` (`id`, `username`, `password`, `role`, `parent_manager_id`, `farm_name`, `status`) VALUES
(1, 'admin',     '$2b$10$jjR5TOz.XFI2ftgMf7whrONUx5PNT8pDEkdLSfBRNlXVC8zr5xz/S', 'manager', NULL, '绿源生态农场',  1),
(2, 'farmer01',  '$2b$10$jjR5TOz.XFI2ftgMf7whrONUx5PNT8pDEkdLSfBRNlXVC8zr5xz/S', 'farmer',  NULL, 'farmer01农场', 1),
(3, 'farmer02',  '$2b$10$jjR5TOz.XFI2ftgMf7whrONUx5PNT8pDEkdLSfBRNlXVC8zr5xz/S', 'farmer',  NULL, 'farmer02农场', 1),
(4, 'farmer03',  '$2b$10$jjR5TOz.XFI2ftgMf7whrONUx5PNT8pDEkdLSfBRNlXVC8zr5xz/S', 'farmer',  NULL, 'farmer03农场', 1),
(5, 'farmer04',  '$2b$10$jjR5TOz.XFI2ftgMf7whrONUx5PNT8pDEkdLSfBRNlXVC8zr5xz/S', 'farmer',  NULL, 'farmer04农场', 1);

-- ----- 农户-管理者绑定关系 -----
INSERT INTO `farmer_manager_relations` (`farmer_id`, `manager_id`, `status`) VALUES
(4, 1, 'active');

-- ----- 绑定申请记录 -----
INSERT INTO `bind_requests` (`bind_code`, `farmer_id`, `farmer_name`, `manager_id`, `manager_name`, `status`, `request_time`, `resolve_time`, `remark`) VALUES
('AGX8K2M', 3, 'farmer02',   1, 'admin', 'pending',  '2026-08-04 09:30:00', NULL,                    '申请绑定A区温室大棚'),
('AGP3N7Q', 4, 'farmer03',   1, 'admin', 'approved', '2026-08-03 14:20:00', '2026-08-03 16:10:00',  '申请绑定B区露天菜地'),
('AGL9R4T', 5, 'farmer04',   1, 'admin', 'rejected', '2026-08-02 10:15:00', '2026-08-02 11:30:00',  '绑定码已过期，请重新生成');

-- ----- 农田地块数据 -----
INSERT INTO `fields` (`id`, `name`, `crop`, `area`, `manager_id`, `status`, `soil_moisture`, `temperature`, `humidity`) VALUES
(1, 'A区-温室大棚1号', '番茄', 1200, 1, 'normal',  45.0, 26.5, 68.0),
(2, 'A区-温室大棚2号', '黄瓜',  980, 1, 'warning', 22.0, 31.2, 55.0),
(3, 'B区-露天菜地1号', '白菜', 2400, 1, 'normal',  52.0, 24.8, 72.0),
(4, 'B区-露天菜地2号', '辣椒', 1800, 1, 'danger',  15.0, 35.6, 40.0),
(5, 'C区-果园1号',     '草莓', 1500, 1, 'normal',  48.0, 25.3, 65.0),
(6, 'C区-果园2号',     '蓝莓', 1100, 1, 'offline',  0.0,  0.0,  0.0);

-- ----- 设备类型 -----
INSERT INTO `device_types` (`type_value`, `type_label`, `is_preset`) VALUES
('soil_sensor',       '土壤传感器', 1),
('temp_sensor',       '温度传感器', 1),
('humidity_sensor',   '湿度传感器', 1),
('irrigation_valve',  '灌溉阀门',   1),
('camera',            '摄像头',     1);

-- ----- 设备数据 -----
INSERT INTO `devices` (`id`, `name`, `type`, `field_id`, `status`, `battery`, `last_report`) VALUES
('DEV-A001', '土壤传感器-A001', 'soil_sensor',      1,    'online',  85, '2026-08-04 10:30:00'),
('DEV-A002', '土壤传感器-A002', 'soil_sensor',      2,    'online',  62, '2026-08-04 10:29:55'),
('DEV-A003', '温度传感器-A003', 'temp_sensor',      1,    'online',  90, '2026-08-04 10:30:02'),
('DEV-B001', '土壤传感器-B001', 'soil_sensor',      3,    'online',  78, '2026-08-04 10:30:01'),
('DEV-B002', '土壤传感器-B002', 'soil_sensor',      4,    'online',  35, '2026-08-04 10:29:58'),
('DEV-B003', '灌溉阀门-B003',   'irrigation_valve', 3,    'online',  95, '2026-08-04 10:30:00'),
('DEV-C001', '土壤传感器-C001', 'soil_sensor',      5,    'online',  88, '2026-08-04 10:30:03'),
('DEV-C002', '土壤传感器-C002', 'soil_sensor',      6,    'offline',  0, '2026-08-03 18:22:14'),
('DEV-UNBIND-001', '未绑定传感器-001', 'soil_sensor',      NULL, 'online', 100, '2026-08-04 10:28:00'),
('DEV-UNBIND-002', '未绑定灌溉阀-002', 'irrigation_valve', NULL, 'online', 100, '2026-08-04 10:27:00'),
('DEV-CAM-001',     '监控摄像头-A区1号',   'camera',           1,    'online',  92, '2026-08-04 10:30:00'),
('DEV-CAM-002',     '监控摄像头-B区1号',   'camera',           3,    'online',  80, '2026-08-04 10:29:50'),
('DEV-UNBIND-CAM-001', '未绑定摄像头-001',  'camera',          NULL, 'online', 100, '2026-08-04 10:25:00');

-- ----- 告警数据 -----
INSERT INTO `alerts` (`field_id`, `field_name`, `type`, `level`, `message`, `status`, `created_at`, `resolved_at`) VALUES
(2, 'A区-温室大棚2号', 'low_moisture',  'warning', '土壤湿度低于阈值 (当前: 22%, 阈值: 30%)',      'active',   '2026-08-04 09:15:22', NULL),
(4, 'B区-露天菜地2号', 'low_moisture',  'danger',  '土壤湿度严重偏低 (当前: 15%, 阈值: 30%)',      'active',   '2026-08-04 08:42:10', NULL),
(4, 'B区-露天菜地2号', 'high_temp',     'danger',  '温度超过警戒值 (当前: 35.6°C, 阈值: 35°C)',    'active',   '2026-08-04 08:42:12', NULL),
(6, 'C区-果园2号',     'device_offline','warning', '设备 DEV-C002 已离线超过12小时',                'active',   '2026-08-04 06:30:00', NULL),
(2, 'A区-温室大棚2号', 'low_moisture',  'warning', '土壤湿度低于阈值 (当前: 28%, 阈值: 30%)',      'resolved', '2026-08-03 16:20:00', '2026-08-04 08:00:00'),
(1, 'A区-温室大棚1号', 'low_battery',   'info',    '设备 DEV-A002 电量低于70%',                     'resolved', '2026-08-03 14:10:00', '2026-08-03 15:00:00');

-- ----- 阈值配置 -----
INSERT INTO `thresholds` (`field_id`, `soil_moisture_min`, `soil_moisture_max`, `temp_min`, `temp_max`) VALUES
(1, 30.0, 80.0, 5.0, 35.0),
(2, 30.0, 80.0, 5.0, 35.0),
(3, 25.0, 75.0, 5.0, 38.0),
(4, 30.0, 80.0, 5.0, 35.0),
(5, 35.0, 85.0, 5.0, 32.0),
(6, 35.0, 85.0, 5.0, 32.0);

-- ----- 灌溉状态 -----
INSERT INTO `irrigation_states` (`field_id`, `is_active`) VALUES
(1, 0),
(2, 0),
(3, 0),
(4, 1),
(5, 0),
(6, 0);

-- ----- 传感器历史数据（近7天示例） -----
INSERT INTO `sensor_data` (`field_id`, `soil_moisture`, `temperature`, `humidity`, `recorded_at`) VALUES
(1, 42.0, 25.8, 66.0, '2026-07-29 10:00:00'),
(1, 48.0, 26.2, 70.0, '2026-07-30 10:00:00'),
(1, 45.0, 26.5, 68.0, '2026-07-31 10:00:00'),
(1, 50.0, 27.1, 72.0, '2026-08-01 10:00:00'),
(1, 43.0, 26.0, 65.0, '2026-08-02 10:00:00'),
(1, 47.0, 26.3, 69.0, '2026-08-03 10:00:00'),
(1, 45.0, 26.5, 68.0, '2026-08-04 10:00:00'),
(2, 30.0, 29.5, 60.0, '2026-07-29 10:00:00'),
(2, 28.0, 30.1, 58.0, '2026-07-30 10:00:00'),
(2, 25.0, 30.8, 56.0, '2026-07-31 10:00:00'),
(2, 22.0, 31.2, 55.0, '2026-08-01 10:00:00'),
(2, 26.0, 30.5, 57.0, '2026-08-02 10:00:00'),
(2, 24.0, 30.9, 56.0, '2026-08-03 10:00:00'),
(2, 22.0, 31.2, 55.0, '2026-08-04 10:00:00');

-- ----- 管理者申请记录 -----
INSERT INTO `manager_applications` (`farmer_id`, `farmer_name`, `farm_owner_id`, `reason`, `status`, `request_time`, `resolve_time`, `remark`) VALUES
(3, 'farmer02', 1, '拥有3年农田管理经验，希望协助管理更多农田', 'pending',  '2026-08-04 10:00:00', NULL,                   ''),
(4, 'farmer03', 1, '自家农田规模扩大，需要管理者权限来管理设备', 'approved', '2026-08-03 15:00:00', '2026-08-03 17:00:00', '');
