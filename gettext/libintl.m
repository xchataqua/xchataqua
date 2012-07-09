
#import <Foundation/Foundation.h>

char *gettext(char *cstring) {
    NSString *sourceString = [NSString stringWithUTF8String:cstring];
    NSString *resultString = NSLocalizedStringFromTable(sourceString, @"xchat", @"");
    return (char *)resultString.UTF8String;
}

char *dgettext(char *domain, char *cstring) {
    NSString *sourceString = [NSString stringWithUTF8String:cstring];
    NSString *resultString = NSLocalizedStringFromTable(sourceString, [NSString stringWithUTF8String:domain], @"");
    return (char *)resultString.UTF8String;
}

char *dcgettext(char *domain, char *cstring, char *category) {
    return dgettext(domain, cstring);
}

char *dngettext(char *domain, char *cstring, char *plural, long n) {
    return dgettext(domain, cstring);
}

void bindtextdomain(const char *foo, const char *bar) { }

void bind_textdomain_codeset(const char *foo, const char *bar) { }

const char *textdomain(const char *foo) { return NULL; }
