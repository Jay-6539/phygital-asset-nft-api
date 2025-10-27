-- ============================================================================
-- 数据库命名完整迁移 - Supabase
-- ============================================================================
-- 本脚本将数据库表名和字段名更新为新的命名规范：
-- - asset_checkins → threads
-- - oval_office_checkins → oval_office_threads
-- - 相关字段和注释全部更新
--
-- ⚠️ 重要提示：
-- 1. 请在执行前备份数据库
-- 2. 建议在测试环境先执行验证
-- 3. 执行后需要同步更新应用代码
-- ============================================================================

-- ============================================================================
-- 第一部分：创建新表
-- ============================================================================

-- 1. 创建 threads 表（替代 asset_checkins）
-- ============================================================================
CREATE TABLE IF NOT EXISTS threads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    building_id TEXT NOT NULL,              -- Building ID
    username TEXT NOT NULL,                  -- Thread创建者用户名
    asset_name TEXT,                         -- Thread资产名称
    description TEXT NOT NULL DEFAULT '',   -- Thread描述
    image_url TEXT,                          -- Thread图片URL
    nfc_uuid TEXT,                           -- NFC标签UUID
    gps_latitude DOUBLE PRECISION,           -- GPS纬度
    gps_longitude DOUBLE PRECISION,          -- GPS经度
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. 创建 oval_office_threads 表（替代 oval_office_checkins）
-- ============================================================================
CREATE TABLE IF NOT EXISTS oval_office_threads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username TEXT NOT NULL,                  -- Thread创建者用户名
    asset_name TEXT NOT NULL,                -- Thread资产名称
    description TEXT DEFAULT '',             -- Thread描述
    image_url TEXT,                          -- Thread图片URL
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- 第二部分：迁移现有数据
-- ============================================================================

-- 迁移 asset_checkins → threads
INSERT INTO threads (
    id, building_id, username, asset_name, description, 
    image_url, nfc_uuid, gps_latitude, gps_longitude, 
    created_at, updated_at
)
SELECT 
    id, building_id, username, asset_name, description,
    image_url, nfc_uuid, gps_latitude, gps_longitude,
    created_at, updated_at
FROM asset_checkins
ON CONFLICT (id) DO NOTHING;

-- 迁移 oval_office_checkins → oval_office_threads
INSERT INTO oval_office_threads (
    id, username, asset_name, description, image_url, 
    created_at, updated_at
)
SELECT 
    id, username, asset_name, description, image_url,
    created_at, updated_at
FROM oval_office_checkins
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 第三部分：创建索引
-- ============================================================================

