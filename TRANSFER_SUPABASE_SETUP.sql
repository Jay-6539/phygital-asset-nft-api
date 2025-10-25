-- ============================================
-- Treasure Hunt 转让功能 - Supabase 数据库设置
-- ============================================
-- 请在Supabase SQL Editor中执行此脚本

-- 1. 创建transfer_requests表
CREATE TABLE IF NOT EXISTS transfer_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transfer_code UUID UNIQUE NOT NULL DEFAULT uuid_generate_v4(),
    record_id TEXT NOT NULL,
    record_type TEXT NOT NULL CHECK (record_type IN ('building', 'oval_office')),
    nfc_uuid TEXT NOT NULL,
    building_id TEXT,
    building_name TEXT NOT NULL,
    asset_name TEXT NOT NULL,
    description TEXT DEFAULT '',
    image_url TEXT,
    from_user TEXT NOT NULL,
    to_user TEXT,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'expired', 'cancelled')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT (NOW() + INTERVAL '5 minutes'),
    completed_at TIMESTAMP WITH TIME ZONE
);

-- 2. 创建索引以提高查询性能
CREATE INDEX IF NOT EXISTS idx_transfer_code ON transfer_requests(transfer_code);
CREATE INDEX IF NOT EXISTS idx_from_user_status ON transfer_requests(from_user, status);
CREATE INDEX IF NOT EXISTS idx_status_expires ON transfer_requests(status, expires_at);

-- 3. 启用RLS (Row Level Security)
ALTER TABLE transfer_requests ENABLE ROW LEVEL SECURITY;

-- 4. 创建RLS策略
-- 所有用户可以读取转让请求
CREATE POLICY "Anyone can read transfer requests"
    ON transfer_requests FOR SELECT
    USING (true);

-- 用户可以创建自己的转让请求
CREATE POLICY "Users can create their own transfers"
    ON transfer_requests FOR INSERT
    WITH CHECK (auth.uid()::text = from_user OR true);  -- 暂时允许所有人创建

-- 用户可以更新自己的转让请求
CREATE POLICY "Users can update their own transfers"
    ON transfer_requests FOR UPDATE
    USING (auth.uid()::text = from_user OR auth.uid()::text = to_user OR true);

-- 5. 创建完成转让的函数（原子性操作）
CREATE OR REPLACE FUNCTION complete_transfer(
    p_transfer_code UUID,
    p_nfc_uuid TEXT,
    p_to_user TEXT
) RETURNS JSON AS $$
DECLARE
    v_transfer_record RECORD;
    v_check_in RECORD;
    v_new_record_id TEXT;
