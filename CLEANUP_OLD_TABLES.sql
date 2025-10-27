-- ============================================================================
-- 清理旧表 - 删除与应用无关的数据库表
-- ============================================================================
-- 本脚本用于删除迁移后不再使用的旧表
-- ⚠️ 请务必先备份数据库！
-- ⚠️ 建议在执行删除前先运行新系统至少7天
-- ============================================================================

-- ============================================================================
-- 第一部分：查看所有表（先检查）
-- ============================================================================

-- 列出public schema中的所有表
SELECT 
    tablename,
    schemaname
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- ============================================================================
-- 第二部分：检查表的记录数和最后更新时间
-- ============================================================================

-- 检查旧表的数据情况
DO $$
DECLARE
    v_count INTEGER;
    v_latest TIMESTAMP WITH TIME ZONE;
BEGIN
    -- 检查 asset_checkins（旧表）
    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'asset_checkins') THEN
        SELECT COUNT(*), MAX(created_at) INTO v_count, v_latest
        FROM asset_checkins;
        RAISE NOTICE '📋 asset_checkins: % 条记录, 最新: %', v_count, v_latest;
    ELSE
        RAISE NOTICE '✅ asset_checkins 表不存在';
    END IF;
    
    -- 检查 oval_office_checkins（旧表）
    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'oval_office_checkins') THEN
        SELECT COUNT(*), MAX(created_at) INTO v_count, v_latest
        FROM oval_office_checkins;
        RAISE NOTICE '📋 oval_office_checkins: % 条记录, 最新: %', v_count, v_latest;
    ELSE
        RAISE NOTICE '✅ oval_office_checkins 表不存在';
    END IF;
    
    -- 检查 building_checkins（更早期的表，如果存在）
    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'building_checkins') THEN
        SELECT COUNT(*) INTO v_count FROM building_checkins;
        RAISE NOTICE '📋 building_checkins: % 条记录 (早期版本)', v_count;
    ELSE
        RAISE NOTICE '✅ building_checkins 表不存在';
    END IF;
END $$;

-- ============================================================================
-- 第三部分：当前应用使用的表（不要删除！）
-- ============================================================================

-- ✅ 应用正在使用的表：
-- - threads                 (Thread记录)
-- - oval_office_threads     (Oval Office Thread记录)
-- - bids                    (竞价记录)
-- - transfer_requests       (转让请求)
-- - user_xp                 (用户XP)

-- 验证这些表存在
SELECT 
    tablename,
    CASE 
        WHEN tablename IN ('threads', 'oval_office_threads', 'bids', 'transfer_requests', 'user_xp') 
        THEN '✅ 应用使用中'
        ELSE '⚠️ 可能是旧表'
    END as status
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY status DESC, tablename;

-- ============================================================================
-- 第四部分：备份旧表（推荐，可选执行）
-- ============================================================================

-- 方案A：重命名为备份（推荐）
-- 这样可以在需要时快速恢复

-- 重命名 asset_checkins 为备份
-- ALTER TABLE IF EXISTS asset_checkins 
-- RENAME TO asset_checkins_backup_20251027;

-- 重命名 oval_office_checkins 为备份
-- ALTER TABLE IF EXISTS oval_office_checkins 
-- RENAME TO oval_office_checkins_backup_20251027;

-- 重命名 building_checkins 为备份（如果存在）
-- ALTER TABLE IF EXISTS building_checkins 
-- RENAME TO building_checkins_backup_20251027;

-- ============================================================================
-- 第五部分：删除旧表（谨慎操作！）
-- ============================================================================

-- ⚠️⚠️⚠️ 警告 ⚠️⚠️⚠️
-- 以下命令会永久删除数据！
-- 请确保：
-- 1. 已经备份数据库
-- 2. 新系统运行正常至少7天
-- 3. 确认不需要旧数据
-- 4. 已经复制重要数据到新表
-- ⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️

