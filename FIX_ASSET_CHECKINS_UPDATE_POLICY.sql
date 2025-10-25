-- ============================================================================
-- 修复：为 asset_checkins 表添加 UPDATE 策略
-- ============================================================================
-- 问题：Bid完成后无法转移资产所有权，因为缺少UPDATE策略
-- 解决：添加允许更新username字段的RLS策略
-- ============================================================================

-- 1. 删除旧的UPDATE策略（如果存在）
-- ============================================================================
DROP POLICY IF EXISTS "Allow public update" ON asset_checkins;
DROP POLICY IF EXISTS "Allow update for asset transfer" ON asset_checkins;

-- 2. 创建新的UPDATE策略：允许所有人更新
-- ============================================================================
CREATE POLICY "Allow public update"
    ON asset_checkins
    FOR UPDATE
    USING (true)
    WITH CHECK (true);

-- 说明：
-- - USING (true): 允许更新任何行
-- - WITH CHECK (true): 允许更新任何字段
-- 
-- 生产环境建议：
-- 可以限制只允许通过特定条件更新，例如：
-- CREATE POLICY "Allow update for asset transfer"
--     ON asset_checkins
--     FOR UPDATE
--     USING (true)  -- 允许读取任何行
--     WITH CHECK (
--         -- 只允许更新username和updated_at字段
--         username IS NOT NULL
--     );

-- 3. 同样为 oval_office_checkins 表添加UPDATE策略
-- ============================================================================
DROP POLICY IF EXISTS "Allow public update" ON oval_office_checkins;

CREATE POLICY "Allow public update"
    ON oval_office_checkins
    FOR UPDATE
    USING (true)
    WITH CHECK (true);

-- 4. 验证策略已创建
-- ============================================================================
-- 查看 asset_checkins 的所有策略
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE tablename = 'asset_checkins'
ORDER BY policyname;

-- 查看 oval_office_checkins 的所有策略
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE tablename = 'oval_office_checkins'
ORDER BY policyname;

-- ============================================================================
-- 使用说明
-- ============================================================================
-- 1. 登录 Supabase Dashboard
-- 2. 进入 SQL Editor
-- 3. 复制粘贴上面的SQL
-- 4. 点击 "Run" 执行
-- 5. 查看输出验证策略已创建
-- 6. 重新测试 Bid Accept 功能
-- ============================================================================

-- ============================================================================
-- 预期结果
-- ============================================================================
-- 执行后应该看到以下策略：
--
-- asset_checkins:
-- - Allow public read access (SELECT)
-- - Allow public insert (INSERT)
-- - Allow public update (UPDATE)  ← 新增
--
-- oval_office_checkins:
-- - Allow public read access (SELECT)
-- - Allow public insert (INSERT)
-- - Allow public update (UPDATE)  ← 新增
-- ============================================================================

