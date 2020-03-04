//library phone_input;

import 'dart:async';
import 'dart:convert';

import 'package:phone_input/src/phone_service.dart';

import 'country.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PhoneInput extends StatefulWidget {
  final void Function(String phoneNumber, String internationalizedPhoneNumber,
      String isoCode) onPhoneNumberChange;
  final String initialPhoneNumber;
  final String initialSelection;
  final String errorText;
  final String hintText;
  final TextStyle errorStyle;
  final TextStyle hintStyle;
  final int errorMaxLines;
  final Function onSubmitted;
  final bool europeanCountriesOnly;

  PhoneInput({
    this.onPhoneNumberChange,
    this.initialPhoneNumber,
    this.initialSelection,
    this.errorText,
    this.hintText,
    this.errorStyle,
    this.hintStyle,
    this.errorMaxLines,
    this.onSubmitted,
    this.europeanCountriesOnly = false,
  });

  static Future<String> internationalizeNumber(String number, String iso) {
    return PhoneService.getNormalizedPhoneNumber(number, iso);
  }

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
    hintText = widget.hintText ?? 'eg. 244056345';
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

    super.initState();
  }

  _validatePhoneNumber() {
    String phoneText = phoneTextController.text;
    if (phoneText != null && phoneText.isNotEmpty) {
      PhoneService.parsePhoneNumber(phoneText, selectedItem.code)
          .then((isValid) {
        setState(() {
          hasError = !isValid;
        });

        if (widget.onPhoneNumberChange != null) {
          if (isValid) {
            PhoneService.getNormalizedPhoneNumber(phoneText, selectedItem.code)
                .then((number) {
              widget.onPhoneNumberChange(phoneText, number, selectedItem.code);
            });
          } else {
            widget.onPhoneNumberChange('', '', selectedItem.code);
          }
        }
      });
    }
  }

  Future<List<Country>> _fetchCountryData() async {
    var list = widget.europeanCountriesOnly
        ? await DefaultAssetBundle.of(context)
            .loadString('packages/phone_input/assets/countries.json')
        : await DefaultAssetBundle.of(context)
            .loadString('packages/phone_input/assets/countries_europe.json');
    var jsonList = json.decode(list);
    // jsonList.sort(
    //     (a, b) => Map.from(a)['dial_code'].compareTo(Map.from(b)['dial_code']));
    List<Country> elements = [];
    jsonList.forEach((s) {
      Map elem = Map.from(s);
      elements.add(Country(
          name: elem['en_short_name'],
          code: elem['alpha_2_code'],
          dialCode: elem['dial_code'],
          flagUri: 'assets/flags/${elem['alpha_2_code'].toLowerCase()}.png'));
    });
    return elements;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
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
                            'assets/logo.png',
                            // value.flagUri,
                            width: 32.0,
                            // package: 'phone_input',
                          ),
                          SizedBox(width: 4),
                          Text(value.dialCode)
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Flexible(
              child: TextField(
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
