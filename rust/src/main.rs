use chrono::{Datelike, Local, NaiveDate};
use std::cmp::{max, min};
use std::fs::File;
use std::io::{self, BufRead};
use std::path::Path;

#[derive(PartialEq, Eq, PartialOrd, Ord)]
struct Birthday {
    month: u8,
    day: u8,
    year: Option<u16>,
    name: String,
}

impl Birthday {
    fn from(s: &str) -> Self {
        let mut iter = s.split_ascii_whitespace();
        let (year, month, day, name) = (
            match iter.next().unwrap().to_string().parse::<u16>() {
                Ok(y) => Some(y),
                Err(_) => None,
            },
            iter.next().unwrap().to_string().parse::<u8>().unwrap(),
            iter.next().unwrap().to_string().parse::<u8>().unwrap(),
            String::from(iter.fold(String::new(), |a, b| a + b + " ").trim()),
        );
        Birthday {
            month,
            day,
            year,
            name,
        }
    }

    fn today() -> Self {
        let now: NaiveDate = Local::now().naive_local().date();
        Birthday {
            name: String::from("\x1b[1m*** TODAY ***"),
            year: Some(now.year() as u16),
            month: now.month() as u8,
            day: now.day() as u8,
        }
    }

    fn to_string_for_year(&self, year: i32) -> String {
        let now: NaiveDate = Local::now().naive_local().date();

        let y = self.year.unwrap_or_default();
        let is_today = now.year() as u16 == y
            && now.month() as u8 == self.month
            && now.day() as u8 == self.day;
        let age = if y != 0 && !is_today {
            format!(" ({})", year as u16 - y)
        } else {
            "".to_string()
        };

        format!(
            "{}{}-{:02}-{:02} {}{}{}",
            if is_today { "\x1b[7m" } else { "" },
            match &self.year {
                Some(y) => format!("{:04}", y),
                _ => "xxxx".to_string(),
            },
            self.month,
            self.day,
            self.name,
            age,
            if is_today { "\x1b[m" } else { "" }
        )
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_parses() {
        let bday = Birthday::from("1990 12 31 John Doe");
        assert_eq!(bday.month, 12);
        assert_eq!(bday.day, 31);
        assert_eq!(bday.year, Some(1990));
        assert_eq!(bday.name, "John Doe");
    }

    #[test]
    fn it_parses_entries_without_year() {
        let bday = Birthday::from("???? 12 24 Jesus Christ");
        assert_eq!(bday.month, 12);
        assert_eq!(bday.day, 24);
        assert_eq!(bday.year, None);
        assert_eq!(bday.name, "Jesus Christ");
    }

    #[test]
    fn it_calculates_age() {
        let bday = Birthday::from("1981 10 08 Rob Lillack");
        assert_eq!(bday.to_string_for_year(2023), "1981-10-08 Rob Lillack (42)");
    }

    #[test]
    fn it_skips_calculating_age_for_entries_without_years() {
        let bday = Birthday::from("???? 12 24 Jesus Christ");
        assert_eq!(bday.to_string_for_year(2023), "xxxx-12-24 Jesus Christ");
    }
}

fn read_birthdays() -> Vec<Birthday> {
    let filename = home::home_dir().unwrap().join("birthdays");
    let mut birthdays: Vec<Birthday> = Vec::new();

    if let Ok(lines) = read_lines(filename) {
        for line in lines {
            if let Ok(ip) = line {
                birthdays.push(Birthday::from(&ip));
            }
        }
    }

    return birthdays;
}

fn main() {
    let mut bdays = read_birthdays();
    bdays.push(Birthday::today());
    bdays.sort();

    let pos = bdays.binary_search(&Birthday::today()).unwrap() as i32;
    let len = bdays.len() as i32;
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
        println!("{}", bdays[idx as usize].to_string_for_year(year));
    }
}

// The output is wrapped in a Result to allow matching on errors
// Returns an Iterator to the Reader of the lines of the file.
fn read_lines<P: AsRef<Path>>(filename: P) -> io::Result<io::Lines<io::BufReader<File>>> {
    let file = File::open(filename)?;
    Ok(io::BufReader::new(file).lines())
}
