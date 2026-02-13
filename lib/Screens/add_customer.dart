import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/domain/models/customers.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';

class AddCustomerPage extends ConsumerStatefulWidget {
  final bool isEdit;
  final Customer? customer; 

  const AddCustomerPage({
    super.key,
    this.isEdit = false,
    this.customer,
  });
  


  @override
  ConsumerState<AddCustomerPage> createState() => _AddCustomerPageState();
}

class _AddCustomerPageState extends ConsumerState<AddCustomerPage> {
  final _formKey = GlobalKey<FormState>();

  final name = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final licenceNo = TextEditingController();
  final address = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // You can now use ref.watch() or ref.read() here

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.indigo.shade600,
        foregroundColor: Colors.white,
        title: Text(
          widget.isEdit ? "Edit Customer" : "Add Customer",
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// Header
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: widget.isEdit
                          ? [Colors.blue.shade600, Colors.blue.shade400]
                          : [Colors.indigo.shade600, Colors.indigo.shade400],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.isEdit
                            ? Icons.edit
                            : Icons.person_add_alt_1,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.isEdit
                              ? "Update Customer Information"
                              : "Customer Registration Form",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                /// Form Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      _sectionHeader("Customer Information"),
                      const SizedBox(height: 12),

                      _compactInput(
                        name,
                        "Full Name",
                        Icons.person_outline,
                      ),
                      const SizedBox(height: 12),

                      _compactInput(
                        phone,
                        "Phone Number",
                        Icons.phone_outlined,
                        number: true,
                      ),
                      const SizedBox(height: 12),

                      _compactInput(
                        address,
                        "Address",
                        Icons.location_on_outlined,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
  if (_formKey.currentState!.validate()) {
    try {
      final newId = await ref
          .read(customerViewModelProvider.notifier)
          .addCustomer(
            Customer(
              customerId: widget.isEdit
                  ? widget.customer?.customerId ?? 0
                  : 0,
              name: name.text,
              phone: phone.text,
              address: address.text,
              

            ),
          );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEdit
                ? "Customer Updated Successfully"
                : "Customer Added Successfully",
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, newId);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
},


                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isEdit
                          ? Colors.blue.shade600
                          : Colors.indigo.shade600,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.isEdit
                              ? Icons.save_rounded
                              : Icons.add_circle_outline,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.isEdit
                              ? "Update Customer"
                              : "Add Customer",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: widget.isEdit
            ? Colors.blue.shade700
            : Colors.indigo.shade700,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _compactInput(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool number = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: number ? TextInputType.number : null,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 14),
        prefixIcon:
            Icon(icon, color: Colors.indigo.shade600, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: Colors.indigo.shade600, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
      ),
      validator: (v) =>
          v == null || v.isEmpty ? "Required" : null,
    );
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    email.dispose();
    licenceNo.dispose();
    address.dispose();
    super.dispose();
  }
}
