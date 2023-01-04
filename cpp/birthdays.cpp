#include <Core/Core.h>

class Birthday : Comparable <Birthday, Moveable <Birthday> > {
public:
	String name;
	int year;
	int month;
	int day;
	Birthday();
	Birthday(const String&);
	Birthday(const Date&, const String&);
	void Print(int);
	int Compare(const Birthday&) const;
	bool operator<(const Birthday&);
	bool operator>(const Birthday&);
	bool operator==(const Birthday&);
	
};

Birthday::Birthday(const Date &date, const String &who) {
	year = date.year;
	month = date.month;
	day = date.day;
	name = who;
}

Birthday::Birthday(const String &line) {
	Vector <String> tokens = Split(line, ' ', true);
	static Value v;
	switch (tokens.GetCount()) {
		default:
		for (int i = 3; i < tokens.GetCount(); i++)
			name += (i > 3 ? " " : "") + tokens[i];
		case 3:
		if ((v = StdConvertIntNotNull().Scan(tokens[2])) &&
			!IsError(v) && (int)v > 0 && (int)v <= 31)
			day = v;
		else day = -1;
		case 2:
		if ((v = StdConvertIntNotNull().Scan(tokens[1])) &&
			!IsError(v) && (int)v > 0 && (int)v <= 12)
			month = v;
		else month = -1;
		case 1:
		if ((v = StdConvertIntNotNull().Scan(tokens[0])) &&
			!IsError(v) && (int)v >= 1900 && (int)v <= 9999)
			year = v;
		else year = -1;
		case 0:
		break;
	}
}
	
void Birthday::Print(int y = -1) {
	Cout() << (year > 0 ? Format("%04d", year) : "?   ") << "-"
	       << (month > 0 ? Format("%02d", month) : "? ") << "-"
	       << (day > 0 ? Format("%02d", day) : "? ") << ": " << name;
	if (y > 0 && year > 1)
		Cout() << " (" << (y - year) << ")";
	Cout() << '\n';
}

int Birthday::Compare(const Birthday &other) const {
	int delta = month - other.month;
	if (delta == 0) {
		delta = day - other.day;
		if (delta == 0) {
			delta == year - other.year;
			if (delta == 0) {
				return name.Compare(other.name);
			} else {
				return -delta;
			}
		} else return delta;
	} else return delta;
}

inline bool Birthday::operator<(const Birthday &other) {
	return (Compare(other) < 0);
}

inline bool Birthday::operator>(const Birthday &other) {
	return (Compare(other) > 0);
}

inline bool Birthday::operator==(const Birthday &other) {
	return (Compare(other) == 0);
}

CONSOLE_APP_MAIN {
	Vector<Birthday> list;

	FileIn birthdays(String(getenv("HOME")) + "/birthdays");
	while (!birthdays.IsEof()) list << Birthday(birthdays.GetLine());
	birthdays.Close();

	Birthday today = Birthday(Date(), "\x1b[1m*** TODAY ***");
	time_t now = time(NULL);
	struct tm *bla = localtime(&now);
	today.year = bla->tm_year + 1900;
	today.month = bla->tm_mon + 1;
	today.day = bla->tm_mday;
	list << today;

	Sort(list);
	
	int todayindex = FindBinary(list, today);
	int showbefore = 3;
	int showafter = 5;
	
	// dates from the year before this year
	if (showbefore - todayindex > 0) {
		for (int i = showbefore - todayindex; i > 0; i--)
			// only show if not longer than a year ago
			if (list.GetCount() - i > todayindex)
				list[list.GetCount() - i].Print(today.year - 1);
		Cout() << "----------" << '\n';
	}

	// all dates from this year that are before today
	for (int i = showbefore; i > 0; i--)
		if (todayindex - i >= 0)
			list[todayindex - i].Print(today.year);
	
	// ‘reverse video’
	Cout() << "\x1b[7m";
	today.Print();
	Cout() << "\x1b[m";
	
	// following dates this year
	for (int i = 1; i <= showafter; i++) 
		if (todayindex + i < list.GetCount())
			list[todayindex + i].Print(today.year);
	
	// dates next year
	if (todayindex + showafter >= list.GetCount()) {
		Cout() << "----------" << '\n';
		for (int i = 0; i < todayindex + showafter - list.GetCount(); i++)
			if (i < todayindex)
				list[i].Print(today.year + 1);
	}
}
