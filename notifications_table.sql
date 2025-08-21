-- Create notifications table for user notifications
CREATE TABLE notifications (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL CHECK (type IN ('comment', 'message', 'favorite')),
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    related_id UUID, -- Could be listing_id, chat_id, comment_id, etc.
    related_type VARCHAR(50), -- 'listing', 'chat', 'comment', etc.
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE,
    
    -- Additional metadata as JSON
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Create indexes for better performance
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_type ON notifications(type);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at DESC);
CREATE INDEX idx_notifications_user_unread ON notifications(user_id, is_read) WHERE is_read = FALSE;

-- Enable Row Level Security (RLS)
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- RLS Policies for notifications table

-- Policy: Users can only view their own notifications
CREATE POLICY "Users can view their own notifications" ON notifications
    FOR SELECT USING (auth.uid() = user_id);

-- Policy: System can insert notifications for any user (for system-generated notifications)
CREATE POLICY "System can insert notifications" ON notifications
    FOR INSERT WITH CHECK (true);

-- Policy: Users can update their own notifications (mark as read, etc.)
CREATE POLICY "Users can update their own notifications" ON notifications
    FOR UPDATE USING (auth.uid() = user_id);

-- Policy: Users can delete their own notifications
CREATE POLICY "Users can delete their own notifications" ON notifications
    FOR DELETE USING (auth.uid() = user_id);

-- Grant necessary permissions
GRANT ALL ON notifications TO authenticated;
GRANT ALL ON notifications TO anon;

-- Create function to automatically delete expired notifications
CREATE OR REPLACE FUNCTION delete_expired_notifications()
RETURNS void AS $$
BEGIN
    DELETE FROM notifications 
    WHERE expires_at IS NOT NULL 
    AND expires_at < timezone('utc'::text, now());
END;
$$ LANGUAGE plpgsql;
