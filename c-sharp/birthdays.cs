using System;
using System.Collections;
using System.IO;

class birthday : IComparable {
  private int year = -1;
  private int month = -1;
  private int day = -1;
  private string name = null;

  public int CompareTo(object other) {
    int delta = this.month - ((birthday)other).month;
    if (delta == 0) {
      delta = this.day - ((birthday)other).day;
      if (delta == 0) {
        delta = this.year - ((birthday)other).year;
        if (delta == 0) {
          return this.name.CompareTo(((birthday)other).name);
        } else {
          return -delta; // youngest first (and therefore *today* at the top)
        }
      } else return delta;
    } else return delta;
  }

  public birthday(string input) {
    string[] split = input.Split(null, 4);
    name = split[3];
    
    try { this.year = Convert.ToInt16(split[0]); }
    catch (FormatException e) { this.year = -1; }
    try { this.month = Convert.ToInt16(split[1]); }
    catch (FormatException e) { this.month = -1; }
    try { this.day = Convert.ToInt16(split[2]); }
    catch (FormatException e) { this.day = -1; }
  }

  public birthday(DateTime when, string who) {
    this.year = when.Year;
    this.month = when.Month;
    this.day = when.Day;
    this.name = who;
  }

  public void printData() {
    this.printData(-1);
  }

  public void printData(int whichyear) {
    Console.WriteLine("{0}-{1}-{2}: {3}{4}",
                      this.year.ToString("0000;?   "),
                      this.month.ToString("00;? "),
                      this.day.ToString("00;? "),
                      this.name,
                      (whichyear != -1 && this.year != -1) ?
                      " (" + (whichyear - this.year) + ")" : "");
  }
}

public class birthdays {
  public static void Main(string[] args) {
    string datafile = Environment.GetEnvironmentVariable("HOME") + "/birthdays";

    StreamReader sr = new StreamReader(File.OpenRead(datafile));

    ArrayList list = new ArrayList();
    for (string l = sr.ReadLine(); l != null; l = sr.ReadLine())
      list.Add(new birthday(l));
    sr.Close();

    DateTime now = DateTime.Now;
    birthday today = new birthday(now, "\x1b[1m*** TODAY ***");
    list.Add(today);
    list.Sort(); //bComparer());
    int todayindex = list.BinarySearch(today);
    int showbefore = 3;
    int showafter = 5;

    // we should show more than we have this year before today
    if (showbefore - todayindex > 0) {
      for (int i = showbefore - todayindex; i > 0; i--)
        // only show if not longer ago than a year
        if (list.Count - i > todayindex)
          ((birthday)list[list.Count - i]).printData(now.Year - 1);
      Console.WriteLine("-----------");
    }

    // all dates from this year that are before today
    for (int i = showbefore; i > 0; i--)
      if (todayindex - i >= 0)
        ((birthday)list[todayindex - i]).printData(now.Year);

    Console.Write("\x1b[3m");
    today.printData();
    Console.Write("\x1b[m");

    for (int i = 1; i <= showafter; i++)
      if (todayindex + i < list.Count)
        ((birthday)list[todayindex + i]).printData(now.Year);

    if (todayindex + showafter >= list.Count) {
      Console.WriteLine("-----------");
      for (int i = 0; i < (todayindex + showafter) - list.Count; i++)
        if (i < todayindex)
          ((birthday)list[i]).printData(now.Year + 1);
    }
  }
}
