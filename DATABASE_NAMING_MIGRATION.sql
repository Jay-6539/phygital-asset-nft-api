-- ============================================================================
-- 数据库命名规范迁移 - Supabase
-- ============================================================================
-- 本脚本更新数据库注释和文档，统一命名规范：
-- - Credit → Echo
-- - Check-in → Thread
-- - Building 保持不变
--
-- ⚠️ 注意：此脚本不会更改表名和字段名，只更新注释
-- 这样可以保持应用代码的兼容性，同时统一文档说明
-- ============================================================================

-- 1. 更新 asset_checkins 表注释（Thread记录）
-- ============================================================================
COMMENT ON TABLE asset_checkins IS 'Thread记录表 - 用户在NFC标签或建筑上留下的记录';

COMMENT ON COLUMN asset_checkins.id IS 'Thread唯一标识符 (UUID)';
COMMENT ON COLUMN asset_checkins.building_id IS 'Building ID - 关联的建筑或NFC标识';
COMMENT ON COLUMN asset_checkins.username IS 'Thread创建者的用户名';
COMMENT ON COLUMN asset_checkins.asset_name IS 'Thread的资产名称（用户自定义）';
COMMENT ON COLUMN asset_checkins.description IS 'Thread描述内容';
COMMENT ON COLUMN asset_checkins.image_url IS 'Thread图片URL';
COMMENT ON COLUMN asset_checkins.nfc_uuid IS 'NFC标签UUID - Thread关联的NFC位置';
COMMENT ON COLUMN asset_checkins.gps_latitude IS 'Thread创建时的GPS纬度';
COMMENT ON COLUMN asset_checkins.gps_longitude IS 'Thread创建时的GPS经度';
COMMENT ON COLUMN asset_checkins.created_at IS 'Thread创建时间';
COMMENT ON COLUMN asset_checkins.updated_at IS 'Thread更新时间';

-- 2. 更新 oval_office_checkins 表注释（Oval Office Thread记录）
-- ============================================================================
COMMENT ON TABLE oval_office_checkins IS 'Oval Office Thread记录表 - 特殊位置的Thread记录';

COMMENT ON COLUMN oval_office_checkins.id IS 'Thread唯一标识符 (UUID)';
COMMENT ON COLUMN oval_office_checkins.username IS 'Thread创建者的用户名';
COMMENT ON COLUMN oval_office_checkins.asset_name IS 'Thread的资产名称';
COMMENT ON COLUMN oval_office_checkins.description IS 'Thread描述内容';
COMMENT ON COLUMN oval_office_checkins.image_url IS 'Thread图片URL';
COMMENT ON COLUMN oval_office_checkins.created_at IS 'Thread创建时间';
COMMENT ON COLUMN oval_office_checkins.updated_at IS 'Thread更新时间';

-- 3. 更新 bids 表注释（Echo相关）
-- ============================================================================
COMMENT ON TABLE bids IS 'Thread竞价记录表 - 用户对Thread的出价和交易';

COMMENT ON COLUMN bids.id IS 'Bid唯一标识符';
COMMENT ON COLUMN bids.record_id IS 'Thread记录ID - 关联的asset_checkins或oval_office_checkins记录';
COMMENT ON COLUMN bids.record_type IS 'Thread类型: building 或 oval_office';
COMMENT ON COLUMN bids.building_id IS 'Building ID（如果是building类型的Thread）';
COMMENT ON COLUMN bids.bidder_username IS '出价者用户名（买家）';
COMMENT ON COLUMN bids.owner_username IS 'Thread拥有者用户名（卖家）';
COMMENT ON COLUMN bids.bid_amount IS '出价金额 - Echo数量';
COMMENT ON COLUMN bids.counter_amount IS '卖家反价金额 - Echo数量';
COMMENT ON COLUMN bids.bidder_contact IS '买家联系方式（交易接受后填写）';
COMMENT ON COLUMN bids.owner_contact IS '卖家联系方式（交易接受后填写）';
COMMENT ON COLUMN bids.status IS 'Bid状态: pending/countered/accepted/completed/rejected/cancelled/expired';
COMMENT ON COLUMN bids.created_at IS 'Bid创建时间';
COMMENT ON COLUMN bids.updated_at IS 'Bid更新时间';
COMMENT ON COLUMN bids.expires_at IS 'Bid过期时间（默认7天）';
COMMENT ON COLUMN bids.completed_at IS 'Bid完成时间（交易完成时）';
COMMENT ON COLUMN bids.bidder_message IS '买家留言';
COMMENT ON COLUMN bids.owner_message IS '卖家回复留言';

