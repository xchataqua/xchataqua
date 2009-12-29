#include <Carbon/Carbon.h>
#include <sys/param.h>
#include <stdio.h>
#include <dlfcn.h>

struct xchat_plugin;

static void *_real_handle;
static char *_real_plugin;
static char *_dlerror;

static void (*_xchat_plugin_get_info)(char **, char **, char **, void **);
static int  (*_xchat_plugin_init)(struct xchat_plugin *, char **,
		char **, char **, char *);
static int  (*_xchat_plugin_deinit)(struct xchat_plugin *);

static const char *_MacOSVersion ()
{
    SInt32 MacVersion;
    if (Gestalt (gestaltSystemVersion, &MacVersion) == noErr)
    {
		if (MacVersion >= 0x1050)
			return "leopard";
		if (MacVersion >= 0x1040)
			return "tiger";
		if (MacVersion >= 0x1030)
			return "panther";
	}

    return NULL;
}

__attribute__((constructor))
static void XCA_shim_init ()
{
    Dl_info info;
    dladdr (XCA_shim_init, &info);

    char buff [MAXPATHLEN];

    strcpy (buff, info.dli_fname);
    char *dot_so = strstr (buff, ".so");
    strcpy (dot_so, "-");
    strcat (buff, _MacOSVersion ());
    strcat (buff, ".impl");

	_real_plugin = strdup (buff);
	
    _real_handle = dlopen (buff, RTLD_NOW);

    if (_real_handle)
    {
		_xchat_plugin_get_info = dlsym(_real_handle, "xchat_plugin_get_info");
		_xchat_plugin_init = dlsym(_real_handle, "xchat_plugin_init");
		_xchat_plugin_deinit = dlsym(_real_handle, "xchat_plugin_deinit");
    }
    else
    {
		_dlerror = strdup (dlerror());
    }
}

void xchat_plugin_get_info(char **name, char **desc, char **version, void **reserved)
{
    if (_xchat_plugin_get_info)
		_xchat_plugin_get_info (name, desc, version, reserved);
}

int
xchat_plugin_init (struct xchat_plugin *plugin_handle, char **plugin_name,
	char **plugin_desc, char **plugin_version, char *arg)
{
    if (!_xchat_plugin_init)
	{
		xchat_printf (plugin_handle, 
			"Error loading OS specific plugin library: %s - ", _real_plugin, _dlerror);
		return 0;
	}

	xchat_printf(plugin_handle, "OS Specific plugin loaded: %s\n", _real_plugin);
	
    return _xchat_plugin_init (plugin_handle, plugin_name, plugin_desc, plugin_version, arg);
}

int
xchat_plugin_deinit (struct xchat_plugin *plugin_handle)
{
    if (!_xchat_plugin_deinit)
		return 0;

    return _xchat_plugin_deinit (plugin_handle);
}