BEGIN
    -- 1. 锁定转让请求（防止并发）
    SELECT * INTO v_transfer_record
    FROM transfer_requests
    WHERE transfer_code = p_transfer_code
    FOR UPDATE;
    
    -- 2. 验证转让请求存在
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Transfer not found'
        );
    END IF;
    
    -- 3. 验证转让状态
    IF v_transfer_record.status != 'pending' THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Transfer already ' || v_transfer_record.status
        );
    END IF;
    
    -- 4. 验证是否过期
    IF v_transfer_record.expires_at < NOW() THEN
        UPDATE transfer_requests
        SET status = 'expired'
        WHERE id = v_transfer_record.id;
        
        RETURN json_build_object(
            'success', false,
            'error', 'Transfer expired'
        );
    END IF;
    
    -- 5. 验证NFC UUID
    IF v_transfer_record.nfc_uuid != p_nfc_uuid THEN
        RETURN json_build_object(
            'success', false,
            'error', 'NFC UUID mismatch'
        );
    END IF;
    
    -- 6. 执行转让（根据记录类型）
    BEGIN
        IF v_transfer_record.record_type = 'building' THEN
            -- Building记录转让
            
            -- 6.1 获取原记录
            SELECT * INTO v_check_in
            FROM asset_checkins
            WHERE id = v_transfer_record.record_id
            AND username = v_transfer_record.from_user;
            
            IF NOT FOUND THEN
                RETURN json_build_object(
                    'success', false,
                    'error', 'Original check-in not found'
                );
            END IF;
            
            -- 6.2 删除原用户的记录
            DELETE FROM asset_checkins
            WHERE id = v_transfer_record.record_id
            AND username = v_transfer_record.from_user;
            
            -- 6.3 创建新用户的记录
            v_new_record_id := uuid_generate_v4()::text;
            INSERT INTO asset_checkins (
                id, username, building_id, nfc_uuid, asset_name, description,
                image_url, gps_latitude, gps_longitude, created_at
            ) VALUES (
                v_new_record_id,
                p_to_user,
                v_check_in.building_id,
                v_check_in.nfc_uuid,
                v_check_in.asset_name,
                v_check_in.description,
                v_check_in.image_url,
                v_check_in.gps_latitude,
                v_check_in.gps_longitude,
                NOW()  -- 使用新的创建时间
            );
            
        ELSIF v_transfer_record.record_type = 'oval_office' THEN
            -- Oval Office记录转让
            
            -- 6.1 获取原记录
            SELECT * INTO v_check_in
            FROM oval_office_checkins
            WHERE id = v_transfer_record.record_id
            AND username = v_transfer_record.from_user;
            
            IF NOT FOUND THEN
                RETURN json_build_object(
                    'success', false,
                    'error', 'Original check-in not found'
                );
            END IF;
            
            -- 6.2 删除原用户的记录
            DELETE FROM oval_office_checkins
            WHERE id = v_transfer_record.record_id
            AND username = v_transfer_record.from_user;
            
            -- 6.3 创建新用户的记录
            v_new_record_id := uuid_generate_v4()::text;
            INSERT INTO oval_office_checkins (
                id, username, nfc_uuid, asset_name, description,
                image_url, grid_x, grid_y, created_at
            ) VALUES (
                v_new_record_id,
                p_to_user,
                v_check_in.nfc_uuid,
                v_check_in.asset_name,
                v_check_in.description,
                v_check_in.image_url,
                v_check_in.grid_x,
                v_check_in.grid_y,
                NOW()  -- 使用新的创建时间
            );
        END IF;
        
        -- 7. 标记转让完成
        UPDATE transfer_requests
        SET status = 'completed',
            to_user = p_to_user,
            completed_at = NOW()
        WHERE id = v_transfer_record.id;
        
        -- 8. 返回成功
        RETURN json_build_object(
            'success', true,
            'error', NULL
        );
        
    EXCEPTION WHEN OTHERS THEN
        -- 发生错误时回滚
        RAISE WARNING 'Transfer failed: %', SQLERRM;
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM
        );
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. 创建自动过期转让请求的函数
CREATE OR REPLACE FUNCTION expire_old_transfers()
RETURNS void AS $$
BEGIN
    UPDATE transfer_requests
    SET status = 'expired'
    WHERE status = 'pending'
    AND expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- 7. 创建定时任务（每分钟检查一次过期的转让）
-- 注意：Supabase需要pg_cron扩展，请确保已启用
-- SELECT cron.schedule('expire-transfers', '* * * * *', 'SELECT expire_old_transfers()');

-- ============================================
-- 说明
-- ============================================
-- 1. transfer_requests表存储所有转让请求
-- 2. transfer_code是唯一的转让码，用于QR码
-- 3. 转让有5分钟有效期，过期自动标记为expired
-- 4. complete_transfer函数确保转让的原子性
-- 5. 转让完成后，原记录删除，新记录创建给接收者
-- 6. 支持Building和Oval Office两种记录类型

-- ============================================
-- 测试查询
-- ============================================
-- 查看所有转让请求
-- SELECT * FROM transfer_requests ORDER BY created_at DESC;

-- 查看特定用户的转让
-- SELECT * FROM transfer_requests WHERE from_user = 'your_username';

-- 查看待处理的转让
-- SELECT * FROM transfer_requests WHERE status = 'pending' AND expires_at > NOW();

