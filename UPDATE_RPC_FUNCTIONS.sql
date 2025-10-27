-- ============================================================================
-- 紧急修复：更新RPC函数以使用新表名
-- ============================================================================
-- 错误原因：RPC函数还在引用旧表 asset_checkins 和 oval_office_checkins
-- 解决方案：重新创建所有RPC函数，使用新表名 threads 和 oval_office_threads
-- ============================================================================

-- ⚠️ 请立即在Supabase SQL Editor中执行此脚本！

-- 1. 获取热门建筑（按记录数排序）
-- ============================================================================
CREATE OR REPLACE FUNCTION get_trending_buildings(record_limit INT DEFAULT 20)
RETURNS TABLE (
    building_id TEXT,
    record_count BIGINT,
    last_activity TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ac.building_id,
        COUNT(*) as record_count,
        MAX(ac.created_at) as last_activity
    FROM threads ac
    GROUP BY ac.building_id
    ORDER BY record_count DESC
    LIMIT record_limit;
END;
$$ LANGUAGE plpgsql;

-- 2. 获取最活跃用户
-- ============================================================================
CREATE OR REPLACE FUNCTION get_top_users(user_limit INT DEFAULT 20)
RETURNS TABLE (
    username TEXT,
    total_records BIGINT,
    unique_buildings BIGINT,
    transfer_count BIGINT,
    activity_score BIGINT
) AS $$
BEGIN
    RETURN QUERY
    WITH all_users AS (
        SELECT DISTINCT ac.username FROM threads ac
        UNION
        SELECT DISTINCT tr.from_user AS username FROM transfer_requests tr WHERE tr.from_user IS NOT NULL
        UNION
        SELECT DISTINCT tr.to_user AS username FROM transfer_requests tr WHERE tr.to_user IS NOT NULL
        UNION
        SELECT DISTINCT b.bidder_username AS username FROM bids b WHERE b.bidder_username IS NOT NULL
        UNION
        SELECT DISTINCT b.owner_username AS username FROM bids b WHERE b.owner_username IS NOT NULL
        UNION
        SELECT DISTINCT oc.username FROM oval_office_threads oc WHERE oc.username IS NOT NULL
    )
    SELECT 
        au.username,
        COALESCE((SELECT COUNT(*) FROM threads ac WHERE ac.username = au.username), 0) as total_records,
        COALESCE((SELECT COUNT(DISTINCT building_id) FROM threads ac WHERE ac.username = au.username), 0) as unique_buildings,
        COALESCE(
            (SELECT COUNT(*) FROM transfer_requests tr WHERE tr.from_user = au.username AND tr.status = 'completed'), 0
        ) + COALESCE(
            (SELECT COUNT(*) FROM bids b WHERE b.owner_username = au.username AND b.status = 'completed'), 0
        ) as transfer_count,
        (
            COALESCE((SELECT COUNT(*) FROM threads ac WHERE ac.username = au.username), 0) * 10 + 
            COALESCE((SELECT COUNT(*) FROM oval_office_threads oc WHERE oc.username = au.username), 0) * 10 +
            COALESCE((SELECT COUNT(DISTINCT building_id) FROM threads ac WHERE ac.username = au.username), 0) * 50 +
            COALESCE((SELECT COUNT(*) FROM transfer_requests tr WHERE tr.from_user = au.username AND tr.status = 'completed'), 0) * 20 +
            COALESCE((SELECT COUNT(*) FROM bids b WHERE b.owner_username = au.username AND b.status = 'completed'), 0) * 20
        )::BIGINT as activity_score
    FROM all_users au
    WHERE au.username IS NOT NULL AND au.username != ''
    ORDER BY activity_score DESC
    LIMIT user_limit;
END;
$$ LANGUAGE plpgsql;

-- 3. 获取Market总体统计
-- ============================================================================
CREATE OR REPLACE FUNCTION get_market_stats()
RETURNS TABLE (
    total_buildings BIGINT,
    total_records BIGINT,
    active_users BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(DISTINCT building_id) as total_buildings,
        COUNT(*) as total_records,
        COUNT(DISTINCT username) as active_users
    FROM threads;
END;
$$ LANGUAGE plpgsql;

-- 4. 获取交易最多的记录
-- ============================================================================
DROP FUNCTION IF EXISTS get_most_traded_records(INT);

CREATE OR REPLACE FUNCTION get_most_traded_records(record_limit INT DEFAULT 20)
RETURNS TABLE (
    id UUID,
    building_id TEXT,
    building_name TEXT,
    asset_name TEXT,
    image_url TEXT,
    username TEXT,
    transfer_count BIGINT,
    created_at TIMESTAMP WITH TIME ZONE,
    notes TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ac.id,
        ac.building_id,
        ''::TEXT as building_name,
        ac.asset_name,
        ac.image_url,
        ac.username,
        COALESCE(
            (SELECT COUNT(*) 
             FROM transfer_requests tr 
             WHERE tr.record_id::text = ac.id::text
             AND tr.record_type = 'building'
             AND tr.status = 'completed'
            ) +
            (SELECT COUNT(*)
             FROM bids b
             WHERE b.record_id = ac.id
             AND b.record_type = 'building'
             AND b.status = 'completed'
            ), 0
        ) as transfer_count,
        ac.created_at,
        ac.description as notes
    FROM threads ac
    WHERE ac.id::text IN (
        SELECT DISTINCT record_id 
        FROM transfer_requests 
        WHERE record_type = 'building'
        AND status = 'completed'
    ) OR ac.id IN (
        SELECT DISTINCT record_id
        FROM bids
        WHERE record_type = 'building'
        AND status = 'completed'
    )
    ORDER BY transfer_count DESC
    LIMIT record_limit;
END;
$$ LANGUAGE plpgsql;

-- 5. 获取Oval Office Threads的热门统计
-- ============================================================================
CREATE OR REPLACE FUNCTION get_trending_oval_assets(record_limit INT DEFAULT 20)
RETURNS TABLE (
    asset_name TEXT,
    record_count BIGINT,
    last_activity TIMESTAMP WITH TIME ZONE,
    unique_owners BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        oc.asset_name,
        COUNT(*) as record_count,
        MAX(oc.created_at) as last_activity,
        COUNT(DISTINCT oc.username) as unique_owners
    FROM oval_office_threads oc
    WHERE oc.asset_name IS NOT NULL
    GROUP BY oc.asset_name
    ORDER BY record_count DESC
    LIMIT record_limit;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 权限设置
-- ============================================================================
GRANT EXECUTE ON FUNCTION get_trending_buildings(INT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_top_users(INT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_market_stats() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_most_traded_records(INT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_trending_oval_assets(INT) TO anon, authenticated;

-- ============================================================================
-- 验证函数
-- ============================================================================
-- 测试所有函数
SELECT 'get_market_stats' as function_name, * FROM get_market_stats();
SELECT 'get_trending_buildings' as function_name, * FROM get_trending_buildings(5);
SELECT 'get_top_users' as function_name, * FROM get_top_users(5);
SELECT 'get_most_traded_records' as function_name, * FROM get_most_traded_records(5);
SELECT 'get_trending_oval_assets' as function_name, * FROM get_trending_oval_assets(5);

-- ============================================================================
-- 完成！
-- ============================================================================
-- 执行此脚本后，Market功能应该立即恢复正常
-- ============================================================================