-- 4. 更新 transfer_requests 表注释（Thread转让）
-- ============================================================================
COMMENT ON TABLE transfer_requests IS 'Thread转让请求表 - 用户之间的Thread转移记录';

COMMENT ON COLUMN transfer_requests.id IS '转让请求唯一标识符';
COMMENT ON COLUMN transfer_requests.transfer_code IS '转让代码 - 用于接收方扫码领取';
COMMENT ON COLUMN transfer_requests.record_id IS 'Thread记录ID';
COMMENT ON COLUMN transfer_requests.record_type IS 'Thread类型: building 或 oval_office';
COMMENT ON COLUMN transfer_requests.nfc_uuid IS 'NFC标签UUID - Thread关联的位置';
COMMENT ON COLUMN transfer_requests.building_id IS 'Building ID（如果是building类型）';
COMMENT ON COLUMN transfer_requests.building_name IS 'Building名称';
COMMENT ON COLUMN transfer_requests.asset_name IS 'Thread资产名称';
COMMENT ON COLUMN transfer_requests.description IS 'Thread描述';
COMMENT ON COLUMN transfer_requests.image_url IS 'Thread图片URL';
COMMENT ON COLUMN transfer_requests.from_user IS '转让发起者用户名';
COMMENT ON COLUMN transfer_requests.to_user IS '接收者用户名（完成后填写）';
COMMENT ON COLUMN transfer_requests.status IS '转让状态: pending/completed/expired/cancelled';
COMMENT ON COLUMN transfer_requests.created_at IS '转让请求创建时间';
COMMENT ON COLUMN transfer_requests.expires_at IS '转让请求过期时间（默认5分钟）';
COMMENT ON COLUMN transfer_requests.completed_at IS '转让完成时间';

-- 5. 更新 user_xp 表注释（已经是正确的）
-- ============================================================================
COMMENT ON TABLE user_xp IS '用户XP和等级表 - 跟踪用户活跃度';

COMMENT ON COLUMN user_xp.username IS '用户名';
COMMENT ON COLUMN user_xp.xp IS '经验值 (Experience Points)';
COMMENT ON COLUMN user_xp.level IS '等级 - 自动计算: Level = (XP / 1000) + 1';
COMMENT ON COLUMN user_xp.created_at IS '记录创建时间';
COMMENT ON COLUMN user_xp.updated_at IS '记录更新时间';

-- ============================================================================
-- 表名映射说明
-- ============================================================================
-- 以下表名保持不变，以确保应用兼容性：
--
-- asset_checkins        → 存储Building的Thread记录
-- oval_office_checkins  → 存储Oval Office的Thread记录
-- bids                  → 存储Thread的竞价记录（使用Echo交易）
-- transfer_requests     → 存储Thread的转让请求
-- user_xp               → 存储用户的XP和等级
--
-- ============================================================================

-- ============================================================================
-- 命名规范总结
-- ============================================================================
-- 
-- 概念映射：
-- - Building: 地图上标注的建筑点
-- - Thread: 用户在NFC/建筑上留下的记录（存储在 asset_checkins 表）
-- - Echo: 用户的代币（用于bid_amount, counter_amount字段）
-- - XP: 用户的经验值（存储在 user_xp 表）
--
-- 数据库层面：
-- - 表名保持原样（asset_checkins, oval_office_checkins等）
-- - 字段名保持原样（username, asset_name, bid_amount等）
-- - 仅更新注释说明，统一术语
--
-- 应用层面：
-- - UI显示使用新术语（Thread, Echo, XP）
-- - 代码注释使用新术语
-- - 数据库查询保持不变
--
-- ============================================================================

-- 完成！所有注释已更新为新的命名规范。
-- 现有应用代码无需修改，可以继续正常工作。