-- 删除旧表前的最后检查
DO $$
BEGIN
    -- 检查新表是否有数据
    IF (SELECT COUNT(*) FROM threads) = 0 THEN
        RAISE EXCEPTION '❌ threads 表为空！不能删除旧表！';
    END IF;
    
    IF (SELECT COUNT(*) FROM oval_office_threads) = 0 THEN
        RAISE EXCEPTION '❌ oval_office_threads 表为空！不能删除旧表！';
    END IF;
    
    RAISE NOTICE '✅ 新表有数据，可以安全删除旧表';
END $$;

-- 取消以下命令的注释以执行删除（谨慎！）

-- 删除 asset_checkins（旧表）
-- DROP TABLE IF EXISTS asset_checkins CASCADE;

-- 删除 oval_office_checkins（旧表）
-- DROP TABLE IF EXISTS oval_office_checkins CASCADE;

-- 删除 building_checkins（早期版本，如果存在）
-- DROP TABLE IF EXISTS building_checkins CASCADE;

-- ============================================================================
-- 第六部分：删除旧备份表（30天后执行）
-- ============================================================================

-- 如果之前创建了备份表，30天后可以删除

-- 删除备份表
-- DROP TABLE IF EXISTS asset_checkins_backup_20251027 CASCADE;
-- DROP TABLE IF EXISTS oval_office_checkins_backup_20251027 CASCADE;
-- DROP TABLE IF EXISTS building_checkins_backup_20251027 CASCADE;

-- ============================================================================
-- 第七部分：清理孤立的存储对象（可选）
-- ============================================================================

-- 查看storage中的buckets
SELECT 
    id,
    name,
    public,
    created_at
FROM storage.buckets
ORDER BY name;

-- 可能需要删除的旧buckets（如果创建了新的）：
-- - asset_checkin_images（如果已迁移到thread_images）
-- - oval_office_images（如果已迁移到oval_office_thread_images）

-- ⚠️ 删除bucket会删除其中的所有文件！
-- DELETE FROM storage.buckets WHERE name = 'asset_checkin_images';
-- DELETE FROM storage.buckets WHERE name = 'oval_office_images';

-- ============================================================================
-- 第八部分：验证清理结果
-- ============================================================================

-- 清理后，验证只剩下应用使用的表
SELECT 
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- 预期结果应该只有：
-- - bids
-- - oval_office_threads
-- - threads
-- - transfer_requests  
-- - user_xp

-- ============================================================================
-- 执行建议
-- ============================================================================
--
-- 🔴 保守方案（推荐）：
-- 1. 先执行"第四部分"：重命名旧表为备份
-- 2. 运行应用测试7天
-- 3. 确认无问题后，执行"第五部分"：删除旧表
-- 4. 30天后执行"第六部分"：删除备份表
--
-- 🟡 激进方案（不推荐）：
-- 1. 直接执行"第五部分"：删除旧表
-- 2. 立即测试应用
-- 3. 如有问题从备份恢复
--
-- 🟢 最安全方案：
-- 1. 永久保留备份表
-- 2. 只在磁盘空间不足时删除
--
-- ============================================================================

-- ============================================================================
-- 快速清理命令（仅供参考）
-- ============================================================================

-- 如果您确定要立即清理，可以执行：
/*
BEGIN;

-- 检查新表有数据
DO $$
BEGIN
    IF (SELECT COUNT(*) FROM threads) = 0 THEN
        RAISE EXCEPTION 'threads表为空，中止删除';
    END IF;
END $$;

-- 重命名旧表为备份
ALTER TABLE IF EXISTS asset_checkins RENAME TO asset_checkins_backup_20251027;
ALTER TABLE IF EXISTS oval_office_checkins RENAME TO oval_office_checkins_backup_20251027;

-- 验证
SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;

COMMIT;
*/

-- ============================================================================
-- 完成！
-- ============================================================================

