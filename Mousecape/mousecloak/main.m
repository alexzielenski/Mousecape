//
//  main.m
//  mousecloak
//
//  Created by Alex Zielenski on 2/11/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import "restore.h"
#import "backup.h"
#import "apply.h"
#import "create.h"

#import <GBCli/GBSettings.h>
#import <GBCli/GBOptionsHelper.h>
#import <GBCli/GBCommandLineParser.h>

@interface GBOptionsHelper (Helper)
- (void)replacePlaceholdersAndPrintStringFromBlock:(GBOptionStringBlock)block;
@end

int main(int argc, char * argv[]) {
    @autoreleasepool {
        defaultCursors = @[
                           @"com.apple.coregraphics.Arrow",
                           @"com.apple.coregraphics.IBeam",
                           @"com.apple.coregraphics.IBeamXOR",
                           @"com.apple.coregraphics.Alias",
                           @"com.apple.coregraphics.Copy",
                           @"com.apple.coregraphics.Move",
                           @"com.apple.coregraphics.ArrowCtx",
                           @"com.apple.coregraphics.Wait",
                           @"com.apple.coregraphics.Empty"];
        
        GBSettings *settings = [GBSettings settingsWithName:@"mousecape" parent:nil];
        
        GBOptionsHelper *options = [[[GBOptionsHelper alloc] init] autorelease];
        [options registerSeparator:@(BOLD "APPLYING CAPES" RESET)];
        [options registerOption:'a' long:@"apply" description:@"Apply a cape" flags:GBValueRequired];
        [options registerOption:'r' long:@"reset" description:@"Reset to the default OSX cursors" flags:GBValueNone];
        [options registerSeparator:@(BOLD "CREATING CAPES" RESET)];
        [options registerOption:'c' long:@"create"
                    description:
         @"Create a cursor from a folder. Default output is to a new file of the same name. Directory must use the format:\n"
         "\t\t├── com.apple.coregraphics.Arrow\n"
         "\t\t│   ├── 0.png\n"
         "\t\t│   ├── 1.png\n"
         "\t\t│   ├── 2.png\n"
         "\t\t│   └── 3.png\n"
         "\t\t├── com.apple.coregraphics.Wait\n"
         "\t\t│   ├── 0.png\n"
         "\t\t│   ├── 1.png\n"
         "\t\t│   └── 2.png\n"
         "\t\t├── com.apple.cursor.3\n"
         "\t\t│   ├── 0.png\n"
         "\t\t│   ├── 1.png\n"
         "\t\t│   ├── 2.png\n"
         "\t\t│   └── 3.png\n"
         "\t\t└── com.apple.cursor.5\n"
         "\t\t    ├── 0.png\n"
         "\t\t    ├── 1.png\n"
         "\t\t    ├── 2.png\n"
         "\t\t    └── 3.png\n"
                          flags:GBValueRequired];
        [options registerOption:'d' long:@"dump" description:@"Dumps the currently applied cursors to a file." flags:GBValueRequired];
        [options registerSeparator:@(BOLD "CONVERTING MIGHTYMOUSE TO CAPE" RESET)];
        [options registerOption:'x' long:@"convert" description:@"Convert a .MightyMouse file to cape. Default output is to a new file of the same name" flags:GBValueRequired];
        [options registerSeparator:@(BOLD "MISCELLANEOUS" RESET)];
        [options registerOption:'?' long:@"help" description:@"Display this help and exit" flags:GBValueNone];
        [options registerOption:'o' long:@"output" description:@"Use this option to tell where an output file goes. (For convert and create)" flags:GBValueRequired];
        [options registerOption:0 long:@"suppressCopyright" description:@"Suppress Copyright info" flags:GBValueNone | GBOptionNoHelp | GBOptionNoPrint];
        [options registerOption:'s' long:@"scale" description:@"Scale the cursor to obscene multipliers or get the current scale" flags:GBValueOptional];
        
        options.applicationName = ^{ return @"mousecloak"; };
        options.applicationVersion = ^{ return @"2.0"; };
        options.applicationBuild = ^{ return @""; };
        options.printHelpHeader = ^{ return @(BOLD WHITE "%APPNAME v%APPVERSION" RESET); };
        options.printHelpFooter = ^{ return @(BOLD WHITE "Copyright © 2013-14 Alex Zielenski" RESET); };
        
        GBCommandLineParser *parser = [[[GBCommandLineParser alloc] init] autorelease];
        [options registerOptionsToCommandLineParser:parser];
        [parser parseOptionsWithArguments:argv count:argc block:^(GBParseFlags flags, NSString *option, id value, BOOL *stop) {
            switch (flags) {
                case GBParseFlagUnknownOption:
                    MMLog(BOLD RED "Unknown command line option %s, try --help!" RESET, option.UTF8String);
                    break;
                case GBParseFlagMissingValue:
                    MMLog(BOLD RED "Missing value for command line option %s, try --help!" RESET, option.UTF8String);
                    break;
                case GBParseFlagArgument:
                    [settings addArgument:value];
                    break;
                case GBParseFlagOption:
                    [settings setObject:value forKey:option];
                    break;
            }
        }];
        
        if ([settings boolForKey:@"help"] || argc == 1) {
            [options printHelp];
            return EXIT_SUCCESS;
        }
        
        BOOL suppressCopyright = [settings boolForKey:@"suppressCopyright"];
        
        if (!suppressCopyright)
            [options replacePlaceholdersAndPrintStringFromBlock:options.printHelpHeader];
        
        if ([settings boolForKey:@"reset"]) {
            // reset to default cursors
            resetAllCursors();
            
            if (!suppressCopyright)
                [options replacePlaceholdersAndPrintStringFromBlock:options.printHelpFooter];
            return EXIT_SUCCESS;
        }
        
        BOOL convert = [settings isKeyPresentAtThisLevel:@"convert"];
        BOOL apply   = [settings isKeyPresentAtThisLevel:@"apply"];
        BOOL create  = [settings isKeyPresentAtThisLevel:@"create"];
        BOOL dump    = [settings isKeyPresentAtThisLevel:@"dump"];
        BOOL scale   = [settings isKeyPresentAtThisLevel:@"scale"];
        int amt = 0;
        
        if (convert) amt++;
        if (apply) amt++;
        if (create) amt++;
        if (dump) amt++;
        if (scale) amt++;
        
        if (amt > 1) {
            printf(BOLD RED "One command at a time, son!" RESET);
            
            if (!suppressCopyright)
                [options replacePlaceholdersAndPrintStringFromBlock:options.printHelpFooter];
            return 0;
        }
        
        NSFileManager *manager = [NSFileManager defaultManager];
        
        if (apply) {
            // Apply a cape at a given path
            NSString *path = [settings objectForKey:@"apply"];
            NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
            
            BOOL isDir = NO;
            BOOL fileExists = [manager fileExistsAtPath:path];
            
            if (!fileExists || isDir) {
                MMLog(BOLD RED "Invalid cursor file or bad path given: %s" RESET, path.UTF8String);
                goto fin;
            }
            
            if (dict)
                applyCape(dict);
            
        } else if (create || convert) {
            NSError *error  = nil;
            NSString *input = create ? [settings objectForKey:@"create"] : [settings objectForKey:@"convert"];
            NSString *output = [settings isKeyPresentAtThisLevel:@"output"] ? [settings objectForKey:@"output"] : input.stringByDeletingLastPathComponent;
            
            error = createCape(input, output, convert);
            if (error) {
                MMLog(BOLD RED "%s" RESET, error.localizedDescription.UTF8String);
            } else {
                MMLog(BOLD GREEN "Cape successfully written to %s" RESET, output.UTF8String);
            }
            goto fin;

        } else if (dump) {
            dumpCursorsToFile([settings objectForKey:@"dump"]);
        } else if (scale) {
            NSNumber *number = [settings objectForKey:@"scale"];
            
            if (argc == 2) {
                
                float value;
                CGSGetCursorScale(CGSMainConnectionID(), &value);
                
                MMLog("%f", value);
                
            } else {
                float dbl = number.floatValue;
                
                if (dbl > 32) {
                    MMLog("Not a good idea...");
                } else if (CGSSetCursorScale(CGSMainConnectionID(), dbl) == noErr) {
                    MMLog("Successfully set cursor scale!");
                } else {
                    MMLog("Somehow failed to set cursor scale!");
                }
            }
            goto fin;
        }
        fin: {
            if (!suppressCopyright)
                [options replacePlaceholdersAndPrintStringFromBlock:options.printHelpFooter];
        }
        
        return EXIT_SUCCESS;
    }
}

