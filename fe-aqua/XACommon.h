@class NSString;

void nick_command_parse (session *sess, const char *cmd, const char *nick, const char *allnick);
void change_channel_flag (session *sess, char flag, int enabled);
void set_l_flag (session *sess, int enabled, int value);
void set_k_flag (session *sess, int enabled, char *value);

NSString * formatNumber (int n);
