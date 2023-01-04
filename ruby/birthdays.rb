#!/usr/bin/env ruby

class Birthday
  include Comparable
  attr_reader :year, :month, :day, :name

  def initialize(year, month, day, name)
    return nil unless month >= 1 and month <= 12 and
                      day >= 1 and day <= 31 and
                      name != nil and !name.empty?
    @year = year
    if @year < 1000 then
      @year = 0
    end
    @month = month
    @day = day
    @name = name.strip
  end

  def Birthday.newFromLine(line)
    year, month, day, name = line.split(/[\s\-]+/, 4)
    new(year.to_i, month.to_i, day.to_i, name)
  end

  def stringWithAgeIn(ageIn)
    (@year > 0 ? sprintf("%04u", @year) : "?   " ) +
      sprintf("-%02u-%02u %s", @month, @day, @name) +
      ((@year > 0 and ageIn) ? " (#{(ageIn - @year)})" : "")
  end

  def to_str
    stringWithAgeIn(nil)
  end

  def <=>(another)
    delta = @month <=> another.month
    return delta unless delta == 0
    delta = @day <=> another.day
    return delta unless delta == 0
    delta = @year <=> another.year
    # invert years, because THIS year should be the first
    return -delta unless delta == 0
    return @name <=> another.name
  end
    
end

def addFlatFileBirthdays(list)
  return unless handle = File.new(ENV['HOME'] + '/birthdays', 'r')
  handle.each do |line|
    list.push(Birthday.newFromLine(line))
  end
  handle.close
end

def addOSXBirthdays(list)
  begin
    require 'osx/cocoa'
  rescue LoadError => e
    return
  end

  OSX.require_framework "AddressBook"

  ab = OSX::ABAddressBook.sharedAddressBook

  ab.people.to_a.each do |p|
    nameString = ""
    first = p.valueForProperty(OSX::KABFirstNameProperty).to_s
    if (!first.empty?) then
      nameString += first
    end
    nickname = p.valueForProperty(OSX::KABNicknameProperty).to_s
    if (!nickname.empty?) then
      if (!first.empty?)
        nameString += " ‘#{nickname}’"
      else
        nameString += nickname
      end
    end
    if (!nameString.empty?) then
      nameString += " "
    end
    last = p.valueForProperty(OSX::KABLastNameProperty).to_s
    if !last.empty? then
      nameString += last
    end
    company = p.valueForProperty(OSX::KABOrganizationProperty).to_s
    if !company.empty? then
      if (nameString.empty?) then
        nameString = company
      else
        # is kABPersonFlags really an int?
        if (flags = p.valueForProperty(OSX::KABPersonFlags)) and
           (flags.intValue & OSX::KABShowAsMask == OSX::KABShowAsCompany) then
          nameString = "#{company}: #{nameString}"
        else
          if nameString[-1,1] != " " then
            nameString += " "
          end
          nameString += "[#{company}]"
        end
      end
    end
    if birth = p.valueForProperty(OSX::KABBirthdayProperty) then
      #birthString = sprintf("%04u", birth.yearOfCommonEra) + "-" +
      #sprintf("%02u", birth.monthOfYear) + "-" +
      #sprintf("%02u", birth.dayOfMonth)
      b = Birthday.new(birth.yearOfCommonEra, birth.monthOfYear,
                       birth.dayOfMonth, nameString)
      list.push(b)
    end
  end
end

l = Array.new
addFlatFileBirthdays(l)
addOSXBirthdays(l)
now = Time.now
today = Birthday.new(now.year, now.month, now.day, "\x1b[1m*** TODAY ***")
l.push(today)
l.sort!

showbefore = 3
showafter = 5
todayindex = l.index(today)

# dates from the year before this year
if (showbefore - todayindex > 0) then
  (showbefore - todayindex).downto(1) do |i| 
    if (l.length - i > todayindex) then
      puts l[l.length - i].stringWithAgeIn(today.year - 1)
    end
  end
  puts "----------"
end

# all dates from this year that are before today
showbefore.downto(1) do |i|
  if (todayindex - i >= 0) then
    puts l[todayindex - i].stringWithAgeIn(today.year)
  end 
end

# reverse video TODAY
puts "\x1b[7m" + today + "\x1b[m"

# following dates this year
1.upto(showafter) do |i|
  if (todayindex + i < l.length) then
    puts l[todayindex + i].stringWithAgeIn(today.year)
  end
end

# dates next year
if (todayindex + showafter >= l.length) then
  puts "----------"
  0.upto(todayindex + showafter - l.length - 1) do |i|
    if (i < todayindex) then
      puts l[i].stringWithAgeIn(today.year + 1)
    end
  end
end

#ab.save
