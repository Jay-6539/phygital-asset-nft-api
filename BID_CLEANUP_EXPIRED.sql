-- ============================================================================
-- Bid自动清理 - 将过期的pending/countered Bid标记为expired
-- ============================================================================
-- 功能：自动清理过期的Bid，释放数据库空间，保持数据整洁
-- 使用：可设置为Supabase Cron Job（每小时执行一次）
-- ============================================================================

-- 1. 创建清理过期Bid的函数
-- ============================================================================
DROP FUNCTION IF EXISTS cleanup_expired_bids();

CREATE OR REPLACE FUNCTION cleanup_expired_bids()
RETURNS TABLE (
    cleaned_count INTEGER,
    details TEXT
) AS $$
DECLARE
    expired_count INTEGER;
BEGIN
    -- 将过期的pending/countered Bid标记为expired
    UPDATE bids
    SET 
        status = 'expired',
        updated_at = NOW()
    WHERE expires_at < NOW()
    AND status IN ('pending', 'countered');
    
    -- 获取更新的行数
    GET DIAGNOSTICS expired_count = ROW_COUNT;
    
    -- 返回清理结果
    RETURN QUERY
    SELECT 
        expired_count,
        'Cleaned ' || expired_count::TEXT || ' expired bid(s)' as details;
    
    -- 记录到日志（如果有日志表的话）
    RAISE NOTICE 'Cleaned % expired bid(s)', expired_count;
END;
$$ LANGUAGE plpgsql;

-- 授权
GRANT EXECUTE ON FUNCTION cleanup_expired_bids() TO anon, authenticated;

-- 2. 测试函数
-- ============================================================================
-- 手动执行测试：
-- SELECT * FROM cleanup_expired_bids();
--
-- 预期输出示例：
-- cleaned_count | details
-- --------------+-------------------------
-- 5             | Cleaned 5 expired bid(s)

-- 3. 设置Supabase Cron Job（可选）
-- ============================================================================
-- 在Supabase Dashboard中设置定时任务：
-- 1. 进入 Database → Cron Jobs
-- 2. 创建新任务：
--    - Name: cleanup_expired_bids
--    - Schedule: 0 * * * * (每小时整点执行)
--    - Command: SELECT cleanup_expired_bids();
--
-- 或使用pg_cron扩展（如果已启用）：
/*
SELECT cron.schedule(
    'cleanup-expired-bids',
    '0 * * * *',  -- 每小时
    $$SELECT cleanup_expired_bids();$$
);
*/

-- 4. 查看过期Bid统计
-- ============================================================================
CREATE OR REPLACE FUNCTION get_expired_bid_stats()
RETURNS TABLE (
    total_expired BIGINT,
    by_status JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*) as total_expired,
        jsonb_object_agg(
            status, 
            count
        ) as by_status
    FROM (
        SELECT 
            status,
            COUNT(*) as count
        FROM bids
        WHERE expires_at < NOW()
        GROUP BY status
    ) stats;
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION get_expired_bid_stats() TO anon, authenticated;

-- 测试：
-- SELECT * FROM get_expired_bid_stats();
--
-- 预期输出示例：
-- total_expired | by_status
-- --------------+----------------------------------
-- 10            | {"pending": 6, "countered": 4}

-- 5. 手动清理rejected/cancelled/expired Bid（可选，定期执行）
-- ============================================================================
-- 这个函数会永久删除已完成/拒绝/取消/过期超过30天的Bid
-- 警告：此操作不可恢复！

DROP FUNCTION IF EXISTS cleanup_old_bids(INTEGER);

CREATE OR REPLACE FUNCTION cleanup_old_bids(days_old INTEGER DEFAULT 30)
RETURNS TABLE (
    deleted_count INTEGER,
    details TEXT
) AS $$
DECLARE
    deleted INTEGER;
BEGIN
    -- 删除30天前的rejected/cancelled/expired Bid
    DELETE FROM bids
    WHERE status IN ('rejected', 'cancelled', 'expired')
    AND updated_at < NOW() - (days_old || ' days')::INTERVAL;
    
    GET DIAGNOSTICS deleted = ROW_COUNT;
    
    RETURN QUERY
    SELECT 
        deleted,
        'Deleted ' || deleted::TEXT || ' old bid(s) older than ' || days_old::TEXT || ' days';
    
    RAISE NOTICE 'Deleted % old bid(s)', deleted;
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION cleanup_old_bids(INTEGER) TO anon, authenticated;

-- 测试：
-- SELECT * FROM cleanup_old_bids(30);

-- ============================================================================
-- 使用说明
-- ============================================================================
-- 1. 在Supabase SQL Editor中执行此脚本
-- 2. 手动测试清理函数：
--    SELECT * FROM cleanup_expired_bids();
-- 3. 设置定时任务（推荐每小时执行一次）
-- 4. 定期查看统计：
--    SELECT * FROM get_expired_bid_stats();
-- 5. 可选：每月清理旧Bid：
--    SELECT * FROM cleanup_old_bids(30);
-- ============================================================================

-- ============================================================================
-- 验证SQL
-- ============================================================================
-- 查看即将被清理的Bid
SELECT 
    id,
    bidder_username,
    owner_username,
    bid_amount,
    status,
    expires_at,
    NOW() - expires_at as overdue_by
FROM bids
WHERE expires_at < NOW()
AND status IN ('pending', 'countered')
ORDER BY expires_at ASC
LIMIT 10;
-- ============================================================================

