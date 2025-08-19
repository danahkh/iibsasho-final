-- Create comments table for listing comments
CREATE TABLE comments (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    listing_id UUID NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    
    -- Add indexes for better performance
    CONSTRAINT comments_content_check CHECK (char_length(content) >= 1 AND char_length(content) <= 2000)
);

-- Create indexes for better performance
CREATE INDEX idx_comments_listing_id ON comments(listing_id);
CREATE INDEX idx_comments_user_id ON comments(user_id);
CREATE INDEX idx_comments_created_at ON comments(created_at DESC);

-- Enable Row Level Security (RLS)
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;

-- RLS Policies for comments table

-- Policy: Users can view all comments
CREATE POLICY "Anyone can view comments" ON comments
    FOR SELECT USING (true);

-- Policy: Authenticated users can insert their own comments
CREATE POLICY "Users can insert their own comments" ON comments
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own comments
CREATE POLICY "Users can update their own comments" ON comments
    FOR UPDATE USING (auth.uid() = user_id);

-- Policy: Users can delete their own comments OR listing owners can delete comments on their listings
CREATE POLICY "Users can delete their own comments or listing owners can delete comments" ON comments
    FOR DELETE USING (
        auth.uid() = user_id OR 
        auth.uid() IN (
            SELECT user_id FROM listings WHERE id = comments.listing_id
        )
    );

-- Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update updated_at on row updates
CREATE TRIGGER update_comments_updated_at 
    BEFORE UPDATE ON comments 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Grant necessary permissions
GRANT ALL ON comments TO authenticated;
GRANT ALL ON comments TO anon;
