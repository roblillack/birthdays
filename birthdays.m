#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>
#import <Contacts/Contacts.h>
#import "Birthday.h"

void printBirthdays(NSArray *list, long first, long last, NSUInteger year) {
	for (NSInteger i = first; i != last; i += (first < last) ? 1 : -1) {
		@try {
			[[list objectAtIndex: i] outputWithAgeIn: year];
		}
		@catch(NSException *e) {
		}
	}
}


extern void _NSSetLogCStringFunction(void(*)(const char*, unsigned, BOOL));

static void noLog(const char *message, unsigned length,
                   BOOL withSyslogBanner) {
    // nothing.
}

void listBirthdays(CNContactStore *store) {
    // Disabling this, because notorious:
    // 2022-01-31 21:51:40.693 birthdays[19298:198948] XXX: countOfStores: 1, countOfAccounts: 1
    _NSSetLogCStringFunction(noLog);

    NSMutableArray *list = [[NSMutableArray alloc] init];
    
    NSArray *keys = @[CNContactFamilyNameKey, CNContactNicknameKey, CNContactGivenNameKey, CNContactBirthdayKey];

    id predicate = [CNContact predicateForContactsInContainerWithIdentifier:store.defaultContainerIdentifier];
    
    for (id contact in [store unifiedContactsMatchingPredicate:predicate keysToFetch:keys error:NULL]) {
        Birthday *b = [Birthday birthdayWithContact: contact];
        if (b) {
            [list addObject: b];
        }
    }
   
    id todayString = isatty(1) ? @"\x1b[1m*** TODAY ***\x1b[m" : @"*** TODAY ***";

    id today = [Birthday birthdayWithDate: [NSDate date]
                                     name: todayString];
    [list addObject: today];
    [list sortUsingSelector: @selector(compare:)];
    
    NSInteger before = 3;
    NSInteger after = 5;
    NSUInteger count = [list count];
    
    NSInteger idx_today = 0;
    for (NSInteger i = 0; i != [list count]; i++) {
        if ([list objectAtIndex: i] == today) {
            idx_today = i;
            break;
        }
    }
        
    // dates from the year before this year
    if (before - idx_today > 0) {
        printBirthdays(list, count - before - idx_today, count - 1, [today year] - 1);
        printf("----------\n");
    }
    
    printBirthdays(list, idx_today - before - 1, idx_today - 1, [today year]);
    [today outputReverseVideo: isatty(1)];
    printBirthdays(list, idx_today + 1, idx_today + after + 1, [today year]);
    
    // next year
    if (idx_today + after >= [list count]) {
        printf("----------\n");
        printBirthdays(list, 0, idx_today + after - count - 1, [today year] + 1);
    }
                   
}

int main (int argc, const char * argv[]) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    CNContactStore *store = [[CNContactStore alloc] init];

    [store requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (granted == YES) {
            listBirthdays(store);
        }
    }];

    [pool drain];
    return 0;
}
