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

+ (Birthday*) birthdayWithContact: (CNContact*) c {
    NSString *nameString = @"";
    
    NSString *first = c.givenName;
    if ([first length] > 0) {
        nameString = [nameString stringByAppendingString: first];
    }
    
    NSString *nickname = c.nickname;
    if ([nickname length] > 0) {
        nameString = [nameString stringByAppendingFormat: @" ‘%@’", nickname];
    }
    
    if ([nameString length] > 0) {
        nameString = [nameString stringByAppendingString: @" "];
    }
    
    NSString *last = c.familyName;
    if ([last length] > 0) {
        nameString = [nameString stringByAppendingString: last];
    }
    
    if (!c.birthday) {
        return nil;
    }
    
    return [Birthday birthdayWithYear:c.birthday.year month:c.birthday.month day:c.birthday.day name:nameString];
}

+ (Birthday*) birthdayWithDate: (NSDate*) d
						  name: (NSString*) n {
	NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear
																   fromDate: d];
	
	return [Birthday birthdayWithYear: [components year]
								month: [components month]
								  day: [components day]
								 name: n];
}

- (id) initWithYear: (unsigned long) y
			  month: (unsigned long) m
				day: (unsigned long) d
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
	return [NSString stringWithFormat: @"%04lu-%02lu-%02lu %@", year, month, day, name];
}

- (NSString*) descriptionWithAgeIn: (unsigned long) age_in_year {
	NSString *age;
	if (year > 0 && age_in_year > 0) {
		age = [NSString stringWithFormat: @" (%lu)", age_in_year - year];
	} else {
		age = @"";
	}
	
	return [NSString stringWithFormat: @"%04lu-%02lu-%02lu %@%@", year, month, day, name, age];
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
    if (o == NULL) {
        return NSOrderedAscending;
    }
    
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
