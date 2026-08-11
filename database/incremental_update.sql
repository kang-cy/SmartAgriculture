-- ============================================================
-- 智慧农业管理平台 - 增量更新脚本
-- 适用于已有数据库的增量升级（不会删除已有数据）
-- 执行前请先备份数据库！
-- ============================================================

USE smart_agriculture;

-- ============================================================
-- 1. users 表新增 parent_manager_id 列
-- ============================================================
ALTER TABLE `users` ADD COLUMN `parent_manager_id` BIGINT DEFAULT NULL COMMENT '上级农场主ID（NULL=农场主，非NULL=子管理者）' AFTER `role`;
ALTER TABLE `users` ADD KEY `idx_parent_manager_id` (`parent_manager_id`);
ALTER TABLE `users` ADD CONSTRAINT `fk_user_parent` FOREIGN KEY (`parent_manager_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

-- ============================================================
-- 2. 创建 manager_applications 表
-- ============================================================
CREATE TABLE IF NOT EXISTS `manager_applications` (
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
-- 3. 修复种子用户数据（用户名改为英文格式 + 更新BCrypt密码哈希）
--    仅更新原始种子账号（ID 1-5），不影响后续注册的账号
-- ============================================================
UPDATE `users` SET `username` = 'admin',    `password` = '$2b$10$jjR5TOz.XFI2ftgMf7whrONUx5PNT8pDEkdLSfBRNlXVC8zr5xz/S', `parent_manager_id` = NULL WHERE `id` = 1;
UPDATE `users` SET `username` = 'farmer01', `password` = '$2b$10$jjR5TOz.XFI2ftgMf7whrONUx5PNT8pDEkdLSfBRNlXVC8zr5xz/S', `farm_name` = 'farmer01农场' WHERE `id` = 2;
UPDATE `users` SET `username` = 'farmer02', `password` = '$2b$10$jjR5TOz.XFI2ftgMf7whrONUx5PNT8pDEkdLSfBRNlXVC8zr5xz/S', `farm_name` = 'farmer02农场' WHERE `id` = 3;
UPDATE `users` SET `username` = 'farmer03', `password` = '$2b$10$jjR5TOz.XFI2ftgMf7whrONUx5PNT8pDEkdLSfBRNlXVC8zr5xz/S', `farm_name` = 'farmer03农场' WHERE `id` = 4;
UPDATE `users` SET `username` = 'farmer04', `password` = '$2b$10$jjR5TOz.XFI2ftgMf7whrONUx5PNT8pDEkdLSfBRNlXVC8zr5xz/S', `farm_name` = 'farmer04农场' WHERE `id` = 5;

-- ============================================================
-- 4. 更新绑定申请记录中的农户名称
-- ============================================================
UPDATE `bind_requests` SET `farmer_name` = 'farmer02' WHERE `farmer_id` = 3;
UPDATE `bind_requests` SET `farmer_name` = 'farmer03' WHERE `farmer_id` = 4;
UPDATE `bind_requests` SET `farmer_name` = 'farmer04' WHERE `farmer_id` = 5;

-- ============================================================
-- 5. 插入管理者申请种子数据（如果不存在）
-- ============================================================
INSERT IGNORE INTO `manager_applications` (`farmer_id`, `farmer_name`, `farm_owner_id`, `reason`, `status`, `request_time`, `resolve_time`, `remark`) VALUES
(3, 'farmer02', 1, '拥有3年农田管理经验，希望协助管理更多农田', 'pending',  '2026-08-04 10:00:00', NULL,                   ''),
(4, 'farmer03', 1, '自家农田规模扩大，需要管理者权限来管理设备', 'approved', '2026-08-03 15:00:00', '2026-08-03 17:00:00', '');

-- ============================================================
-- 6. 验证更新结果
-- ============================================================
SELECT id, username, role, parent_manager_id, farm_name FROM users ORDER BY id;
SELECT COUNT(*) AS manager_app_count FROM manager_applications;

-- ============================================================
-- 更新完成！
-- 账号密码对照表：
--   admin    / 123456  (管理者)
--   farmer01 / 123456  (农户，未绑定)
--   farmer02 / 123456  (农户，待审批)
--   farmer03 / 123456  (农户，已绑定admin)
--   farmer04 / 123456  (农户，已被拒绝)
-- ============================================================
