//
//  SCTimeSlider.m
//  SelfControl
//
//  Created by Charlie Stigler on 4/17/21.
//

#import "SCDurationSlider.h"
#import "SCConstants.h"
#import "SCTimeIntervalFormatter.h"
#import <TransformerKit/NSValueTransformer+TransformerKit.h>

#define kValueTransformerName @"BlockDurationSliderTransformer"

@implementation SCDurationSlider

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder: coder]) {
        [self initializeDurationProperties];
    }
    return self;
}
- (instancetype)init {
    if (self = [super init]) {
        [self initializeDurationProperties];
    }
    return self;
}

- (void)initializeDurationProperties {
    _maxDuration = kSCMaxBlockLengthMinutes;

    // register an NSValueTransformer
    [self registerMinutesValueTransformer];
}

- (void)setMaxDuration:(NSInteger)maxDuration {
    NSInteger cappedMax = MIN(maxDuration, kSCMaxBlockLengthMinutes);
    _maxDuration = [SCDurationSlider clampDurationMinutes: cappedMax max: cappedMax];
    [self setMinValue: kSCMinBlockDurationMinutes];
    [self setMaxValue: self.maxDuration];
    [self configureDurationTickMarks];
}

- (void)configureDurationTickMarks {
    NSSliderCell* cell = self.cell;
    if (cell == nil) {
        return;
    }
    NSInteger span = self.maxDuration - kSCMinBlockDurationMinutes;
    NSInteger tickCount = (span / kSCBlockDurationStepMinutes) + 1;
    cell.numberOfTickMarks = (int)tickCount;
    cell.allowsTickMarkValuesOnly = YES;
}

- (void)registerMinutesValueTransformer {
    [NSValueTransformer registerValueTransformerWithName: kValueTransformerName
                                   transformedValueClass: [NSNumber class]
                      returningTransformedValueWithBlock:^id _Nonnull(id  _Nonnull value) {
        if (![value respondsToSelector: @selector(floatValue)]) return @0;

        long minutesValue = lroundf([value floatValue]);
        minutesValue = [SCDurationSlider clampDurationMinutes: minutesValue max: kSCMaxBlockLengthMinutes];
        return @(minutesValue);
    }
                          allowingReverseTransformationWithBlock:^id _Nonnull(id  _Nonnull value) {
        if (![value respondsToSelector: @selector(floatValue)]) return @0;

        long minutesValue = lroundf([value floatValue]);
        minutesValue = [SCDurationSlider clampDurationMinutes: minutesValue max: kSCMaxBlockLengthMinutes];
        return @(minutesValue);
    }];
}

+ (NSInteger)clampDurationMinutes:(NSInteger)minutes max:(NSInteger)max {
    NSInteger clamped = MAX(kSCMinBlockDurationMinutes, MIN(max, minutes));
    NSInteger step = kSCBlockDurationStepMinutes;
    NSInteger rounded = ((clamped + step / 2) / step) * step;
    return MAX(kSCMinBlockDurationMinutes, MIN(max, rounded));
}

- (NSInteger)durationValueMinutes {
    return lroundf(self.floatValue);
}

- (void)bindDurationToObject:(id)obj keyPath:(NSString*)keyPath {
    [self bind: @"value"
      toObject: obj
   withKeyPath: keyPath
       options: @{
                  NSContinuouslyUpdatesValueBindingOption: @YES,
                  NSValueTransformerNameBindingOption: kValueTransformerName
                  }];
}

- (NSString*)durationDescription {
    return [SCDurationSlider timeSliderDisplayStringFromNumberOfMinutes: self.durationValueMinutes];
}

// String conversion utility methods

+ (NSString *)timeSliderDisplayStringFromTimeInterval:(NSTimeInterval)numberOfSeconds {
    static SCTimeIntervalFormatter* formatter = nil;
    if (formatter == nil) {
        formatter = [[SCTimeIntervalFormatter alloc] init];
    }

    NSString* formatted = [formatter stringForObjectValue:@(numberOfSeconds)];
    return formatted;
}

+ (NSString *)timeSliderDisplayStringFromNumberOfMinutes:(NSInteger)numberOfMinutes {
    if (numberOfMinutes < 0) return @"Invalid duration";

    static NSCalendar* gregorian = nil;
    if (gregorian == nil) {
        gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    }

    NSRange secondsRangePerMinute = [gregorian
                                     rangeOfUnit:NSCalendarUnitSecond
                                     inUnit:NSCalendarUnitMinute
                                     forDate:[NSDate date]];
    NSInteger numberOfSecondsPerMinute = (NSInteger)NSMaxRange(secondsRangePerMinute);

    NSTimeInterval numberOfSecondsSelected = (NSTimeInterval)(numberOfSecondsPerMinute * numberOfMinutes);

    NSString* displayString = [SCDurationSlider timeSliderDisplayStringFromTimeInterval:numberOfSecondsSelected];
    return displayString;
}


@end
