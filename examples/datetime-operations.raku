#!/usr/bin/env raku

use Inline::Python3;

my $py = Inline::Python3.new;

say "=== Date and Time Operations Examples ===\n";

# Import datetime module
$py.run('from datetime import datetime, date, time, timedelta');

# Current date and time
say "1. Current date and time:";
say "datetime.now(): " ~ $py.run('datetime.now().strftime("%Y-%m-%d %H:%M:%S")', :eval);
say "date.today(): " ~ $py.run('date.today().isoformat()', :eval);
say "Current year: " ~ $py.run('datetime.now().year', :eval);
say "Current month: " ~ $py.run('datetime.now().month', :eval);
say "Current day: " ~ $py.run('datetime.now().day', :eval);
say "Current weekday: " ~ $py.run('datetime.now().strftime("%A")', :eval);

# Creating specific dates and times
say "\n2. Creating specific dates and times:";
$py.run('birthday = date(1990, 5, 15)');
say "Birthday: " ~ $py.run('birthday.strftime("%B %d, %Y")', :eval);
say "Day of week: " ~ $py.run('birthday.strftime("%A")', :eval);
say "Day of year: " ~ $py.run('birthday.strftime("%j")', :eval);

$py.run('meeting_time = time(14, 30, 0)');
say "Meeting time: " ~ $py.run('meeting_time.strftime("%I:%M %p")', :eval);

# Date arithmetic
say "\n3. Date arithmetic:";
$py.run('today = date.today()');
$py.run('one_week = timedelta(weeks=1)');
$py.run('one_month = timedelta(days=30)');
$py.run('one_year = timedelta(days=365)');

say "Today: " ~ $py.run('today.isoformat()', :eval);
say "Next week: " ~ $py.run('(today + one_week).isoformat()', :eval);
say "30 days from now: " ~ $py.run('(today + one_month).isoformat()', :eval);
say "One year ago: " ~ $py.run('(today - one_year).isoformat()', :eval);

# Time differences
say "\n4. Calculating time differences:";
$py.run('start_date = date(2024, 1, 1)');
$py.run('end_date = date(2024, 12, 31)');
$py.run('difference = end_date - start_date');
say "Days in 2024: " ~ $py.run('difference.days', :eval);

$py.run('birth_date = date(1990, 5, 15)');
$py.run('age_days = (date.today() - birth_date).days');
say "Days since birth: " ~ $py.run('age_days', :eval);
say "Approximate age in years: " ~ $py.run('age_days // 365', :eval);

# Formatting dates and times
say "\n5. Date and time formatting:";
$py.run('now = datetime.now()');
say "Default: " ~ $py.run('str(now)', :eval);
say "ISO format: " ~ $py.run('now.isoformat()', :eval);
say "Custom format 1: " ~ $py.run('now.strftime("%d/%m/%Y")', :eval);
say "Custom format 2: " ~ $py.run('now.strftime("%B %d, %Y at %I:%M %p")', :eval);
say "Custom format 3: " ~ $py.run('now.strftime("%a %b %d %H:%M:%S %Y")', :eval);

# Parsing dates
say "\n6. Parsing date strings:";
$py.run('date_string = "2024-06-15"');
$py.run('parsed_date = datetime.strptime(date_string, "%Y-%m-%d")');
say "Parsed date: " ~ $py.run('parsed_date.strftime("%B %d, %Y")', :eval);

$py.run('time_string = "14:30:45"');
$py.run('parsed_time = datetime.strptime(time_string, "%H:%M:%S")');
say "Parsed time: " ~ $py.run('parsed_time.strftime("%I:%M:%S %p")', :eval);

# Working with timestamps
say "\n7. Working with timestamps:";
$py.run('current_timestamp = datetime.now().timestamp()');
say "Current timestamp: " ~ $py.run('current_timestamp', :eval);
say "From timestamp: " ~ $py.run('datetime.fromtimestamp(current_timestamp).strftime("%Y-%m-%d %H:%M:%S")', :eval);

# Calendar operations
say "\n8. Calendar operations:";
$py.run('import calendar');
say "Is 2024 a leap year? " ~ $py.run('calendar.isleap(2024)', :eval);
say "Days in February 2024: " ~ $py.run('calendar.monthrange(2024, 2)[1]', :eval);
say "First weekday of June 2024: " ~ $py.run('calendar.weekday(2024, 6, 1)', :eval) ~ " (0=Monday)";

# Time zones (using only standard library)
say "\n9. UTC time:";
$py.run('from datetime import timezone');
$py.run('utc_now = datetime.now(timezone.utc)');
say "UTC time: " ~ $py.run('utc_now.strftime("%Y-%m-%d %H:%M:%S %Z")', :eval);
say "UTC offset: " ~ $py.run('utc_now.strftime("%z")', :eval);

# Practical examples
say "\n10. Practical date/time examples:";

# Calculate next birthday
$py.run(q:to/PYTHON/);
def next_birthday(birth_month, birth_day):
    today = date.today()
    this_year = today.year
    birthday_this_year = date(this_year, birth_month, birth_day)
    
    if birthday_this_year < today:
        return date(this_year + 1, birth_month, birth_day)
    else:
        return birthday_this_year

next_bday = next_birthday(5, 15)
days_until = (next_bday - date.today()).days
PYTHON

say "Next birthday: " ~ $py.run('next_bday.strftime("%B %d, %Y")', :eval);
say "Days until birthday: " ~ $py.run('days_until', :eval);

# Business days calculation
$py.run(q:to/PYTHON/);
def business_days_between(start, end):
    days = 0
    current = start
    while current <= end:
        if current.weekday() < 5:  # Monday = 0, Friday = 4
            days += 1
        current += timedelta(days=1)
    return days

start = date(2024, 6, 1)
end = date(2024, 6, 30)
business_days = business_days_between(start, end)
PYTHON

say "\nBusiness days in June 2024: " ~ $py.run('business_days', :eval);

say "\n=== End of Date and Time Operations Examples ===";