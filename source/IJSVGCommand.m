//
//  IJSVGCommand.m
//  IconJar
//
//  Created by Curtis Hard on 30/08/2014.
//  Copyright (c) 2014 Curtis Hard. All rights reserved.
//

#import "IJSVGCommand.h"
#import "IJSVGUtils.h"

@implementation IJSVGCommand

@synthesize commandString;
@synthesize string;
@synthesize command;
@synthesize parameterCount;
@synthesize parameters;
@synthesize subCommands;
@synthesize commandClass;
@synthesize requiredParameters;
@synthesize type;
@synthesize previousCommand;

static NSMutableDictionary * _classes = nil;

- (void)dealloc
{
    [string release], string = nil;
    [commandString release], commandString = nil;
    [command release], command = nil;
    [subCommands release], subCommands = nil;
    free( parameters );
    [super dealloc];
}

- (id)initWithCommandString:(NSString *)str
{
    if( ( self = [super init] ) != nil )
    {
        // work out the basics
        subCommands = [[NSMutableArray alloc] init];
        command = [[str substringToIndex:1] copy];
        type = [IJSVGUtils typeForCommandString:self.command];
        commandClass = [[self class] commandClassForCommandLetter:self.command];
        parameters = [IJSVGUtils commandParameters:str
                                                  count:&parameterCount];
        requiredParameters = [self.commandClass requiredParameterCount];
        
        // now work out the sets of parameters we have
        // each command could have a series of subcommands
        // if there is a multiple of commands in a command
        // then we need to work those out...
        NSInteger sets = 1;
        if( self.requiredParameters != 0 )
            sets = self.parameterCount/self.requiredParameters;
        
        // interate over the sets
        for( NSInteger i = 0; i < sets; i++ )
        {
            NSMutableString * cs = [[[NSMutableString alloc] init] autorelease];
            [cs appendString:self.command];
            
            // memory for this will be handled by the created subcommand
            CGFloat * subParams = (CGFloat*)malloc(self.requiredParameters*sizeof(CGFloat));
            for( NSInteger p = 0; p < self.requiredParameters; p++ )
            {
                subParams[p] = self.parameters[i*self.requiredParameters+p];
                [cs appendFormat:@"%f ",subParams[p]];
            }
            
            // create a subcommand per set
            IJSVGCommand * c = [[[[self class] alloc] init] autorelease];
            c.string = cs;
            c.parameterCount = self.requiredParameters;
            c.parameters = subParams;
            c.type = self.type;
            c.command = self.command;
            c.previousCommand = [self.subCommands lastObject];
            c.commandClass = self.commandClass;
            
            // add it to our tree
            [self.subCommands addObject:c];
        }
    }
    return self;
}

+ (void)registerClass:(Class)aClass
           forCommand:(NSString *)command
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _classes = [[NSMutableDictionary alloc] init];
    });
    [_classes setObject:NSStringFromClass(aClass)
                 forKey:command];
}

+ (NSDictionary *)registeredCommandClasses
{
    return _classes;
}

+ (void)load
{
    // register here...
}

+ (Class<IJSVGCommandProtocol>)commandClassForCommandLetter:(NSString *)str
{
    NSString * command = nil;
    if( ( command = [_classes objectForKey:[str lowercaseString]] ) == nil )
        return nil;
    return NSClassFromString(command);
}

@end
