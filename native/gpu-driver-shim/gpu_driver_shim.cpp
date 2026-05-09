#include <android/log.h>
#include <dlfcn.h>
#include <pthread.h>
#include <stdarg.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>
#include <vulkan/vulkan.h>

#include <adrenotools/driver.h>
#include <adrenotools/priv.h>

#define TAG "GpuDriverShim"

static const char *kPackageName = "xyz.aethersx2.android";
static const char *kDriverDir = "/data/data/xyz.aethersx2.android/files/gpu_drivers/current/";
static const char *kDriverName = "libvulkan_freedreno.so";
static const char *kEnabledMarker = "/data/data/xyz.aethersx2.android/files/gpu_drivers/current/enabled";
static const char *kTmpDir = "/data/data/xyz.aethersx2.android/cache/gpu_driver_shim";
static const char *kExternalLog = "/sdcard/Android/data/xyz.aethersx2.android/files/gpu_driver_shim.log";

static pthread_mutex_t g_lock = PTHREAD_MUTEX_INITIALIZER;
static void *g_vulkan = nullptr;
static bool g_initialized = false;
static char g_hook_dir[512] = {0};

static void log_line(const char *fmt, ...) {
    char msg[1024];
    va_list args;
    va_start(args, fmt);
    vsnprintf(msg, sizeof(msg), fmt, args);
    va_end(args);

    __android_log_print(ANDROID_LOG_INFO, TAG, "%s", msg);

    FILE *f = fopen(kExternalLog, "a");
    if (f) {
        fprintf(f, "%s\n", msg);
        fclose(f);
    }
}

static bool file_exists(const char *path) {
    return access(path, F_OK) == 0;
}

static void ensure_dir(const char *path) {
    char tmp[512];
    strncpy(tmp, path, sizeof(tmp) - 1);
    tmp[sizeof(tmp) - 1] = '\0';

    size_t len = strlen(tmp);
    if (len == 0) {
        return;
    }
    if (tmp[len - 1] == '/') {
        tmp[len - 1] = '\0';
    }

    for (char *p = tmp + 1; *p; ++p) {
        if (*p == '/') {
            *p = '\0';
            mkdir(tmp, 0700);
            *p = '/';
        }
    }
    mkdir(tmp, 0700);
}

static void resolve_hook_dir() {
    if (g_hook_dir[0] != '\0') {
        return;
    }

    Dl_info info;
    if (dladdr(reinterpret_cast<void *>(&resolve_hook_dir), &info) && info.dli_fname) {
        strncpy(g_hook_dir, info.dli_fname, sizeof(g_hook_dir) - 1);
        g_hook_dir[sizeof(g_hook_dir) - 1] = '\0';
        char *slash = strrchr(g_hook_dir, '/');
        if (slash) {
            *(slash + 1) = '\0';
            return;
        }
    }

    g_hook_dir[0] = '\0';
}

static void *load_system_vulkan() {
    void *handle = dlopen("libvulkan.so", RTLD_NOW | RTLD_GLOBAL);
    log_line("system Vulkan load %s", handle ? "succeeded" : dlerror());
    return handle;
}

static void initialize_vulkan() {
    pthread_mutex_lock(&g_lock);
    if (g_initialized) {
        pthread_mutex_unlock(&g_lock);
        return;
    }

    g_initialized = true;
    resolve_hook_dir();
    ensure_dir(kTmpDir);

    char driver_path[512];
    snprintf(driver_path, sizeof(driver_path), "%s%s", kDriverDir, kDriverName);

    if (file_exists(kEnabledMarker) && file_exists(driver_path) && g_hook_dir[0] != '\0') {
        log_line("custom driver requested: %s", driver_path);
        g_vulkan = adrenotools_open_libvulkan(
            RTLD_NOW,
            ADRENOTOOLS_DRIVER_CUSTOM,
            kTmpDir,
            g_hook_dir,
            kDriverDir,
            kDriverName,
            nullptr,
            nullptr);

        if (g_vulkan) {
            log_line("custom driver load succeeded via libadrenotools");
        } else {
            log_line("custom driver load failed, falling back to system Vulkan");
        }
    } else {
        log_line("custom driver disabled or missing for %s", kPackageName);
    }

    if (!g_vulkan) {
        g_vulkan = load_system_vulkan();
    }

    pthread_mutex_unlock(&g_lock);
}

