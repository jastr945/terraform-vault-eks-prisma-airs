# Allows to read K/V secrets 
path "kv/data/chatbot" {
  capabilities = ["read", "list", "subscribe"]
  subscribe_event_types = ["*"]
}
# Allows reading K/V secret versions and metadata
path "kv/metadata/chatbot" {
  capabilities = ["list", "read"]
}

path "sys/events/subscribe/kv*" {
  capabilities = ["read"]
}