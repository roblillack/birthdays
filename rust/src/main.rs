use chrono::{Datelike, Local};
use std::cmp::{max, min};
use std::fmt;
use std::fs::File;
use std::io::{self, BufRead};
use std::path::Path;
use std::str::FromStr;
use thiserror::Error;

#[derive(Error, Debug)]
enum BirthdayError {
    #[error("Missing or invalid year: {0}")]
    InvalidYear(String),
    #[error("Missing or invalid month: {0}")]
    InvalidMonth(String),
    #[error("Missing or invalid day: {0}")]
    InvalidDay(String),
    #[error("Month must be between 1 and 12, got: {0}")]
    MonthOutOfRange(u8),
    #[error("Day must be between 1 and 31, got: {0}")]
    DayOutOfRange(u8),
    #[error("Missing name")]
    MissingName,
    #[error("IO error: {0}")]
    Io(#[from] io::Error),
}

const TODAY_MARKER: &str = "\x1b[1m*** TODAY ***";
const HIGHLIGHT_START: &str = "\x1b[7m";
const HIGHLIGHT_END: &str = "\x1b[m";
const UNKNOWN_YEAR: &str = "xxxx";
const MIN_MONTH: u8 = 1;
const MAX_MONTH: u8 = 12;
const MIN_DAY: u8 = 1;
const MAX_DAY: u8 = 31;

#[derive(Debug, PartialEq, Eq, PartialOrd, Ord)]
struct Birthday {
    month: u8,
    day: u8,
    year: Option<u16>,
    name: String,
}

impl FromStr for Birthday {
    type Err = BirthdayError;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let mut iter = s.split_ascii_whitespace();

        let year_str = iter
            .next()
            .ok_or(BirthdayError::InvalidYear("missing".to_string()))?;
        let year;
        if let Ok(y) = year_str.parse::<u16>() {
            if y < 1900 || y > 2100 {
                return Err(BirthdayError::InvalidYear(year_str.to_string()));
            }
            year = Some(y)
        } else {
            year = None
        }

        let month_str = iter
            .next()
            .ok_or(BirthdayError::InvalidMonth("missing".to_string()))?;
        let month = month_str
            .parse::<u8>()
            .map_err(|_| BirthdayError::InvalidMonth(month_str.to_string()))?;

        if month < MIN_MONTH || month > MAX_MONTH {
            return Err(BirthdayError::MonthOutOfRange(month));
        }

        let day_str = iter
            .next()
            .ok_or(BirthdayError::InvalidDay("missing".to_string()))?;
        let day = day_str
            .parse::<u8>()
            .map_err(|_| BirthdayError::InvalidDay(day_str.to_string()))?;

        if day < MIN_DAY || day > MAX_DAY {
            return Err(BirthdayError::DayOutOfRange(day));
        }

        let name: String = iter.collect::<Vec<_>>().join(" ");
        if name.is_empty() {
            return Err(BirthdayError::MissingName);
        }

        Ok(Birthday {
            month,
            day,
            year,
            name,
        })
    }
}

impl Birthday {
    fn today() -> Self {
        let now = Local::now().naive_local().date();
        Birthday {
            name: TODAY_MARKER.to_string(),
            year: Some(now.year() as u16),
            month: now.month() as u8,
            day: now.day() as u8,
        }
    }

    fn format_for_year(&self, year: i32) -> String {
        let now = Local::now().naive_local().date();

        let birth_year = self.year.unwrap_or_default();
        let is_today = now.year() as u16 == birth_year
            && now.month() as u8 == self.month
            && now.day() as u8 == self.day;

        let age = if birth_year != 0 && !is_today {
            format!(" ({})", year as u16 - birth_year)
        } else {
            String::new()
        };

        let year_display = match self.year {
            Some(y) => format!("{:04}", y),
            None => UNKNOWN_YEAR.to_string(),
        };

        format!(
            "{}{}-{:02}-{:02} {}{}{}",
            if is_today { HIGHLIGHT_START } else { "" },
            year_display,
            self.month,
            self.day,
            self.name,
            age,
            if is_today { HIGHLIGHT_END } else { "" }
        )
    }
}

