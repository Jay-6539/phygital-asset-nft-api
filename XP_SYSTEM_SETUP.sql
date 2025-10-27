-- ============================================================================
-- XP系统 - Supabase 数据库设置
-- ============================================================================
-- XP (Experience Points) 用于跟踪用户活跃度和等级

-- 1. 在 users/profiles 表中添加 XP 和 Level 字段
-- ============================================================================
-- 如果你已经有用户表，可以添加这些列
-- ALTER TABLE users ADD COLUMN IF NOT EXISTS xp INTEGER DEFAULT 0;
-- ALTER TABLE users ADD COLUMN IF NOT EXISTS level INTEGER DEFAULT 1;

-- 或者创建单独的 user_xp 表来跟踪XP
CREATE TABLE IF NOT EXISTS user_xp (
    username TEXT PRIMARY KEY,
    xp INTEGER NOT NULL DEFAULT 0,
    level INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. 创建索引
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_user_xp_level ON user_xp(level DESC);
CREATE INDEX IF NOT EXISTS idx_user_xp_xp ON user_xp(xp DESC);

-- 3. 启用RLS (Row Level Security)
-- ============================================================================
ALTER TABLE user_xp ENABLE ROW LEVEL SECURITY;

-- 4. 创建RLS策略
-- ============================================================================
DROP POLICY IF EXISTS "Anyone can view XP" ON user_xp;
DROP POLICY IF EXISTS "Users can update own XP" ON user_xp;

-- 允许所有人查看XP
CREATE POLICY "Anyone can view XP"
    ON user_xp FOR SELECT
    USING (true);

-- 允许所有人更新（应用层面控制）
CREATE POLICY "Users can update own XP"
    ON user_xp FOR ALL
    USING (true)
    WITH CHECK (true);

-- 5. 创建自动更新updated_at的触发器
-- ============================================================================
CREATE OR REPLACE FUNCTION update_user_xp_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    -- 自动计算等级（每1000 XP = 1级）
    NEW.level = GREATEST(1, (NEW.xp / 1000) + 1);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_user_xp_updated_at ON user_xp;

CREATE TRIGGER trigger_update_user_xp_updated_at
    BEFORE UPDATE ON user_xp
    FOR EACH ROW
    EXECUTE FUNCTION update_user_xp_updated_at();

-- 6. 创建RPC函数：添加XP
-- ============================================================================
DROP FUNCTION IF EXISTS add_xp(TEXT, INTEGER, TEXT);

CREATE OR REPLACE FUNCTION add_xp(
    username_param TEXT,
    xp_amount INTEGER,
    reason TEXT DEFAULT ''
)
RETURNS TABLE (
    username TEXT,
    new_xp INTEGER,
    new_level INTEGER,
    leveled_up BOOLEAN
) AS $$
DECLARE
    old_level INTEGER;
    current_xp INTEGER;
BEGIN
    -- 获取当前XP和等级
    SELECT xp, level INTO current_xp, old_level
    FROM user_xp
    WHERE user_xp.username = username_param;
    
    -- 如果用户不存在，创建记录
    IF NOT FOUND THEN
        INSERT INTO user_xp (username, xp, level)
        VALUES (username_param, xp_amount, GREATEST(1, (xp_amount / 1000) + 1))
        RETURNING user_xp.username, user_xp.xp, user_xp.level, FALSE
        INTO username, new_xp, new_level, leveled_up;
        
        RETURN NEXT;
        RETURN;
    END IF;
    
    -- 更新XP
    UPDATE user_xp
    SET xp = xp + xp_amount
    WHERE user_xp.username = username_param
    RETURNING user_xp.xp, user_xp.level INTO new_xp, new_level;
    
    -- 返回结果
    RETURN QUERY SELECT 
        username_param,
        new_xp,
        new_level,
        (new_level > old_level) AS leveled_up;
END;
$$ LANGUAGE plpgsql;

-- 授权
GRANT EXECUTE ON FUNCTION add_xp(TEXT, INTEGER, TEXT) TO anon, authenticated;

-- 7. 创建RPC函数：获取排行榜
-- ============================================================================
DROP FUNCTION IF EXISTS get_xp_leaderboard(INTEGER);

CREATE OR REPLACE FUNCTION get_xp_leaderboard(limit_count INTEGER DEFAULT 100)
RETURNS TABLE (
    rank INTEGER,
    username TEXT,
    xp INTEGER,
    level INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ROW_NUMBER() OVER (ORDER BY u.xp DESC)::INTEGER AS rank,
        u.username,
        u.xp,
        u.level
    FROM user_xp u
    ORDER BY u.xp DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- 授权
GRANT EXECUTE ON FUNCTION get_xp_leaderboard(INTEGER) TO anon, authenticated;

-- 8. 添加注释
-- ============================================================================
COMMENT ON TABLE user_xp IS '用户XP和等级跟踪表';
COMMENT ON COLUMN user_xp.username IS '用户名';
COMMENT ON COLUMN user_xp.xp IS '经验值';
COMMENT ON COLUMN user_xp.level IS '等级（自动计算：level = (xp / 1000) + 1）';

-- ============================================================================
-- XP奖励建议
-- ============================================================================
-- Thread创建: +10 XP
-- 发现新建筑: +50 XP
-- Thread转移: +20 XP
-- Bid被接受: +30 XP
-- 每日登录: +5 XP

-- ============================================================================
-- 测试查询
-- ============================================================================
-- 添加XP测试
-- SELECT * FROM add_xp('testuser', 100, 'Thread created');

-- 查看排行榜
-- SELECT * FROM get_xp_leaderboard(10);

-- ============================================================================
-- 完成！
-- ============================================================================

