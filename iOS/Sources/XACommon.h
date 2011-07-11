
void nick_command_parse (struct session *sess, const char *cmd, const char *nick, const char *allnick);
void change_channel_flag (struct session *sess, char flag, int enabled);
void set_l_flag (struct session *sess, int enabled, int value);
void set_k_flag (struct session *sess, int enabled, char *value);

NSString * formatNumber (int n);
