import 'package:intl/intl.dart';

String mealLabel(String meal) => switch (meal) {
      'breakfast' => 'Breakfast',
      'lunch' => 'Lunch',
      'dinner' => 'Dinner',
      'snack' => 'Snack',
      'post_workout' => 'After workout',
      _ => meal,
    };

/// A sensible meal for now; the web always starts at lunch.
String mealForTime(DateTime now) => switch (now.hour) {
      < 11 => 'breakfast',
      < 16 => 'lunch',
      < 22 => 'dinner',
      _ => 'snack',
    };

String categoryLabel(String category) => switch (category) {
      'grains' => 'Grains',
      'proteins' => 'Proteins',
      'vegetables' => 'Vegetables',
      'fruits' => 'Fruits',
      'dairy' => 'Dairy',
      'fats_oils' => 'Fats & oils',
      'beverages' => 'Drinks',
      'snacks' => 'Snacks',
      _ => category,
    };

final _num = NumberFormat('#,##0.#', 'en_KE');
final _int = NumberFormat('#,##0', 'en_KE');

String formatGrams(double g) => '${_num.format(g)} g';

String formatKcal(double kcal) => '${_int.format(kcal.round())} kcal';

String formatMacro(double g) => '${_num.format(g)} g';
