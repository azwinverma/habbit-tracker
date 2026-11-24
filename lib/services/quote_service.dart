import 'dart:math';


class QuoteService {
static const List<String> _quotes = [
'Small steps every day lead to big results.',
'Discipline beats motivation.',
'You are what you repeatedly do.',
'Start where you are. Use what you have. Do what you can.',
'Focus on progress, not perfection.',
'Your future is created by what you do today.',
'Consistency is a superpower.',
'One day or day one — you decide.',
'Winners are made from habits.',
'Make it simple. Make it happen.',
];


static String quoteForDate(DateTime date) {
// Same quote for the whole day; changes next day.
final seed = date.year * 10000 + date.month * 100 + date.day;
final rng = Random(seed);
return _quotes[rng.nextInt(_quotes.length)];
}
}