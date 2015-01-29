//
//  NSString+JustNumbers.m
//  Pincore Tests
//
//  Created by Richard Allen on 12/31/13.
//

#import "NSString+JustNumbers.h"

@implementation NSString (JustNumbers)

//  Credit: http://stackoverflow.com/a/1426819/1333939
-(NSString *)justNumbers
{
    return [[self componentsSeparatedByCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""];
}

@end