static void *resolve_symbol(const char *name) {
    initialize_vulkan();
    if (!g_vulkan) {
        return nullptr;
    }
    return dlsym(g_vulkan, name);
}

extern "C" __attribute__((visibility("default")))
PFN_vkVoidFunction vkGetInstanceProcAddr(VkInstance instance, const char *name) {
    auto fn = reinterpret_cast<PFN_vkGetInstanceProcAddr>(resolve_symbol("vkGetInstanceProcAddr"));
    return fn ? fn(instance, name) : nullptr;
}

extern "C" __attribute__((visibility("default")))
PFN_vkVoidFunction vkGetDeviceProcAddr(VkDevice device, const char *name) {
    auto fn = reinterpret_cast<PFN_vkGetDeviceProcAddr>(resolve_symbol("vkGetDeviceProcAddr"));
    return fn ? fn(device, name) : nullptr;
}

extern "C" __attribute__((visibility("default")))
VkResult vkEnumerateInstanceVersion(uint32_t *apiVersion) {
    auto fn = reinterpret_cast<PFN_vkEnumerateInstanceVersion>(resolve_symbol("vkEnumerateInstanceVersion"));
    if (!fn) {
        if (apiVersion) {
            *apiVersion = VK_API_VERSION_1_0;
        }
        return VK_SUCCESS;
    }
    return fn(apiVersion);
}

extern "C" __attribute__((visibility("default")))
VkResult vkEnumerateInstanceExtensionProperties(const char *layerName, uint32_t *propertyCount, VkExtensionProperties *properties) {
    auto fn = reinterpret_cast<PFN_vkEnumerateInstanceExtensionProperties>(resolve_symbol("vkEnumerateInstanceExtensionProperties"));
    return fn ? fn(layerName, propertyCount, properties) : VK_ERROR_INITIALIZATION_FAILED;
}

extern "C" __attribute__((visibility("default")))
VkResult vkEnumerateInstanceLayerProperties(uint32_t *propertyCount, VkLayerProperties *properties) {
    auto fn = reinterpret_cast<PFN_vkEnumerateInstanceLayerProperties>(resolve_symbol("vkEnumerateInstanceLayerProperties"));
    return fn ? fn(propertyCount, properties) : VK_ERROR_INITIALIZATION_FAILED;
}

extern "C" __attribute__((visibility("default")))
VkResult vkCreateInstance(const VkInstanceCreateInfo *createInfo, const VkAllocationCallbacks *allocator, VkInstance *instance) {
    auto fn = reinterpret_cast<PFN_vkCreateInstance>(resolve_symbol("vkCreateInstance"));
    return fn ? fn(createInfo, allocator, instance) : VK_ERROR_INITIALIZATION_FAILED;
}

extern "C" __attribute__((visibility("default")))
void vkDestroyInstance(VkInstance instance, const VkAllocationCallbacks *allocator) {
    auto fn = reinterpret_cast<PFN_vkDestroyInstance>(resolve_symbol("vkDestroyInstance"));
    if (fn) {
        fn(instance, allocator);
    }
}

extern "C" __attribute__((visibility("default")))
VkResult vkEnumeratePhysicalDevices(VkInstance instance, uint32_t *deviceCount, VkPhysicalDevice *devices) {
    auto fn = reinterpret_cast<PFN_vkEnumeratePhysicalDevices>(resolve_symbol("vkEnumeratePhysicalDevices"));
    return fn ? fn(instance, deviceCount, devices) : VK_ERROR_INITIALIZATION_FAILED;
}
