using System;
using System.Collections;
using System.IO;

class Log {
  //private static starttime : DateTime = DateTime.Now;
  public static void log(string text) {
    //WriteLine("LOG " + ((DateTime.Now - Log.starttime) :> TimeSpan).ToString() + ": " + text);
  }
}

class birthday : IComparable {
  public short year = -1;
  public short month = -1;
  public short day = -1;
  public string name = null;

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

  public void printData() {
    this.printData(-1);
  }

  public void printData(int whichyear) {
    Console.Write(this.year.ToString("0000;?   "));
    Console.Write("-");
    Console.Write(this.month.ToString("00;? "));
    Console.Write("-");
    Console.Write(this.day.ToString("00;? "));
    Console.Write(": ");
    Console.Write(this.name);
    if (whichyear != -1 && this.year != -1)
      Console.Write(" (" + (whichyear - this.year) + ")");
    Console.WriteLine();
  }
}

public class birthdays {
  public static void Main(string[] args) {
    Log.log("started.");
    Log.log("searching birthdays");
    string datafile = Environment.GetEnvironmentVariable("HOME") + "/birthdays";
    //System.Console.WriteLine(datafile);

    Log.log("opening file...");

    StreamReader sr = new StreamReader(File.OpenRead(datafile));

    Log.log("reading file...");
    ArrayList list = new ArrayList();
    for (string l = sr.ReadLine(); l != null; l = sr.ReadLine())
      list.Add(new birthday(l));
    Log.log("closing file...");
    sr.Close();

    Log.log("adding today");
    DateTime now = DateTime.Now;
    birthday today = new birthday(now.Year + " " + now.Month + " " + now.Day + " \x1b[1m*** TODAY ***");
    list.Add(today);

    Log.log("starting to sort dates...");
    list.Sort(); //bComparer());
    Log.log("finished sorting dates");

    Log.log("seeking today");
    int todayindex = list.BinarySearch(today);
    Log.log("found today");

    int showbefore = 3;
    int showafter = 5;

    Log.log("(possibly) showing dates from last year");
    // we should show more than we have this year before today
    if (showbefore - todayindex > 0) {
      for (int i = showbefore - todayindex; i > 0; i--)
        // only show if not longer ago than a year
        if (list.Count - i > todayindex)
          ((birthday)list[list.Count - i]).printData(now.Year - 1);
      Console.WriteLine("-----------");
    }

    Log.log("showing dates before today");
    // all dates from this year that are before today
    for (int i = showbefore; i > 0; i--)
      if (todayindex - i >= 0)
        ((birthday)list[todayindex - i]).printData(now.Year);

    Log.log("showing today");
    Console.Write("\x1b[3m");
    today.printData();
    Console.Write("\x1b[m");

    Log.log("showing future dates");
    for (int i = 1; i <= showafter; i++)
      if (todayindex + i < list.Count)
        ((birthday)list[todayindex + i]).printData(now.Year);

    Log.log("showing next year's dates");
    if (todayindex + showafter >= list.Count) {
      Console.WriteLine("-----------");
      for (int i = 0; i < (todayindex + showafter) - list.Count; i++)
        if (i < todayindex)
          ((birthday)list[i]).printData(now.Year + 1);
    }
  }
}
