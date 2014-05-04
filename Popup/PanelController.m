#import "PanelController.h"
#import "BackgroundView.h"
#import "StatusItemView.h"
#import "MenubarController.h"
#import "FileSystemItem.h"

#define OPEN_DURATION .15
#define CLOSE_DURATION .1

#define SEARCH_INSET 17

#define POPUP_HEIGHT 230
#define PANEL_WIDTH 300
#define MENU_ANIMATION_DURATION .1

#pragma mark -

@implementation PanelController

@synthesize backgroundView = _backgroundView;
@synthesize delegate = _delegate;
@synthesize searchField = _searchField;
@synthesize outlineView = _outlineView;
@synthesize addButton = _addButton;
@synthesize helpButton = _helpButton;

#pragma mark -

- (id)initWithDelegate:(id<PanelControllerDelegate>)delegate
{
    self = [super initWithWindowNibName:@"Panel"];
    if (self != nil)
    {
        _delegate = delegate;
        file_manager = [[NSFileManager alloc] init];
        gpg = [[GPGManager alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]
     removeObserver:self
     name:NSControlTextDidChangeNotification
     object:self.searchField];
}

#pragma mark -

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // Make a fully skinned panel
    NSPanel *panel = (id)[self window];
    [panel setAcceptsMouseMovedEvents:YES];
    [panel setLevel:NSPopUpMenuWindowLevel];
    [panel setOpaque:NO];
    [panel setBackgroundColor:[NSColor clearColor]];
    
    // Follow search string
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(runSearch)
     name:NSControlTextDidChangeNotification
     object:self.searchField];
}

#pragma mark - Public accessors

- (BOOL)hasActivePanel
{
    return _hasActivePanel;
}

- (void)setHasActivePanel:(BOOL)flag
{
    if (_hasActivePanel != flag)
    {
        _hasActivePanel = flag;
        
        if (_hasActivePanel)
        {
            [self openPanel];
        }
        else
        {
            [self closePanel];
        }
    }
}

#pragma mark - NSWindowDelegate

- (void)windowWillClose:(NSNotification *)notification
{
    self.hasActivePanel = NO;
}

- (void)windowDidResignKey:(NSNotification *)notification;
{
    if ([[self window] isVisible])
    {
        self.hasActivePanel = NO;
    }
}

void adjust_view(id field, NSRect bounds, CGFloat x, CGFloat y)
{
    NSRect frame = [field frame];
    frame.origin.x = x;
    frame.origin.y = y;
    
    if (NSIsEmptyRect(frame))
    {
        [field setHidden:YES];
    }
    else
    {
        [field setFrame:frame];
        [field setHidden:NO];
    }
}

- (void)windowDidResize:(NSNotification *)notification
{
    NSWindow *panel = [self window];
    NSRect statusRect = [self statusRectForWindow:panel];
    NSRect panelRect = [panel frame];
    
    CGFloat statusX = roundf(NSMidX(statusRect));
    CGFloat panelX = statusX - NSMinX(panelRect);
    
    self.backgroundView.arrowX = panelX;
    
    NSRect bounds = [self.backgroundView bounds];
    adjust_view(self.searchField, bounds,
                10,
                10);
    adjust_view(self.scrollView, bounds,
                13,
                15 + NSHeight([self.searchField frame]));
    adjust_view(self.addButton, bounds,
                10,
                POPUP_HEIGHT - NSHeight([self.helpButton frame]) - 20);
    adjust_view(self.helpButton, bounds,
                PANEL_WIDTH - NSWidth([self.helpButton frame]) - 10,
                POPUP_HEIGHT - NSHeight([self.helpButton frame]) - 15);
}

#pragma mark - Keyboard

- (void)cancelOperation:(id)sender
{
    self.hasActivePanel = NO;
}

- (void)runSearch
{
    NSString *searchFormat = @"";
    NSString *searchString = [self.searchField stringValue];
    if ([searchString length] > 0)
    {
        searchFormat = NSLocalizedString(@"Search for ‘%@’…",
                                         @"Format for search request");
    }
    NSString *searchRequest = [NSString
                               stringWithFormat:searchFormat, searchString];
}

#pragma mark - Public methods

- (NSRect)statusRectForWindow:(NSWindow *)window
{
    NSRect screenRect = [[[NSScreen screens] objectAtIndex:0] frame];
    NSRect statusRect = NSZeroRect;
    
    StatusItemView *statusItemView = nil;
    if ([self.delegate
         respondsToSelector:@selector(statusItemViewForPanelController:)])
    {
        statusItemView = [self.delegate
                          statusItemViewForPanelController:self];
    }
    
    if (statusItemView)
    {
        statusRect = statusItemView.globalRect;
        statusRect.origin.y = NSMinY(statusRect) - NSHeight(statusRect);
    }
    else
    {
        statusRect.size = NSMakeSize(STATUS_ITEM_VIEW_WIDTH,
                                     [[NSStatusBar systemStatusBar] thickness]);
        statusRect.origin.x = roundf((NSWidth(screenRect)
                                      - NSWidth(statusRect)) / 2);
        statusRect.origin.y = NSHeight(screenRect) - NSHeight(statusRect) * 2;
    }
    return statusRect;
}

