import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NewTourBookingPage extends StatefulWidget {
  const NewTourBookingPage({Key? key}) : super(key: key);

  @override
  State<NewTourBookingPage> createState() => _NewTourBookingPageState();
}

class _NewTourBookingPageState extends State<NewTourBookingPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController bookingNo = TextEditingController();
  final TextEditingController customerName = TextEditingController();
  final TextEditingController contactNo = TextEditingController();
  final TextEditingController startLocation = TextEditingController();
  final TextEditingController endLocation = TextEditingController();
  final TextEditingController vehicleNo = TextEditingController();

  DateTime bookingDate = DateTime.now();
  DateTime? startDate;
  DateTime? endDate;

  bool driverRequired = false;
  bool isLoading = false;

  String formatDate(DateTime? d) =>
      d == null ? "" : DateFormat("dd-MM-yyyy").format(d);

  Future<void> pickDate(bool isStart) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: isStart ? (startDate ?? DateTime.now()) : (endDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selected != null) {
      setState(() {
        if (isStart) startDate = selected;
        else endDate = selected;
      });
    }
  }

  Future<void> submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select Start & End Dates")),
      );
      return;
    }

    setState(() => isLoading = true);

    final url = Uri.parse("https://your-api-url.com/api/bookings");

    final body = {
      "bookingDate": bookingDate.toIso8601String(),
      "bookingNo": bookingNo.text,
      "customerName": customerName.text,
      "contactNo": contactNo.text,
      "startDate": startDate!.toIso8601String(),
      "endDate": endDate!.toIso8601String(),
      "startLocation": startLocation.text,
      "destinationLocation": endLocation.text,
      "vehicleNo": vehicleNo.text,
      "driverRequired": driverRequired
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Booking Saved Successfully")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed: $e")),
      );
    }

    setState(() => isLoading = false);
  }

  InputDecoration styledInput(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Tour Booking"),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [

                  TextFormField(
                    readOnly: true,
                    decoration: styledInput("Booking Date", Icons.calendar_month),
                    initialValue: DateFormat("dd-MM-yyyy").format(bookingDate),
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: bookingNo,
                    decoration: styledInput("Booking No", Icons.confirmation_number),
                    validator: (v) => v!.isEmpty ? "Enter Booking No" : null,
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: customerName,
                    decoration: styledInput("Customer Name", Icons.person),
                    validator: (v) => v!.isEmpty ? "Enter Customer Name" : null,
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: contactNo,
                    keyboardType: TextInputType.phone,
                    decoration: styledInput("Contact No", Icons.phone),
                    validator: (v) =>
                        v!.length < 10 ? "Enter valid contact no" : null,
                  ),

                  const SizedBox(height: 12),

                  GestureDetector(
                    onTap: () => pickDate(true),
                    child: AbsorbPointer(
                      child: TextFormField(
                        decoration: styledInput("Start Date", Icons.date_range),
                        controller: TextEditingController(text: formatDate(startDate)),
                        validator: (v) =>
                            v!.isEmpty ? "Select Start Date" : null,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  GestureDetector(
                    onTap: () => pickDate(false),
                    child: AbsorbPointer(
                      child: TextFormField(
                        decoration: styledInput("End Date", Icons.event),
                        controller: TextEditingController(text: formatDate(endDate)),
                        validator: (v) =>
                            v!.isEmpty ? "Select End Date" : null,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: startLocation,
                    decoration: styledInput("Start Location", Icons.location_on),
                    validator: (v) => v!.isEmpty ? "Enter start location" : null,
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: endLocation,
                    decoration: styledInput("Destination Location", Icons.flag),
                    validator: (v) => v!.isEmpty ? "Enter destination" : null,
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: vehicleNo,
                    decoration: styledInput("Vehicle No", Icons.directions_car),
                  ),

                  CheckboxListTile(
                    title: const Text("Driver Required"),
                    value: driverRequired,
                    onChanged: (v) => setState(() => driverRequired = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),

                  const SizedBox(height: 16),

                  FilledButton.icon(
                    onPressed: isLoading ? null : submitBooking,
                    icon: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: const Text("Save Booking"),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontSize: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
