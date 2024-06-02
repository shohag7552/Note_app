import 'package:intl/intl.dart';

class DateConverter {

  static String dateTimeStringToDateOnly(String dateTime) {
    return DateFormat.yMMMd().format(DateFormat('dd-MM-yyyy HH:mm a').parse(dateTime));
  }
}

// 'dd mm yyyy HH:mm'//