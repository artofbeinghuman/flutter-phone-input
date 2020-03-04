import 'package:flutter_test/flutter_test.dart';
import 'package:phone_input/src/phone_input.dart';

void main() {
  test('validates phone number input value', () {
    InternationalPhoneInput.internationalizeNumber('0508232165', 'gh')
        .then((internationalizedNumber) {
      expect(internationalizedNumber, '+233508232165');
    });
  });
}
