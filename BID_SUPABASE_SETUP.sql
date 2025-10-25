-- ============================================================================
-- Bid竞价功能 - Supabase 数据库设置
-- ============================================================================
-- 请在Supabase SQL Editor中执行此脚本

-- 1. 创建bids表
-- ============================================================================
CREATE TABLE IF NOT EXISTS bids (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- 关联信息
    record_id UUID NOT NULL,
    record_type TEXT NOT NULL CHECK (record_type IN ('building', 'oval_office')),
    building_id TEXT,
    
    -- 买卖双方
    bidder_username TEXT NOT NULL,
    owner_username TEXT NOT NULL,
    
    -- 出价信息
    bid_amount INTEGER NOT NULL CHECK (bid_amount > 0),
    counter_amount INTEGER CHECK (counter_amount IS NULL OR counter_amount > 0),
    
    -- 联系方式（接受后才填写）
    bidder_contact TEXT,
    owner_contact TEXT,
    
    -- 状态管理
    status TEXT NOT NULL DEFAULT 'pending' CHECK (
        status IN ('pending', 'countered', 'accepted', 'completed', 'rejected', 'expired')
    ),
    
    -- 时间戳
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '7 days'),
    completed_at TIMESTAMP WITH TIME ZONE,
    
    -- 备注
    bidder_message TEXT,
    owner_message TEXT
);

-- 2. 创建索引以提高查询性能
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_bids_owner_status ON bids(owner_username, status);
CREATE INDEX IF NOT EXISTS idx_bids_bidder_status ON bids(bidder_username, status);
CREATE INDEX IF NOT EXISTS idx_bids_record ON bids(record_id, status);
CREATE INDEX IF NOT EXISTS idx_bids_status_expires ON bids(status, expires_at);
CREATE INDEX IF NOT EXISTS idx_bids_created ON bids(created_at DESC);

-- 3. 启用RLS (Row Level Security)
-- ============================================================================
ALTER TABLE bids ENABLE ROW LEVEL SECURITY;

-- 4. 创建RLS策略（先删除旧策略，避免重复创建错误）
-- ============================================================================
-- 删除已存在的策略
DROP POLICY IF EXISTS "Users can view related bids" ON bids;
DROP POLICY IF EXISTS "Users can create bids" ON bids;
DROP POLICY IF EXISTS "Users can update related bids" ON bids;

-- 用户可以查看与自己相关的Bid
CREATE POLICY "Users can view related bids"
    ON bids FOR SELECT
    USING (true);  -- 暂时允许所有人查看，生产环境应限制

-- 用户可以创建Bid
CREATE POLICY "Users can create bids"
    ON bids FOR INSERT
    WITH CHECK (true);

-- 用户可以更新自己相关的Bid
CREATE POLICY "Users can update related bids"
    ON bids FOR UPDATE
    USING (true);

-- 5. 创建自动更新updated_at的触发器
-- ============================================================================
CREATE OR REPLACE FUNCTION update_bids_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 删除已存在的触发器
DROP TRIGGER IF EXISTS trigger_update_bids_updated_at ON bids;

CREATE TRIGGER trigger_update_bids_updated_at
    BEFORE UPDATE ON bids
    FOR EACH ROW
    EXECUTE FUNCTION update_bids_updated_at();

-- 6. 创建RPC函数：获取未读Bid数量
-- ============================================================================
DROP FUNCTION IF EXISTS get_unread_bid_count(TEXT);

CREATE OR REPLACE FUNCTION get_unread_bid_count(username_param TEXT)
RETURNS INTEGER AS $$
BEGIN
    RETURN (
        SELECT COUNT(*)::INTEGER
        FROM bids
        WHERE owner_username = username_param
        AND status = 'pending'
        AND expires_at > NOW()
    );
END;
$$ LANGUAGE plpgsql;

-- 授权
GRANT EXECUTE ON FUNCTION get_unread_bid_count(TEXT) TO anon, authenticated;

-- 7. 创建RPC函数：获取我收到的Bid
-- ============================================================================
DROP FUNCTION IF EXISTS get_my_received_bids(TEXT);

CREATE OR REPLACE FUNCTION get_my_received_bids(username_param TEXT)
RETURNS TABLE (
    id UUID,
    record_id UUID,
    record_type TEXT,
    building_id TEXT,
    bidder_username TEXT,
    owner_username TEXT,
    bid_amount INTEGER,
    counter_amount INTEGER,
    bidder_contact TEXT,
    owner_contact TEXT,
    status TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    bidder_message TEXT,
    owner_message TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        b.id,
        b.record_id,
        b.record_type,
        b.building_id,
        b.bidder_username,
        b.owner_username,
        b.bid_amount,
        b.counter_amount,
        b.bidder_contact,
        b.owner_contact,
        b.status,
        b.created_at,
        b.updated_at,
        b.expires_at,
        b.completed_at,
        b.bidder_message,
        b.owner_message
    FROM bids b
    WHERE b.owner_username = username_param
    AND b.status IN ('pending', 'countered', 'accepted')  -- 增加accepted状态
    AND b.expires_at > NOW()
    ORDER BY 
        CASE b.status
            WHEN 'pending' THEN 1      -- pending优先显示
            WHEN 'countered' THEN 2    -- countered其次
            WHEN 'accepted' THEN 3     -- accepted最后
        END,
        b.updated_at DESC;             -- 同状态按更新时间排序
END;
$$ LANGUAGE plpgsql;

-- 授权
GRANT EXECUTE ON FUNCTION get_my_received_bids(TEXT) TO anon, authenticated;

-- 8. 添加注释
-- ============================================================================
COMMENT ON TABLE bids IS 'Bid竞价记录表';
COMMENT ON COLUMN bids.record_id IS 'check-in记录ID';
COMMENT ON COLUMN bids.record_type IS '记录类型: building 或 oval_office';
COMMENT ON COLUMN bids.bidder_username IS '出价者用户名';
COMMENT ON COLUMN bids.owner_username IS '记录拥有者用户名';
COMMENT ON COLUMN bids.bid_amount IS '出价金额（credits）';
COMMENT ON COLUMN bids.counter_amount IS '卖家反价金额';
COMMENT ON COLUMN bids.status IS '状态: pending/countered/accepted/completed/rejected/expired';

-- ============================================================================
-- 测试查询
-- ============================================================================
-- 查看所有Bid
-- SELECT * FROM bids ORDER BY created_at DESC;

-- 测试获取未读数量
-- SELECT get_unread_bid_count('your_username');

-- 测试获取收到的Bid
-- SELECT * FROM get_my_received_bids('your_username');

-- ============================================================================
-- 完成！
-- ============================================================================

