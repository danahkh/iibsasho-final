-- Create chats table
CREATE TABLE IF NOT EXISTS chats (
    id TEXT PRIMARY KEY,
    participants TEXT[] NOT NULL,
    listing_id TEXT NOT NULL,
    listing_title TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_message TEXT DEFAULT '',
    last_message_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_message_sender_id TEXT DEFAULT '',
    is_active BOOLEAN DEFAULT true,
    unread_count JSONB DEFAULT '{}'::jsonb
);

-- Create messages table
CREATE TABLE IF NOT EXISTS messages (
    id TEXT PRIMARY KEY,
    chat_id TEXT NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
    sender_id TEXT NOT NULL,
    content TEXT NOT NULL,
    type TEXT DEFAULT 'text',
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_read BOOLEAN DEFAULT false,
    is_edited BOOLEAN DEFAULT false,
    is_deleted BOOLEAN DEFAULT false
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_chats_participants ON chats USING GIN (participants);
CREATE INDEX IF NOT EXISTS idx_chats_listing_id ON chats (listing_id);
CREATE INDEX IF NOT EXISTS idx_chats_updated_at ON chats (updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_chat_id ON messages (chat_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON messages (sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages (created_at DESC);

-- Enable Row Level Security
ALTER TABLE chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- RLS Policies for chats table
CREATE POLICY "Users can view chats they participate in" ON chats
    FOR SELECT USING (auth.uid()::text = ANY(participants));

CREATE POLICY "Users can create chats" ON chats
    FOR INSERT WITH CHECK (auth.uid()::text = ANY(participants));

CREATE POLICY "Users can update chats they participate in" ON chats
    FOR UPDATE USING (auth.uid()::text = ANY(participants));

-- RLS Policies for messages table
CREATE POLICY "Users can view messages in their chats" ON messages
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM chats 
            WHERE chats.id = messages.chat_id 
            AND auth.uid()::text = ANY(chats.participants)
        )
    );

CREATE POLICY "Users can create messages in their chats" ON messages
    FOR INSERT WITH CHECK (
        auth.uid()::text = sender_id AND
        EXISTS (
            SELECT 1 FROM chats 
            WHERE chats.id = messages.chat_id 
            AND auth.uid()::text = ANY(chats.participants)
        )
    );

CREATE POLICY "Users can update their own messages" ON messages
    FOR UPDATE USING (auth.uid()::text = sender_id);