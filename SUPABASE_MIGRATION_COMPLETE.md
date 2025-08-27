[
  {
    "table_name": "admin_actions",
    "column_name": "id",
    "data_type": "uuid"
  },
  {
    "table_name": "admin_actions",
    "column_name": "admin_id",
    "data_type": "uuid"
  },
  {
    "table_name": "admin_actions",
    "column_name": "admin_email",
    "data_type": "text"
  },
  {
    "table_name": "admin_actions",
    "column_name": "action",
    "data_type": "text"
  },
  {
    "table_name": "admin_actions",
    "column_name": "target_type",
    "data_type": "text"
  },
  {
    "table_name": "admin_actions",
    "column_name": "target_id",
    "data_type": "text"
  },
  {
    "table_name": "admin_actions",
    "column_name": "details",
    "data_type": "jsonb"
  },
  {
    "table_name": "admin_actions",
    "column_name": "created_at",
    "data_type": "timestamp with time zone"
  },
  {
    "table_name": "chat_messages",
    "column_name": "id",
    "data_type": "uuid"
  },
  {
    "table_name": "chat_messages",
    "column_name": "chat_id",
    "data_type": "uuid"
  },
  {
    "table_name": "chat_messages",
    "column_name": "sender_id",
    "data_type": "uuid"
  },
  {
    "table_name": "chat_messages",
    "column_name": "content",
    "data_type": "text"
  },
  {
    "table_name": "chat_messages",
    "column_name": "type",
    "data_type": "text"
  },
  {
    "table_name": "chat_messages",
    "column_name": "metadata",
    "data_type": "jsonb"
  },
  {
    "table_name": "chat_messages",
    "column_name": "is_read",
    "data_type": "boolean"
  },
  {
    "table_name": "chat_messages",
    "column_name": "created_at",
    "data_type": "timestamp with time zone"
  },
  {
    "table_name": "chat_participants",
    "column_name": "chat_id",
    "data_type": "uuid"
  },
  {
    "table_name": "chat_participants",
    "column_name": "user_id",
    "data_type": "uuid"
  },
  {
    "table_name": "chat_participants",
    "column_name": "unread_count",
    "data_type": "integer"
  },
  {
    "table_name": "chat_participants",
    "column_name": "is_active",
    "data_type": "boolean"
  },
  {
    "table_name": "chats",
    "column_name": "id",
    "data_type": "uuid"
  },
  {
    "table_name": "chats",
    "column_name": "buyer_id",
    "data_type": "uuid"
  },
  {
    "table_name": "chats",
    "column_name": "seller_id",
    "data_type": "uuid"
  },
  {
    "table_name": "chats",
    "column_name": "listing_id",
    "data_type": "uuid"
  },
  {
    "table_name": "chats",
    "column_name": "last_message",
    "data_type": "text"
  },
  {
    "table_name": "chats",
    "column_name": "last_message_at",
    "data_type": "timestamp with time zone"
  },
  {
    "table_name": "chats",
    "column_name": "is_buyer_read",
    "data_type": "boolean"
  },
  {
    "table_name": "chats",
    "column_name": "is_seller_read",
    "data_type": "boolean"
  },
  {
    "table_name": "chats",
    "column_name": "created_at",
    "data_type": "timestamp with time zone"
  },
  {
    "table_name": "chats",
    "column_name": "updated_at",
    "data_type": "timestamp with time zone"
  },
  {
    "table_name": "chats",
    "column_name": "last_message_time",
    "data_type": "timestamp with time zone"
  },
  {
    "table_name": "chats",
    "column_name": "last_message_sender_id",
    "data_type": "text"
  },
  {
    "table_name": "chats",
    "column_name": "listing_title",
    "data_type": "text"
  },
  {
    "table_name": "chats",
    "column_name": "unread_count",
    "data_type": "jsonb"
  },
  {
    "table_name": "comment_likes",
    "column_name": "id",
    "data_type": "uuid"
  },
  {
    "table_name": "comment_likes",
    "column_name": "comment_id",
    "data_type": "uuid"
  },
  {
    "table_name": "comment_likes",
    "column_name": "user_id",
    "data_type": "uuid"
  },
  {
    "table_name": "comment_likes",
    "column_name": "created_at",
    "data_type": "timestamp with time zone"
  },
  {
    "table_name": "comments",
    "column_name": "id",
    "data_type": "uuid"
  },
  {
    "table_name": "comments",
    "column_name": "listing_id",
    "data_type": "uuid"
  },
  {
    "table_name": "comments",
    "column_name": "user_id",
    "data_type": "uuid"
  },
  {
    "table_name": "comments",
    "column_name": "content",
    "data_type": "text"
  },
  {
    "table_name": "comments",
    "column_name": "created_at",
    "data_type": "timestamp with time zone"
  },
  {
    "table_name": "comments",
    "column_name": "updated_at",
    "data_type": "timestamp with time zone"
  },
  {
    "table_name": "comments",
    "column_name": "like_count",
    "data_type": "integer"
  },
  {
    "table_name": "comments",
    "column_name": "parent_id",
    "data_type": "uuid"
  },
  {
    "table_name": "comments",
    "column_name": "user_name",
    "data_type": "text"
  },
  {
    "table_name": "comments",
    "column_name": "user_photo_url",
    "data_type": "text"
  },
  {
    "table_name": "favorites",
    "column_name": "id",
    "data_type": "uuid"
  },
  {
    "table_name": "favorites",
    "column_name": "user_id",
    "data_type": "uuid"
  },
  {
    "table_name": "favorites",
    "column_name": "listing_id",
    "data_type": "uuid"
  },
  {
    "table_name": "favorites",
    "column_name": "created_at",
    "data_type": "timestamp with time zone"
  },
  {
    "table_name": "feature_credit_account_view",
    "column_name": "user_id",
    "data_type": "uuid"
  },
  {
    "table_name": "feature_credit_account_view",
    "column_name": "credits_available",
    "data_type": "integer"
  },
  {
    "table_name": "feature_credit_account_view",
    "column_name": "updated_at",
    "data_type": "timestamp with time zone"
  },
  {
    "table_name": "feature_credit_accounts",
    "column_name": "user_id",
    "data_type": "uuid"
  },
  {
    "table_name": "feature_credit_accounts",
    "column_name": "credits_available",
    "data_type": "integer"
  },
  {
    "table_name": "feature_credit_accounts",
    "column_name": "updated_at",
    "data_type": "timestamp with time zone"
  },
  {
    "table_name": "feature_credit_grants",
    "column_name": "id",
    "data_type": "uuid"
  },
  {
    "table_name": "feature_credit_grants",
    "column_name": "user_id",
    "data_type": "uuid"
  },
  {
    "table_name": "feature_credit_grants",
    "column_name": "credits_added",
    "data_type": "integer"
  },
  {
    "table_name": "feature_credit_grants",
    "column_name": "reason",
    "data_type": "text"
  },
  {
    "table_name": "feature_credit_grants",
    "column_name": "granted_by_admin_id",
    "data_type": "uuid"
  },
  {
    "table_name": "feature_credit_grants",
    "column_name": "expires_at",
    "data_type": "timestamp with time zone"
  },
  {
    "table_name": "feature_credit_grants",
    "column_name": "created_at",
    "data_type": "timestamp with time zone"
  },
  {
    "table_name": "feature_featured_ledger",
    "column_name": "id",
    "data_type": "uuid"
  },
  {
    "table_name": "feature_featured_ledger",
    "column_name": "user_id",
    "data_type": "uuid"
  },
  {
    "table_name": "feature_featured_ledger",
    "column_name": "listing_id",
    "data_type": "uuid"
  },
  {
    "table_name": "feature_featured_ledger",
    "column_name": "hours_purchased",
    "data_type": "integer"
  },
  {
    "table_name": "feature_featured_ledger",
    "column_name": "start_at",
    "data_type": "timestamp with time zone"
  },
  {
    "table_name": "feature_featured_ledger",
    "column_name": "end_at",
    "data_type": "timestamp with time zone"
  },
  {
    "table_name": "feature_featured_ledger",
    "column_name": "status",
    "data_type": "USER-DEFINED"
  },
  {
    "table_name": "feature_featured_ledger",
    "column_name": "created_at",
    "data_type": "timestamp with time zone"
  },
  {
    "table_name": "geography_columns",
    "column_name": "f_table_catalog",
    "data_type": "name"
  },
  {
    "table_name": "geography_columns",
    "column_name": "f_table_schema",
    "data_type": "name"
  },
  {
    "table_name": "geography_columns",
    "column_name": "f_table_name",
    "data_type": "name"
  },
  {
    "table_name": "geography_columns",
    "column_name": "f_geography_column",
    "data_type": "name"
  },
  {
    "table_name": "geography_columns",
    "column_name": "coord_dimension",
    "data_type": "integer"
  },
  {
    "table_name": "geography_columns",
    "column_name": "srid",
    "data_type": "integer"
  },
  {
    "table_name": "geography_columns",
    "column_name": "type",
    "data_type": "text"
  },
  {
    "table_name": "geometry_columns",
    "column_name": "f_table_catalog",
    "data_type": "character varying"
  },
  {
    "table_name": "geometry_columns",
    "column_name": "f_table_schema",
    "data_type": "name"
  },
  {
    "table_name": "geometry_columns",
    "column_name": "f_table_name",
    "data_type": "name"
  },
  {
    "table_name": "geometry_columns",
    "column_name": "f_geometry_column",
    "data_type": "name"
  },
  {
    "table_name": "geometry_columns",
    "column_name": "coord_dimension",
    "data_type": "integer"
  },
  {
    "table_name": "geometry_columns",
    "column_name": "srid",
    "data_type": "integer"
  },
  {
    "table_name": "geometry_columns",
    "column_name": "type",
    "data_type": "character varying"
  },
  {
    "table_name": "listings",
    "column_name": "id",
    "data_type": "uuid"
  },
  {
    "table_name": "listings",
    "column_name": "seller_id",
    "data_type": "uuid"
  },
  {
    "table_name": "listings",
    "column_name": "title",
    "data_type": "text"
  },
  {
    "table_name": "listings",
    "column_name": "description",
    "data_type": "text"
  },
  {
    "table_name": "listings",
    "column_name": "price",
    "data_type": "numeric"
  },
  {
    "table_name": "listings",
    "column_name": "category",
    "data_type": "text"
  },
  {
    "table_name": "listings",
    "column_name": "subcategory",
    "data_type": "text"
  },
  {
    "table_name": "listings",
    "column_name": "condition",
    "data_type": "text"
  },
  {
    "table_name": "listings",
    "column_name": "brand",
    "data_type": "text"
  },
  {
    "table_name": "listings",
    "column_name": "size",
    "data_type": "text"
  },
  {
    "table_name": "listings",
    "column_name": "color",
    "data_type": "text"
  },
  {
    "table_name": "listings",
    "column_name": "images",
    "data_type": "jsonb"
  },
  {
    "table_name": "listings",
    "column_name": "location",
    "data_type": "text"
  },
  {
    "table_name": "listings",
    "column_name": "latitude",
    "data_type": "numeric"
  },
  {
    "table_name": "listings",
    "column_name": "longitude",
    "data_type": "numeric"
  },
  {
    "table_name": "listings",
    "column_name": "status",
    "data_type": "text"
  },
  {
    "table_name": "listings",
    "column_name": "is_featured",
    "data_type": "boolean"
  },
  {
    "table_name": "listings",
    "column_name": "is_promoted",
    "data_type": "boolean"
  },
  {
    "table_name": "listings",
    "column_name": "view_count",
    "data_type": "integer"
  },
  {
    "table_name": "listings",
    "column_name": "created_at",
    "data_type": "timestamp with time zone"
  },
  {
    "table_name": "listings",
    "column_name": "updated_at",
    "data_type": "timestamp with time zone"
  },
  {
    "table_name": "listings",
    "column_name": "address",
    "data_type": "text"
  },
  {
    "table_name": "listings",
    "column_name": "currency",
    "data_type": "text"
  },
  {
    "table_name": "listings",
    "column_name": "videos",
    "data_type": "jsonb"
  },
  {
    "table_name": "listings",
    "column_name": "display_id",
    "data_type": "text"
  },
  {
    "table_name": "listings",
    "column_name": "user_id",
    "data_type": "uuid"
  },
  {
    "table_name": "listings",
    "column_name": "seller_email",
    "data_type": "text"
  },
  {
    "table_name": "listings",
    "column_name": "seller_name",
    "data_type": "text"
  },
  {
    "table_name": "listings",
    "column_name": "is_active",
    "data_type": "boolean"
  },
  {
    "table_name": "listings",
    "column_name": "is_negotiable",
    "data_type": "boolean"
  },
  {
    "table_name": "listings",
    "column_name": "views",
    "data_type": "integer"
  },
  {
    "table_name": "listings",
    "column_name": "expires_at",
    "data_type": "timestamp with time zone"
  },
  {
    "table_name": "listings",
    "column_name": "search_vector",
    "data_type": "tsvector"
  },
  {
    "table_name": "listings",
    "column_name": "is_draft",
    "data_type": "boolean"
  },
  {
    "table_name": "listings",
    "column_name": "location_point",
    "data_type": "USER-DEFINED"
  },
  {
    "table_name": "messages",
    "column_name": "id",
    "data_type": "uuid"
  },
  {
    "table_name": "messages",
    "column_name": "chat_id",
    "data_type": "uuid"
  },
  {
    "table_name": "messages",
    "column_name": "sender_id",
    "data_type": "uuid"
  },
  {
    "table_name": "messages",
    "column_name": "content",
    "data_type": "text"
  },
  {
    "table_name": "messages",
    "column_name": "type",
    "data_type": "text"
  },
  {
    "table_name": "messages",
    "column_name": "metadata",
    "data_type": "jsonb"
  },
  {
    "table_name": "messages",
    "column_name": "is_read",
    "data_type": "boolean"
  },
  {
    "table_name": "messages",
    "column_name": "created_at",
    "data_type": "timestamp with time zone"
  },
  {
    "table_name": "notifications",
    "column_name": "id",
    "data_type": "uuid"
  },
  {
    "table_name": "notifications",
    "column_name": "user_id",
    "data_type": "uuid"
  },
  {
    "table_name": "notifications",
    "column_name": "type",
    "data_type": "character varying"
  },
  {
    "table_name": "notifications",
    "column_name": "title",
    "data_type": "character varying"
  },
  {
    "table_name": "notifications",
    "column_name": "message",
    "data_type": "text"
  },
  {
    "table_name": "notifications",
    "column_name": "related_id",
    "data_type": "uuid"
  },
  {
    "table_name": "notifications",
    "column_name": "related_type",
    "data_type": "character varying"
  },
  {
    "table_name": "notifications",
    "column_name": "is_read",
    "data_type": "boolean"
  },
  {
    "table_name": "notifications",
    "column_name": "created_at",
    "data_type": "timestamp with time zone"
  },
  {
    "table_name": "notifications",
    "column_name": "expires_at",
    "data_type": "timestamp with time zone"
  },
  {
    "table_name": "notifications",
    "column_name": "metadata",
    "data_type": "jsonb"
  },
  {
    "table_name": "promotion_requests",
    "column_name": "id",
    "data_type": "uuid"
  },
  {
    "table_name": "promotion_requests",
    "column_name": "user_id",
    "data_type": "uuid"
  },
  {
    "table_name": "promotion_requests",
    "column_name": "listing_id",
    "data_type": "uuid"
  },
  {
    "table_name": "promotion_requests",
    "column_name": "promotion_type",
    "data_type": "text"
  },
  {
    "table_name": "promotion_requests",
    "column_name": "duration_days",
    "data_type": "integer"
  },
  {
    "table_name": "promotion_requests",
    "column_name": "price",
    "data_type": "numeric"
  },
  {
    "table_name": "promotion_requests",
    "column_name": "status",
    "data_type": "text"
  },
  {
    "table_name": "promotion_requests",
    "column_name": "start_date",
    "data_type": "timestamp with time zone"
  },
  {
    "table_name": "promotion_requests",
    "column_name": "end_date",
    "data_type": "timestamp with time zone"
  },
  {
    "table_name": "promotion_requests",
    "column_name": "payment_status",
    "data_type": "text"
  },
  {
    "table_name": "promotion_requests",
    "column_name": "created_at",
    "data_type": "timestamp with time zone"
  },
  {
    "table_name": "promotion_requests",
    "column_name": "updated_at",
    "data_type": "timestamp with time zone"
  },
  {
    "table_name": "promotion_requests",
    "column_name": "rejection_reason",
    "data_type": "text"
  },
  {
    "table_name": "promotion_requests",
    "column_name": "approved_by",
    "data_type": "uuid"
  },
  {
    "table_name": "promotion_requests",
    "column_name": "approved_at",
    "data_type": "timestamp with time zone"
  },
  {
    "table_name": "promotion_requests",
    "column_name": "canceled_at",
    "data_type": "timestamp with time zone"
  },
  {
    "table_name": "promotion_requests",
    "column_name": "payment_message",
    "data_type": "text"
  },
  {
    "table_name": "ratings",
    "column_name": "id",
    "data_type": "uuid"
  },
  {
    "table_name": "ratings",
    "column_name": "rater_id",
    "data_type": "uuid"
  },
  {
    "table_name": "ratings",
    "column_name": "rated_user_id",
    "data_type": "uuid"
  },
  {
    "table_name": "ratings",
    "column_name": "listing_id",
    "data_type": "uuid"
  },
  {
    "table_name": "ratings",
    "column_name": "rating",
    "data_type": "integer"
  },
  {
    "table_name": "ratings",
    "column_name": "comment",
    "data_type": "text"
  },
  {
    "table_name": "ratings",
    "column_name": "created_at",
    "data_type": "timestamp with time zone"
  },
  {
    "table_name": "safety_reports",
    "column_name": "id",
    "data_type": "uuid"
  },
  {
    "table_name": "safety_reports",
    "column_name": "reporter_id",
    "data_type": "uuid"
  },
  {
    "table_name": "safety_reports",
    "column_name": "reported_user_id",
    "data_type": "uuid"
  },
  {
    "table_name": "safety_reports",
    "column_name": "reported_listing_id",
    "data_type": "uuid"
  },
  {
    "table_name": "safety_reports",
    "column_name": "reason",
    "data_type": "text"
  },
  {
    "table_name": "safety_reports",
    "column_name": "description",
    "data_type": "text"
  },
  {
    "table_name": "safety_reports",
    "column_name": "status",
    "data_type": "text"
  },
  {
    "table_name": "safety_reports",
    "column_name": "created_at",
    "data_type": "timestamp with time zone"
  },
  {
    "table_name": "safety_reports",
    "column_name": "updated_at",
    "data_type": "timestamp with time zone"
  },
  {
    "table_name": "safety_reports",
    "column_name": "resolved_by",
    "data_type": "uuid"
  },
  {
    "table_name": "safety_reports",
    "column_name": "resolved_at",
    "data_type": "timestamp with time zone"
  },
  {
    "table_name": "saved_searches",
    "column_name": "id",
    "data_type": "uuid"
  },
  {
    "table_name": "saved_searches",
    "column_name": "user_id",
    "data_type": "uuid"
  },
  {
    "table_name": "saved_searches",
    "column_name": "query",
    "data_type": "text"
  },
  {
    "table_name": "saved_searches",
    "column_name": "category",
    "data_type": "text"
  },
  {
    "table_name": "saved_searches",
    "column_name": "subcategory",
    "data_type": "text"
  },
  {
    "table_name": "saved_searches",
    "column_name": "min_price",
    "data_type": "numeric"
  },
  {
    "table_name": "saved_searches",
    "column_name": "max_price",
    "data_type": "numeric"
  },
  {
    "table_name": "saved_searches",
    "column_name": "location",
    "data_type": "text"
  },
  {
    "table_name": "saved_searches",
    "column_name": "radius_km",
    "data_type": "numeric"
  },
  {
    "table_name": "saved_searches",
    "column_name": "sort_by",
    "data_type": "text"
  },
  {
    "table_name": "saved_searches",
    "column_name": "filters",
    "data_type": "jsonb"
  },
  {
    "table_name": "saved_searches",
    "column_name": "notifications_enabled",
    "data_type": "boolean"
  },
  {
    "table_name": "saved_searches",
    "column_name": "last_triggered_at",
    "data_type": "timestamp with time zone"
  },
  {
    "table_name": "saved_searches",
    "column_name": "created_at",
    "data_type": "timestamp with time zone"
  },
  {
    "table_name": "saved_searches",
    "column_name": "updated_at",
    "data_type": "timestamp with time zone"
  },
  {
    "table_name": "spatial_ref_sys",
    "column_name": "srid",
    "data_type": "integer"
  },
  {
    "table_name": "spatial_ref_sys",
    "column_name": "auth_name",
    "data_type": "character varying"
  },
  {
    "table_name": "spatial_ref_sys",
    "column_name": "auth_srid",
    "data_type": "integer"
  },
  {
    "table_name": "spatial_ref_sys",
    "column_name": "srtext",
    "data_type": "character varying"
  },
  {
    "table_name": "spatial_ref_sys",
    "column_name": "proj4text",
    "data_type": "character varying"
  },
  {
    "table_name": "support_messages",
    "column_name": "id",
    "data_type": "bigint"
  },
  {
    "table_name": "support_messages",
    "column_name": "support_request_id",
    "data_type": "uuid"
  },
  {
    "table_name": "support_messages",
    "column_name": "message",
    "data_type": "text"
  },
  {
    "table_name": "support_messages",
    "column_name": "sender_id",
    "data_type": "uuid"
  },
  {
    "table_name": "support_messages",
    "column_name": "sender_role",
    "data_type": "text"
  },
  {
    "table_name": "support_messages",
    "column_name": "created_at",
    "data_type": "timestamp with time zone"
  },
  {
    "table_name": "support_requests",
    "column_name": "id",
    "data_type": "uuid"
  },
  {
    "table_name": "support_requests",
    "column_name": "user_id",
    "data_type": "uuid"
  },
  {
    "table_name": "support_requests",
    "column_name": "user_email",
    "data_type": "text"
  },
  {
    "table_name": "support_requests",
    "column_name": "title",
    "data_type": "text"
  },
  {
    "table_name": "support_requests",
    "column_name": "message",
    "data_type": "text"
  },
  {
    "table_name": "support_requests",
    "column_name": "status",
    "data_type": "text"
  },
  {
    "table_name": "support_requests",
    "column_name": "priority",
    "data_type": "text"
  },
  {
    "table_name": "support_requests",
    "column_name": "category",
    "data_type": "text"
  },
  {
    "table_name": "support_requests",
    "column_name": "admin_response",
    "data_type": "text"
  },
  {
    "table_name": "support_requests",
    "column_name": "created_at",
    "data_type": "timestamp with time zone"
  },
  {
    "table_name": "support_requests",
    "column_name": "updated_at",
    "data_type": "timestamp with time zone"
  },
  {
    "table_name": "support_requests",
    "column_name": "responded_by",
    "data_type": "uuid"
  },
  {
    "table_name": "support_requests",
    "column_name": "responded_at",
    "data_type": "timestamp with time zone"
  },
  {
    "table_name": "support_requests",
    "column_name": "reason",
    "data_type": "text"
  },
  {
    "table_name": "support_requests",
    "column_name": "description",
    "data_type": "text"
  },
  {
    "table_name": "support_requests",
    "column_name": "email",
    "data_type": "text"
  },
  {
    "table_name": "support_requests",
    "column_name": "name",
    "data_type": "text"
  },
  {
    "table_name": "support_requests",
    "column_name": "details",
    "data_type": "text"
  },
  {
    "table_name": "support_requests",
    "column_name": "resolved_at",
    "data_type": "timestamp with time zone"
  },
  {
    "table_name": "support_requests",
    "column_name": "resolved_by",
    "data_type": "uuid"
  },
  {
    "table_name": "users",
    "column_name": "id",
    "data_type": "uuid"
  },
  {
    "table_name": "users",
    "column_name": "email",
    "data_type": "text"
  },
  {
    "table_name": "users",
    "column_name": "display_name",
    "data_type": "text"
  },
  {
    "table_name": "users",
    "column_name": "phone_number",
    "data_type": "text"
  },
  {
    "table_name": "users",
    "column_name": "profile_image_url",
    "data_type": "text"
  },
  {
    "table_name": "users",
    "column_name": "is_verified",
    "data_type": "boolean"
  },
  {
    "table_name": "users",
    "column_name": "is_seller",
    "data_type": "boolean"
  },
  {
    "table_name": "users",
    "column_name": "is_admin",
    "data_type": "boolean"
  },
  {
    "table_name": "users",
    "column_name": "role",
    "data_type": "text"
  },
  {
    "table_name": "users",
    "column_name": "status",
    "data_type": "text"
  },
  {
    "table_name": "users",
    "column_name": "rating",
    "data_type": "numeric"
  },
  {
    "table_name": "users",
    "column_name": "total_ratings",
    "data_type": "integer"
  },
  {
    "table_name": "users",
    "column_name": "total_listings",
    "data_type": "integer"
  },
  {
    "table_name": "users",
    "column_name": "total_sales",
    "data_type": "integer"
  },
  {
    "table_name": "users",
    "column_name": "created_at",
    "data_type": "timestamp with time zone"
  },
  {
    "table_name": "users",
    "column_name": "updated_at",
    "data_type": "timestamp with time zone"
  },
  {
    "table_name": "users",
    "column_name": "last_login_at",
    "data_type": "timestamp with time zone"
  },
  {
    "table_name": "v_feature_credit_balance",
    "column_name": "user_id",
    "data_type": "uuid"
  },
  {
    "table_name": "v_feature_credit_balance",
    "column_name": "total_credits",
    "data_type": "integer"
  },
  {
    "table_name": "v_feature_credit_balance",
    "column_name": "used_credits",
    "data_type": "bigint"
  },
  {
    "table_name": "v_feature_credit_balance",
    "column_name": "remaining_credits",
    "data_type": "bigint"
  }
]