
/* Fake gettext */
char *gettext(char *cstring);
char *dgettext(char *domain, char *cstring);
char *dcgettext(char *domain, char *cstring, char *category);
char *dngettext(char *domain, char *cstring, char *plural, long n);

void bindtextdomain(const char *, const char *);
void bind_textdomain_codeset(const char *, const char *);
const char *textdomain(const char *);
//void 