impl fmt::Display for Birthday {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        let now = Local::now().naive_local().date();
        write!(f, "{}", self.format_for_year(now.year()))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_parses() {
        let birthday: Birthday = "1990 12 31 John Doe".parse().unwrap();
        assert_eq!(birthday.month, 12);
        assert_eq!(birthday.day, 31);
        assert_eq!(birthday.year, Some(1990));
        assert_eq!(birthday.name, "John Doe");
    }

    #[test]
    fn it_handles_parse_errors_gracefully() {
        assert!("1990 sh 31 John Doe".parse::<Birthday>().is_err());
        assert!("1990 13 31 John Doe".parse::<Birthday>().is_err());
        assert!("1990 01 32 John Doe".parse::<Birthday>().is_err());
        assert!("1990 01 01".parse::<Birthday>().is_err());
    }

    #[test]
    fn it_parses_entries_without_year() {
        let birthday: Birthday = "???? 12 24 Jesus Christ".parse().unwrap();
        assert_eq!(birthday.month, 12);
        assert_eq!(birthday.day, 24);
        assert_eq!(birthday.year, None);
        assert_eq!(birthday.name, "Jesus Christ");

        assert!("19xx 10 08 Rob Lillack".parse::<Birthday>().is_ok());
        assert!("- 10 08 Rob Lillack".parse::<Birthday>().is_ok());
    }

    #[test]
    fn it_calculates_age() {
        let birthday: Birthday = "1981 10 08 Rob Lillack".parse().unwrap();
        assert_eq!(
            birthday.format_for_year(2023),
            "1981-10-08 Rob Lillack (42)"
        );
    }

    #[test]
    fn it_skips_calculating_age_for_entries_without_years() {
        let birthday: Birthday = "???? 12 24 Jesus Christ".parse().unwrap();
        assert_eq!(birthday.format_for_year(2023), "xxxx-12-24 Jesus Christ");
    }
}

fn read_birthdays() -> Result<Vec<Birthday>, BirthdayError> {
    let filename = home::home_dir()
        .ok_or_else(|| {
            BirthdayError::Io(io::Error::new(
                io::ErrorKind::NotFound,
                "Home directory not found",
            ))
        })?
        .join("birthdays");

    let lines = read_lines(filename)?;

    let birthdays: Result<Vec<Birthday>, BirthdayError> = lines
        .filter_map(|line| line.ok())
        .map(|line| line.parse::<Birthday>())
        .collect();

    birthdays
}

fn main() {
    let mut birthdays = match read_birthdays() {
        Ok(birthdays) => birthdays,
        Err(e) => {
            eprintln!("Error reading birthdays: {}", e);
            Vec::new()
        }
    };

    birthdays.push(Birthday::today());
    birthdays.sort();

    let pos = birthdays.binary_search(&Birthday::today()).unwrap() as i32;
    let len = birthdays.len() as i32;
    let now = Local::now().naive_local().date();
    let begin = max(pos - len + 1, pos - 3);
    let end = min(pos + len, pos + 7);

    for i in begin..end {
        let (idx, year) = match i {
            i if i < 0 => (len + i, now.year() - 1),
            i if i >= len => (i - len, now.year() + 1),
            _ => (i, now.year()),
        };
        if idx == 0 && i > begin {
            println!("----------");
        }
        println!("{}", birthdays[idx as usize].format_for_year(year));
    }
}

// The output is wrapped in a Result to allow matching on errors
// Returns an Iterator to the Reader of the lines of the file.
fn read_lines<P: AsRef<Path>>(filename: P) -> io::Result<io::Lines<io::BufReader<File>>> {
    let file = File::open(filename)?;
    Ok(io::BufReader::new(file).lines())
}
