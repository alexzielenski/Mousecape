//
//  MCLbraryWindowController.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/2/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#import "MCLibraryWindowController.h"

@interface MCLibraryWindowController ()
- (void)composeAccessory;
@end

@implementation MCLibraryWindowController

- (id)initWithWindow:(NSWindow *)window {
    if ((self = [super initWithWindow:window])) {
        
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    [self composeAccessory];
    
}

- (NSString *)windowNibName {
    return @"Library";
}

- (void)composeAccessory {
    NSView *themeFrame = [self.window.contentView superview];
    NSView *accessory = self.appliedAccessory;
    [accessory setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    NSRect c  = themeFrame.frame;
    NSRect aV = accessory.frame;
    NSRect newFrame = NSMakeRect(
                                 c.size.width - aV.size.width,	// x position
                                 c.size.height - aV.size.height,	// y position
                                 aV.size.width,	// width
                                 aV.size.height);	// height
    
    [accessory setFrame:newFrame];
    [themeFrame addSubview:accessory];
    
    [themeFrame addConstraints:[NSLayoutConstraint
                                constraintsWithVisualFormat:@"H:|-(>=100)-[accessory(245)]-(0)-|"
                                options:0
                                metrics:nil
                                views:NSDictionaryOfVariableBindings(accessory)]];
    [themeFrame addConstraints:[NSLayoutConstraint
                                constraintsWithVisualFormat:@"V:|-(0)-[accessory(20)]-(>=22)-|"
                                options:0
                                metrics:nil
                                views:NSDictionaryOfVariableBindings(accessory)]];
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    return self.libraryViewController.libraryController.undoManager;
}

#pragma mark - Menu Actions

- (IBAction)applyCape:(NSMenuItem *)sender {
    MCCursorLibrary *cape = nil;
    if (sender.tag == -1)
        cape = self.libraryViewController.clickedCape;
    else
        cape = self.libraryViewController.selectedCape;
    
    [self.libraryViewController.libraryController applyCape:cape];
}

- (IBAction)editCape:(NSMenuItem *)sender {
    MCCursorLibrary *cape = nil;
    if (sender.tag == -1)
        cape = self.libraryViewController.clickedCape;
    else
        cape = self.libraryViewController.selectedCape;
    
    [self.libraryViewController editCape:cape];
}

- (IBAction)removeCape:(NSMenuItem *)sender {
    MCCursorLibrary *cape = nil;
    if (sender.tag == -1)
        cape = self.libraryViewController.clickedCape;
    else
        cape = self.libraryViewController.selectedCape;
    
    if (cape != self.libraryViewController.editingCape) {
        [self.libraryViewController.libraryController removeCape:cape];
    } else {
        [[NSSound soundNamed:@"Funk"] play];
        [self.libraryViewController editCape:self.libraryViewController.editingCape];
    }
}

- (IBAction)duplicateCape:(NSMenuItem *)sender {
    MCCursorLibrary *cape = nil;
    if (sender.tag == -1)
        cape = self.libraryViewController.clickedCape;
    else
        cape = self.libraryViewController.selectedCape;
    
    [self.libraryViewController.libraryController importCape:cape.copy];
}

- (IBAction)checkCape:(NSMenuItem *)sender {
    
}

- (IBAction)showCape:(NSMenuItem *)sender {
    MCCursorLibrary *cape = nil;
    if (sender.tag == -1)
        cape = self.libraryViewController.clickedCape;
    else
        cape = self.libraryViewController.selectedCape;
    
    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[ cape.fileURL ]];
}

@end

@implementation MCAppliedCapeValueTransformer

+ (Class)transformedValueClass {
    return [NSString class];
}

- (id)transformedValue:(id)value {
    return [NSLocalizedString(@"Applied Cape: ", @"Accessory label for applied cape") stringByAppendingString:value ? value : NSLocalizedString(@"None", @"Accessory label for when no cape is applied")];
}

@end