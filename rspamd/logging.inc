type = "file";
filename = "/var/log/mail.log";
level = "info";

# Enable severity and microseconds for detailed logging
log_severity = true;
log_usec = true;

# Buffer settings for performance
log_buffered = true;
log_buf_size = 32768;

# Error buffer for /errors endpoint
error_elts = 100;
error_maxlen = 2000;

# Extended log tag (useful for high-volume environments)
max_tag_len = 12;
tag_strip_policy = "middle";

# Debug specific modules
# debug_modules = ["dkim", "spf", "dkim_signing"];