- (void)openPanel
{
    NSWindow *panel = [self window];
    
    // re-populate list
    [_outlineView reloadData];
    
    NSRect screenRect = [[[NSScreen screens] objectAtIndex:0] frame];
    NSRect statusRect = [self statusRectForWindow:panel];

    NSRect panelRect = [panel frame];
    panelRect.size.width = PANEL_WIDTH;
    panelRect.size.height = POPUP_HEIGHT;
    panelRect.origin.x = roundf(NSMidX(statusRect) - NSWidth(panelRect) / 2);
    panelRect.origin.y = NSMaxY(statusRect) - NSHeight(panelRect);
    
    if (NSMaxX(panelRect) > (NSMaxX(screenRect) - ARROW_HEIGHT))
        panelRect.origin.x -= NSMaxX(panelRect)
                              - (NSMaxX(screenRect) - ARROW_HEIGHT);
    
    [NSApp activateIgnoringOtherApps:NO];
    [panel setAlphaValue:0];
    [panel setFrame:statusRect display:YES];
    [panel makeKeyAndOrderFront:nil];
    
    NSTimeInterval openDuration = OPEN_DURATION;
    
    NSEvent *currentEvent = [NSApp currentEvent];
    if ([currentEvent type] == NSLeftMouseDown)
    {
        NSUInteger clearFlags = ([currentEvent modifierFlags]
                                 & NSDeviceIndependentModifierFlagsMask);
        BOOL shiftPressed = (clearFlags
                             == NSShiftKeyMask);
        BOOL shiftOptionPressed = (clearFlags
                                   == (NSShiftKeyMask | NSAlternateKeyMask));
        
        if (shiftPressed || shiftOptionPressed)
        {
            openDuration *= 10;
            
            if (shiftOptionPressed)
                NSLog(@"Icon is at %@\n\t"
                      @"Menu is on screen %@\n\t"
                      @"Will be animated to %@",
                      NSStringFromRect(statusRect),
                      NSStringFromRect(screenRect),
                      NSStringFromRect(panelRect));
        }
    }
    
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:openDuration];
    [[panel animator] setFrame:panelRect display:YES];
    [[panel animator] setAlphaValue:1];
    [NSAnimationContext endGrouping];
    
    [panel
     performSelector:@selector(makeFirstResponder:)
     withObject:self.searchField
     afterDelay:openDuration];
}

- (void)closePanel
{
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:CLOSE_DURATION];
    [[[self window] animator] setAlphaValue:0];
    [NSAnimationContext endGrouping];
    
    dispatch_after(dispatch_walltime(NULL, NSEC_PER_SEC * CLOSE_DURATION * 2),
                   dispatch_get_main_queue(), ^{
        [self.window orderOut:nil];
    });
}

// from https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/OutlineView/Articles/UsingOutlineDataSource.html#//apple_ref/doc/uid/20000725-BBCDGDAG
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    return [((item == nil)
             ? [FileSystemItem rootItem]
             : item)
            numberOfChildren];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    return (item == nil) ? YES : ([item numberOfChildren] != -1);
}

- (id)outlineView:(NSOutlineView *)outlineView
        child:(NSInteger)index
        ofItem:(id)item
{
    return [((item == nil)
             ? [FileSystemItem rootItem]
             : item)
            childAtIndex:index];
}

- (id)outlineView:(NSOutlineView *)outlineView
        objectValueForTableColumn:(NSTableColumn *)tableColumn
        byItem:(id)item
{
    return (item == nil) ? @"NULL" : [[item relativePath]
                                      stringByDeletingPathExtension];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
    return ![self outlineView:outlineView isItemExpandable:item];
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    id item = [_outlineView itemAtRow:[_outlineView selectedRow]];
    if (item != nil) {
        
        // post decrypted password to clipboard
        printf("decrypting %s\n", [[item fullPath] UTF8String]);
        NSString *plain = [gpg decryptPasswordFromFile:[item fullPath]];
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        [pasteboard clearContents];
        [pasteboard
            writeObjects:[NSArray
                            arrayWithObject:plain]];
        [_outlineView deselectAll:item];
        
        int timeout = 45;
        
        // show notification
        // credit http://blog.mahasoftware.com/post/28968246552/how-to-use-the-10-8-notification-center-api
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        [notification setTitle:@"Password Store"];
        [notification
         setInformativeText:[NSString
                             stringWithFormat:@"Copied %@ to clipboard. "
                                              @"Will clear in %d seconds.",
                                [[item partialPath]
                                   stringByDeletingPathExtension],
                                timeout]];
        [notification setSoundName:NSUserNotificationDefaultSoundName];
        
        NSUserNotificationCenter *center = [NSUserNotificationCenter
                                            defaultUserNotificationCenter];
        [center setDelegate:self];
        [center deliverNotification:notification];
        
        // clear clipboard after 45 seconds
        [NSTimer
            scheduledTimerWithTimeInterval:timeout
            target:pasteboard
            selector:@selector(clearContents)
            userInfo:nil
            repeats:NO];
    }
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center
        shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}

@end
