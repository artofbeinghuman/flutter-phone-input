import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:libphonenumber/libphonenumber.dart';

class Country {
  final String name;

  final String flagUri;

  final String code;

  final String dialCode;

  Country({this.name, this.code, this.flagUri, this.dialCode});

  @override
  String toString() {
    return {
      'name': name,
      'flagUri': flagUri,
      'code': code,
      'dialCode': dialCode
    }.toString();
  }
}

class PhoneInput extends StatefulWidget {
  final void Function(bool isValid, String internationalizedPhoneNumber)
      returnPhoneInputStatus;
  final String initialPhoneNumber;
  final String initialSelection;
  final String errorText;
  final String hintText;
  final TextStyle textStyle;
  final TextStyle errorStyle;
  final TextStyle hintStyle;
  final int errorMaxLines;
  final Function onSubmitted;
  final bool europeanCountriesOnly;

  PhoneInput({
    this.returnPhoneInputStatus,
    this.initialPhoneNumber = '',
    this.initialSelection,
    this.errorText,
    this.hintText,
    this.textStyle,
    this.errorStyle,
    this.hintStyle,
    this.errorMaxLines,
    this.onSubmitted,
    this.europeanCountriesOnly = false,
  });

  @override
  _PhoneInputState createState() => _PhoneInputState();
}

class _PhoneInputState extends State<PhoneInput> {
  Country selectedItem;
  List<Country> itemList = [];

  String errorText;
  String hintText;

  TextStyle errorStyle;
  TextStyle hintStyle;

  int errorMaxLines;

  bool hasError = false;

  _PhoneInputState();

  final phoneTextController = TextEditingController();

  @override
  void initState() {
    errorText = widget.errorText ?? 'Please enter a valid phone number';
    hintText = '  ' + widget.hintText ?? '  type here';
    errorStyle = widget.errorStyle;
    hintStyle = widget.hintStyle;
    errorMaxLines = widget.errorMaxLines;

    phoneTextController.addListener(_validatePhoneNumber);
    phoneTextController.text = widget.initialPhoneNumber;

    _fetchCountryData().then((list) {
      Country preSelectedItem;

      if (widget.initialSelection != null) {
        preSelectedItem = list.firstWhere(
            (e) =>
                (e.code.toUpperCase() ==
                    widget.initialSelection.toUpperCase()) ||
                (e.dialCode == widget.initialSelection.toString()),
            orElse: () => list[0]);
      } else {
        preSelectedItem = list[0];
      }

      setState(() {
        itemList = list;
        selectedItem = preSelectedItem;
      });
    });

    String phoneText = phoneTextController.text;
    _parsePhoneNumber(phoneText, widget.initialSelection).then((isValid) {
      _getNormalizedPhoneNumber(phoneText, selectedItem.code).then((number) {
        widget.returnPhoneInputStatus(isValid, number);
      });
    });

    super.initState();
  }

  static Future<bool> _parsePhoneNumber(String number, String iso) async {
    try {
      bool isValid = await PhoneNumberUtil.isValidPhoneNumber(
          phoneNumber: number, isoCode: iso);
      return isValid;
    } on PlatformException {
      return false;
    }
  }

  static Future<String> _getNormalizedPhoneNumber(
      String number, String iso) async {
    try {
      String normalizedNumber = await PhoneNumberUtil.normalizePhoneNumber(
          phoneNumber: number, isoCode: iso);

      return normalizedNumber;
    } catch (e) {
      print(e);
      return null;
    }
  }

  _validatePhoneNumber() {
    String phoneText = phoneTextController.text;
    if (phoneText != null && phoneText.isNotEmpty) {
      _parsePhoneNumber(phoneText, selectedItem.code).then((isValid) {
        setState(() {
          hasError = !isValid;
        });

        if (widget.returnPhoneInputStatus != null) {
          if (isValid) {
            _getNormalizedPhoneNumber(phoneText, selectedItem.code)
                .then((number) {
              widget.returnPhoneInputStatus(isValid, number);
            });
          } else {
            widget.returnPhoneInputStatus(isValid, '');
          }
        }
      });
    }
  }

  Future<List<Country>> _fetchCountryData() async {
    var list = widget.europeanCountriesOnly
        ? await DefaultAssetBundle.of(context)
            .loadString('packages/phone_input/assets/countries_europe.json')
        : await DefaultAssetBundle.of(context)
            .loadString('packages/phone_input/assets/countries.json');
    var jsonList = json.decode(list);
    List<Country> elements = [];
    jsonList.forEach((s) {
      Map elem = Map.from(s);
      elements.add(Country(
          name: elem['en_short_name'],
          code: elem['alpha_2_code'],
          dialCode: elem['dial_code'],
          flagUri: 'assets/flags/${elem['alpha_2_code'].toLowerCase()}.png'));
    });

    elements.sort(
        (countryA, countryB) => countryA.dialCode.compareTo(countryB.dialCode));

    return elements;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // height: 100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          DropdownButtonHideUnderline(
            child: Padding(
              padding: EdgeInsets.only(top: 8),
              child: DropdownButton<Country>(
                value: selectedItem,
                onChanged: (Country newValue) {
                  setState(() {
                    selectedItem = newValue;
                  });
                  _validatePhoneNumber();
                },
                items: itemList.map<DropdownMenuItem<Country>>((Country value) {
                  return DropdownMenuItem<Country>(
                    value: value,
                    child: Container(
                      padding: const EdgeInsets.only(bottom: 5.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Image.asset(
                            value.flagUri,
                            width: 32.0,
                            package: 'phone_input',
                          ),
                          SizedBox(width: 4),
                          Text(value.dialCode, style: widget.textStyle)
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          SizedBox(width: 5),
          Flexible(
              child: TextField(
            style: widget.textStyle,
            onSubmitted: widget.onSubmitted,
            keyboardType: TextInputType.phone,
            controller: phoneTextController,
            decoration: InputDecoration(
              hintText: hintText,
              errorText: hasError ? errorText : null,
              hintStyle: hintStyle ?? null,
              errorStyle: errorStyle ?? null,
              errorMaxLines: errorMaxLines ?? 3,
            ),
          ))
        ],
      ),
    );
  }
}
