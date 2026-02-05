-- Calendar Stamps テーブル
-- カレンダーに表示するスタンプ（絵文字）を保存するテーブル

CREATE TABLE IF NOT EXISTS calendar_stamps (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  stamp_date DATE NOT NULL,
  emoji TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- インデックスの作成
CREATE INDEX IF NOT EXISTS idx_calendar_stamps_user_date
  ON calendar_stamps(user_id, stamp_date);

-- Row Level Security (RLS) を有効化
ALTER TABLE calendar_stamps ENABLE ROW LEVEL SECURITY;

-- ユーザーが自分のスタンプのみを操作できるポリシー
CREATE POLICY "Users can view their own stamps"
  ON calendar_stamps FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own stamps"
  ON calendar_stamps FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own stamps"
  ON calendar_stamps FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own stamps"
  ON calendar_stamps FOR DELETE
  USING (auth.uid() = user_id);

-- updated_at を自動更新するトリガー
CREATE OR REPLACE FUNCTION update_calendar_stamps_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER calendar_stamps_updated_at
  BEFORE UPDATE ON calendar_stamps
  FOR EACH ROW
  EXECUTE FUNCTION update_calendar_stamps_updated_at();
