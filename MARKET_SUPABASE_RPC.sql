-- ============================================================================
-- Market功能的Supabase RPC函数
-- 在Supabase SQL Editor中执行这些函数
-- ============================================================================

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

-- 测试查询:
-- SELECT * FROM get_trending_buildings(10);


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
        -- 获取所有用户（包括没有asset的用户）
        -- 1. 所有曾经check-in的用户
        SELECT DISTINCT ac.username FROM threads ac
        UNION
        -- 2. 所有transfer_requests中的用户（无论状态）
        SELECT DISTINCT tr.from_user AS username FROM transfer_requests tr WHERE tr.from_user IS NOT NULL
        UNION
        SELECT DISTINCT tr.to_user AS username FROM transfer_requests tr WHERE tr.to_user IS NOT NULL
        UNION
        -- 3. 所有bids中的用户（无论状态）
        SELECT DISTINCT b.bidder_username AS username FROM bids b WHERE b.bidder_username IS NOT NULL
        UNION
        SELECT DISTINCT b.owner_username AS username FROM bids b WHERE b.owner_username IS NOT NULL
        UNION
        -- 4. Oval Office用户
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
            -- Building check-ins: 10分/个
            COALESCE((SELECT COUNT(*) FROM threads ac WHERE ac.username = au.username), 0) * 10 + 
            -- Oval Office check-ins: 10分/个
            COALESCE((SELECT COUNT(*) FROM oval_office_threads oc WHERE oc.username = au.username), 0) * 10 +
            -- 独立建筑数: 50分/个
            COALESCE((SELECT COUNT(DISTINCT building_id) FROM threads ac WHERE ac.username = au.username), 0) * 50 +
            -- 通过transfer_requests完成的转让: 20分/次
            COALESCE((SELECT COUNT(*) FROM transfer_requests tr WHERE tr.from_user = au.username AND tr.status = 'completed'), 0) * 20 +
            -- 通过bids完成的卖出: 20分/次
            COALESCE((SELECT COUNT(*) FROM bids b WHERE b.owner_username = au.username AND b.status = 'completed'), 0) * 20
        )::BIGINT as activity_score
    FROM all_users au
    WHERE au.username IS NOT NULL AND au.username != ''
    ORDER BY activity_score DESC
    LIMIT user_limit;
END;
$$ LANGUAGE plpgsql;

-- 测试查询:
-- SELECT * FROM get_top_users(10);

-- 调试查询 - 查看所有用户来源:
/*
WITH all_users_debug AS (
    SELECT DISTINCT username, 'threads' as source FROM threads
    UNION ALL
    SELECT DISTINCT from_user AS username, 'transfer_from' as source FROM transfer_requests WHERE from_user IS NOT NULL
    UNION ALL
    SELECT DISTINCT to_user AS username, 'transfer_to' as source FROM transfer_requests WHERE to_user IS NOT NULL
    UNION ALL
    SELECT DISTINCT bidder_username AS username, 'bid_buyer' as source FROM bids WHERE bidder_username IS NOT NULL
    UNION ALL
    SELECT DISTINCT owner_username AS username, 'bid_seller' as source FROM bids WHERE owner_username IS NOT NULL
    UNION ALL
    SELECT DISTINCT username, 'oval_office' as source FROM oval_office_threads WHERE username IS NOT NULL
)
SELECT username, STRING_AGG(DISTINCT source, ', ') as sources
FROM all_users_debug
GROUP BY username
ORDER BY username;
*/


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

-- 测试查询:
-- SELECT * FROM get_market_stats();


-- 4. 获取交易最多的记录
-- ============================================================================
-- 先删除旧函数（如果存在），因为返回类型已更改
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
        ''::TEXT as building_name,  -- 将在app中匹配
        ac.asset_name,
        ac.image_url,
        ac.username,
        COALESCE(
            -- 统计transfer_requests和bids两个来源的交易
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
        ac.description as notes  -- threads表中字段是description
    FROM threads ac
    WHERE ac.id::text IN (
        -- 选择有transfer_requests记录的
        SELECT DISTINCT record_id 
        FROM transfer_requests 
        WHERE record_type = 'building'
        AND status = 'completed'
    ) OR ac.id IN (
        -- 或选择有completed bids的
        SELECT DISTINCT record_id
        FROM bids
        WHERE record_type = 'building'
        AND status = 'completed'
    )
    ORDER BY transfer_count DESC
    LIMIT record_limit;
END;
$$ LANGUAGE plpgsql;

-- 测试查询:
-- SELECT * FROM get_most_traded_records(10);


-- 5. 获取Oval Office check-ins的热门统计
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

-- 测试查询:
-- SELECT * FROM get_trending_oval_assets(10);


-- ============================================================================
-- 权限设置（允许anon用户调用这些函数）
-- ============================================================================
GRANT EXECUTE ON FUNCTION get_trending_buildings(INT) TO anon;
GRANT EXECUTE ON FUNCTION get_top_users(INT) TO anon;
GRANT EXECUTE ON FUNCTION get_market_stats() TO anon;
GRANT EXECUTE ON FUNCTION get_most_traded_records(INT) TO anon;
GRANT EXECUTE ON FUNCTION get_trending_oval_assets(INT) TO anon;

-- ============================================================================
-- 使用说明
-- ============================================================================
-- 1. 在Supabase Dashboard中，进入SQL Editor
-- 2. 复制粘贴上面的所有SQL代码
-- 3. 点击"Run"执行
-- 4. 验证函数是否创建成功:
--    SELECT * FROM get_market_stats();
-- 5. 在app中，MarketDataManager会自动使用这些RPC函数
-- ============================================================================

