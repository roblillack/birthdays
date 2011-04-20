#import "Birthday.h"

@implementation Birthday

@synthesize year, month, day, name;

+ (Birthday*) birthdayWithYear: (NSUInteger) y
						 month: (NSUInteger) m
						   day: (NSUInteger) d
						  name: (NSString*) n {
    Birthday *bday = [[Birthday alloc] initWithYear: y
											  month: m
												day: d
											   name: n];
    return [bday autorelease];
}

+ (Birthday*) birthdayWithPerson: (ABPerson*) p {
	NSString *nameString = @"";
	
	NSString *first = [p valueForProperty: kABFirstNameProperty];
	if ([first length] > 0) {
		nameString = [nameString stringByAppendingString: first];
	}
	
	NSString *nickname = [p valueForProperty: kABNicknameProperty];
	if ([nickname length] > 0) {
		nameString = [nameString stringByAppendingFormat: @" ‘%@’", nickname];
	}
	
	if ([nameString length] > 0) {
		nameString = [nameString stringByAppendingString: @" "];
	}
	
	NSString *last = [p valueForProperty: kABLastNameProperty];
	if ([last length] > 0) {
		nameString = [nameString stringByAppendingString: last];
	}
	
	// TODO: company code missing
	id birth = [p valueForProperty: kABBirthdayProperty];
	
	if (!birth) {
		return nil;
	}
	
	return [Birthday birthdayWithYear: [birth yearOfCommonEra]
								month: [birth monthOfYear]
								  day: [birth dayOfMonth]
								 name: nameString];	
}

+ (Birthday*) birthdayWithDate: (NSDate*) d
						  name: (NSString*) n {
	NSDateComponents *components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit
																   fromDate: d];
	
	return [Birthday birthdayWithYear: [components year]
								month: [components month]
								  day: [components day]
								 name: n];
}

- (id) initWithYear: (NSUInteger) y
			  month: (NSUInteger) m
				day: (NSUInteger) d
			   name: (NSString*) n {
    if (self = [super init]) {
		year = y;
		month = m;
		day = d;
		name = n;
    }
    return self;
}

- (NSString*) description {
	return [NSString stringWithFormat: @"%04u-%02u-%02u %@", year, month, day, name];
}

- (NSString*) descriptionWithAgeIn: (NSUInteger) age_in_year {
	NSString *age;
	if (year > 0 && age_in_year > 0) {
		age = [NSString stringWithFormat: @" (%u)", age_in_year - year];
	} else {
		age = @"";
	}
	
	return [NSString stringWithFormat: @"%04u-%02u-%02u %@%@", year, month, day, name, age];
}

- (void) outputWithAgeIn: (NSUInteger) age_in_year
			reverseVideo: (BOOL) reverseVideo {
	printf("%s%s%s\n",
		   reverseVideo ? "\x1b[7m" : "",
		   [[self descriptionWithAgeIn: age_in_year] UTF8String],
		   reverseVideo ? "\x1b[m" : "");
}

- (void) outputWithAgeIn: (NSUInteger) age_in_year {
	[self outputWithAgeIn: age_in_year
			 reverseVideo: NO];
}

- (void) outputReverseVideo: (BOOL) reverse {
	[self outputWithAgeIn: 0
			 reverseVideo: reverse];
}

- (void) output {
	[self outputReverseVideo: NO];
}

- (NSComparisonResult) compare: (Birthday*) o {
	if (month > o->month) {
		return NSOrderedDescending;
	} else if (month < o->month) {
		return NSOrderedAscending;
	}

	if (day > o->day) {
		return NSOrderedDescending;
	} else if (day < o->day) {
		return NSOrderedAscending;
	}
	
	if (year > o->year) {
		return NSOrderedAscending;
	} else if (year < o->year) {
		return NSOrderedDescending;
	}
	
	return [name compare: o->name options: NSCaseInsensitiveSearch];
}

@end
