#import "AppDelegate.h"
#include <sys/socket.h>
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_mib.h>

@implementation AppDelegate

@synthesize window = _window;

struct _count {
    uint64_t input;
    uint64_t output;
};
void getio(int row, struct _count *c) {
    struct ifmibdata ifmd;
    size_t len = sizeof(ifmd);
    int			name[6];
	name[0] = CTL_NET;
	name[1] = PF_LINK;
	name[2] = NETLINK_GENERIC;
	name[3] = IFMIB_IFDATA;
    name[4] = row;
	name[5] = IFDATA_GENERAL;
    if (sysctl(name, 6, &ifmd, &len, (void*)0, 0) < 0) {
        perror("sysctl");
        return;
    }
    c->input  += (ifmd.ifmd_data.ifi_ibytes * 8);
    c->output += (ifmd.ifmd_data.ifi_obytes * 8);
}
- (void) quit {
    exit(EXIT_SUCCESS);
}
#define SLEEP 2
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSStatusBar *bar = [NSStatusBar systemStatusBar];
    NSMenu *m = [[NSMenu alloc] initWithTitle:@""];
    [m addItem:[[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"in mbps, updated every %d seconds",SLEEP] action:nil keyEquivalent:@""]];
    [m addItem:[[NSMenuItem alloc] initWithTitle:@"Quit" action:@selector(quit) keyEquivalent:@"q"]];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        int			ifcount;
        size_t		len = sizeof(ifcount);
        NSStatusItem *s = [bar statusItemWithLength:NSVariableStatusItemLength];
        [s setMenu:m];
        struct _count current,prev;
        for (;;) {
            if (sysctlbyname("net.link.generic.system.ifcount", &ifcount,&len, (void*)0, 0) < 0) {
                perror("sysctlbyname");
                exit(EXIT_FAILURE);
            }
            prev = current;
            current.input = current.output = 0;
            for (; ifcount > 0; ifcount--)
                getio(ifcount,&current);
            [s setTitle:[NSString stringWithFormat:@"%lu|%lu",(current.input - prev.input)/SLEEP/1024/1024, (current.output - prev.output)/SLEEP/1024/1024]];
            sleep(SLEEP);
        }
    });
}
@end
