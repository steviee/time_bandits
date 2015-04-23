#include <ruby.h>
#include <unistd.h>
#include <stdio.h>
#include <sys/resource.h>

VALUE mTimeBandits;

#ifdef __APPLE__
#include <mach/mach.h>
#define CONVERT_TO_BYTES(x) (x)
#else
#define CONVERT_TO_BYTES(x) (x*1024)
#endif

static VALUE get_peak_vm_size()
{
#if defined(HAVE_GETRUSAGE)
    struct rusage usage;
    int rc;

    rc = getrusage(RUSAGE_SELF, &usage);
    if (rc == -1)
        return LONG2NUM(0L);
    else
        return LONG2NUM(CONVERT_TO_BYTES(usage.ru_maxrss));
#else
    return LONG2NUM(0L);
#endif
}

static VALUE get_current_vm_size()
{
#if defined(__APPLE__) && defined(__MACH__)
    struct mach_task_basic_info info;
    mach_msg_type_number_t infoCount = MACH_TASK_BASIC_INFO_COUNT;
    if ( task_info( mach_task_self( ), MACH_TASK_BASIC_INFO,
                    (task_info_t)&info, &infoCount ) != KERN_SUCCESS )
        return LONG2NUM(0L);
    return LONG2NUM(info.resident_size);

#elif defined(__linux__) || defined(__linux) || defined(linux) || defined(__gnu_linux__)
    long rss = 0L;
    FILE* fp = NULL;
    if ( (fp = fopen("/proc/self/statm", "r") ) == NULL )
        return LONG2NUM(0L);
    if ( fscanf(fp, "%*s%ld", &rss ) != 1 ) {
        fclose(fp);
        return LONG2NUM(0L);
    }
    fclose(fp);
    return LONG2NUM(rss * sysconf(_SC_PAGESIZE));
#else
    return LONG2NUM(0L);
#endif
}

void Init_time_bandits()
{
    mTimeBandits = rb_define_module("TimeBandits");
    rb_define_module_function(mTimeBandits, "peak_vm_size", get_peak_vm_size, 0);
    rb_define_module_function(mTimeBandits, "current_vm_size", get_current_vm_size, 0);
}