-- threads 表索引
CREATE INDEX IF NOT EXISTS idx_threads_building_id ON threads(building_id);
CREATE INDEX IF NOT EXISTS idx_threads_created_at ON threads(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_threads_username ON threads(username);
CREATE INDEX IF NOT EXISTS idx_threads_nfc_uuid ON threads(nfc_uuid);

-- oval_office_threads 表索引
CREATE INDEX IF NOT EXISTS idx_oval_threads_username ON oval_office_threads(username);
CREATE INDEX IF NOT EXISTS idx_oval_threads_created_at ON oval_office_threads(created_at DESC);

-- ============================================================================
-- 第四部分：启用RLS（Row Level Security）
-- ============================================================================

-- threads 表 RLS
ALTER TABLE threads ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can read threads" ON threads;
DROP POLICY IF EXISTS "Anyone can create threads" ON threads;
DROP POLICY IF EXISTS "Users can update own threads" ON threads;

CREATE POLICY "Anyone can read threads"
    ON threads FOR SELECT
    USING (true);

CREATE POLICY "Anyone can create threads"
    ON threads FOR INSERT
    WITH CHECK (true);

CREATE POLICY "Users can update own threads"
    ON threads FOR UPDATE
    USING (true);  -- 暂时允许所有人更新（用于Bid转移所有权）

-- oval_office_threads 表 RLS
ALTER TABLE oval_office_threads ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can read oval threads" ON oval_office_threads;
DROP POLICY IF EXISTS "Anyone can create oval threads" ON oval_office_threads;
DROP POLICY IF EXISTS "Users can update own oval threads" ON oval_office_threads;

CREATE POLICY "Anyone can read oval threads"
    ON oval_office_threads FOR SELECT
    USING (true);

CREATE POLICY "Anyone can create oval threads"
    ON oval_office_threads FOR INSERT
    WITH CHECK (true);

CREATE POLICY "Users can update own oval threads"
    ON oval_office_threads FOR UPDATE
    USING (true);

-- ============================================================================
-- 第五部分：创建或更新触发器
-- ============================================================================

-- threads 表自动更新 updated_at
CREATE OR REPLACE FUNCTION update_threads_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_threads_updated_at ON threads;

CREATE TRIGGER trigger_update_threads_updated_at
    BEFORE UPDATE ON threads
    FOR EACH ROW
    EXECUTE FUNCTION update_threads_updated_at();

-- oval_office_threads 表自动更新 updated_at
CREATE OR REPLACE FUNCTION update_oval_threads_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_oval_threads_updated_at ON oval_office_threads;

CREATE TRIGGER trigger_update_oval_threads_updated_at
    BEFORE UPDATE ON oval_office_threads
    FOR EACH ROW
    EXECUTE FUNCTION update_oval_threads_updated_at();

-- ============================================================================
-- 第六部分：添加注释
-- ============================================================================

-- threads 表注释
COMMENT ON TABLE threads IS 'Thread记录表 - 用户在Building或NFC上创建的记录';
COMMENT ON COLUMN threads.id IS 'Thread唯一标识符 (UUID)';
COMMENT ON COLUMN threads.building_id IS 'Building ID - 关联的建筑或NFC标识';
COMMENT ON COLUMN threads.username IS 'Thread创建者和当前拥有者的用户名';
COMMENT ON COLUMN threads.asset_name IS 'Thread资产名称（用户自定义）';
COMMENT ON COLUMN threads.description IS 'Thread描述内容';
COMMENT ON COLUMN threads.image_url IS 'Thread图片URL';
COMMENT ON COLUMN threads.nfc_uuid IS 'NFC标签UUID - Thread关联的物理位置';
COMMENT ON COLUMN threads.gps_latitude IS 'Thread创建时的GPS纬度';
COMMENT ON COLUMN threads.gps_longitude IS 'Thread创建时的GPS经度';
COMMENT ON COLUMN threads.created_at IS 'Thread创建时间';
COMMENT ON COLUMN threads.updated_at IS 'Thread最后更新时间';

-- oval_office_threads 表注释
COMMENT ON TABLE oval_office_threads IS 'Oval Office Thread记录表 - 特殊位置的Thread';
COMMENT ON COLUMN oval_office_threads.id IS 'Thread唯一标识符 (UUID)';
COMMENT ON COLUMN oval_office_threads.username IS 'Thread创建者和当前拥有者的用户名';
COMMENT ON COLUMN oval_office_threads.asset_name IS 'Thread资产名称';
COMMENT ON COLUMN oval_office_threads.description IS 'Thread描述';
COMMENT ON COLUMN oval_office_threads.image_url IS 'Thread图片URL';
COMMENT ON COLUMN oval_office_threads.created_at IS 'Thread创建时间';
COMMENT ON COLUMN oval_office_threads.updated_at IS 'Thread最后更新时间';

-- bids 表注释更新
COMMENT ON TABLE bids IS 'Thread竞价表 - 用户使用Echo对Thread进行出价和交易';
COMMENT ON COLUMN bids.record_id IS 'Thread ID - 关联threads或oval_office_threads表';
COMMENT ON COLUMN bids.record_type IS 'Thread类型: building 或 oval_office';
COMMENT ON COLUMN bids.building_id IS 'Building ID（如果是building类型的Thread）';
COMMENT ON COLUMN bids.bid_amount IS '出价金额 - Echo数量';
COMMENT ON COLUMN bids.counter_amount IS '反价金额 - Echo数量';

-- transfer_requests 表注释更新
COMMENT ON TABLE transfer_requests IS 'Thread转让请求表 - 用户之间转移Thread所有权';
COMMENT ON COLUMN transfer_requests.record_id IS 'Thread记录ID';
COMMENT ON COLUMN transfer_requests.record_type IS 'Thread类型: building 或 oval_office';
COMMENT ON COLUMN transfer_requests.nfc_uuid IS 'NFC标签UUID - Thread关联的位置';
COMMENT ON COLUMN transfer_requests.building_name IS 'Building名称';
COMMENT ON COLUMN transfer_requests.asset_name IS 'Thread资产名称';

-- ============================================================================
-- 第七部分：验证迁移
-- ============================================================================

-- 验证数据迁移完整性
DO $$
DECLARE
    old_count INTEGER;
    new_count INTEGER;
BEGIN
    -- 检查 asset_checkins → threads
    SELECT COUNT(*) INTO old_count FROM asset_checkins;
    SELECT COUNT(*) INTO new_count FROM threads;
    
    IF old_count = new_count THEN
        RAISE NOTICE '✅ threads 表迁移成功: % 条记录', new_count;
    ELSE
        RAISE WARNING '⚠️ threads 表记录数不匹配: 旧表 % vs 新表 %', old_count, new_count;
    END IF;
    
    -- 检查 oval_office_checkins → oval_office_threads
    SELECT COUNT(*) INTO old_count FROM oval_office_checkins;
    SELECT COUNT(*) INTO new_count FROM oval_office_threads;
    
    IF old_count = new_count THEN
        RAISE NOTICE '✅ oval_office_threads 表迁移成功: % 条记录', new_count;
    ELSE
        RAISE WARNING '⚠️ oval_office_threads 表记录数不匹配: 旧表 % vs 新表 %', old_count, new_count;
    END IF;
END $$;

-- ============================================================================
-- 第八部分：清理旧表（谨慎操作！）
-- ============================================================================
-- ⚠️ 警告：只有在确认新表工作正常后才执行以下命令！
-- ⚠️ 建议先运行应用测试几天，确保一切正常

-- 步骤1：重命名旧表（保留备份）
-- ALTER TABLE asset_checkins RENAME TO asset_checkins_backup_20251027;
-- ALTER TABLE oval_office_checkins RENAME TO oval_office_checkins_backup_20251027;

-- 步骤2：确认应用运行正常后，删除备份表（可选）
-- DROP TABLE IF EXISTS asset_checkins_backup_20251027;
-- DROP TABLE IF EXISTS oval_office_checkins_backup_20251027;

-- ============================================================================
-- 第九部分：Storage Bucket重命名（需要在Supabase Dashboard手动操作）
-- ============================================================================
-- ⚠️ 注意：Storage bucket无法直接重命名，需要手动操作：
--
-- 方案1：创建新bucket并迁移文件（推荐）
-- 1. 在Supabase Dashboard → Storage 创建新bucket：
--    - thread_images（替代 asset_checkin_images）
--    - oval_office_thread_images（替代 oval_office_images，如果需要）
-- 2. 设置为public bucket
-- 3. 复制RLS策略
-- 4. 迁移现有图片（可选，或保持旧bucket继续工作）
--
-- 方案2：保持旧bucket名称继续使用
-- - asset_checkin_images 继续存储Thread图片
-- - oval_office_images 继续存储Oval Office Thread图片
-- - 只在代码中更新引用即可
--
-- 推荐方案2（保持bucket名称），因为：
-- - 避免大量文件迁移
-- - 现有图片URL不会失效
-- - 降低迁移风险
-- ============================================================================

-- ============================================================================
-- 完成！数据库表迁移完成
-- ============================================================================
-- 
-- ✅ 已完成：
-- 1. 创建新表 threads 和 oval_office_threads
-- 2. 迁移所有现有数据
-- 3. 创建索引
-- 4. 设置RLS策略
-- 5. 创建触发器
-- 6. 添加注释
--
-- ⚠️ 验证步骤：
-- 1. 检查数据迁移完整性（运行验证脚本）
-- 2. 更新应用代码中的表名引用
-- 3. 测试所有Thread相关功能
-- 4. 测试Bid和Transfer功能
-- 5. 检查Market数据统计
--
-- 🔄 下一步：
-- 1. 更新应用代码（参考 APP_CODE_MIGRATION_GUIDE.md）
-- 2. 测试应用功能
-- 3. 确认无误后删除旧表备份
--
-- 📞 回滚方案：
-- 如果出现问题，重新执行旧的SUPABASE_SETUP_GUIDE.md中的脚本
-- 或恢复旧表：
--   ALTER TABLE asset_checkins_backup_20251027 RENAME TO asset_checkins;
--   ALTER TABLE oval_office_checkins_backup_20251027 RENAME TO oval_office_checkins;
--
-- ============================================================================

