import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/domain/models/fueltype.dart';
import 'package:travel_agency_app/domain/models/status.dart';
import 'package:travel_agency_app/domain/models/vehicles.dart';
import 'package:travel_agency_app/domain/models/vehicletype.dart';
import 'package:travel_agency_app/domain/viewModel/addVehicle_viewmodel.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';

class AddVehiclePage extends ConsumerStatefulWidget {
  final Vehicles? vehicle;
  final bool isEdit;

  const AddVehiclePage({
    super.key,
    this.vehicle,
    this.isEdit = false,
  });

  @override
  ConsumerState<AddVehiclePage> createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends ConsumerState<AddVehiclePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final name = TextEditingController();
  final number = TextEditingController();
  final capacity = TextEditingController();
  final mileage = TextEditingController();
  final rcDocument = TextEditingController();

  int? selectedTypeId;
  int? selectedFuelTypeId;
  int? selectedStatusId;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // Design tokens — matches VehiclePage & AddDriverPage
  static const Color _primary = Color(0xFF3D5AFE);
  static const Color _primaryDark = Color(0xFF0031CA);
  static const Color _accent = Color(0xFF00BFA5);
  static const Color _surface = Color(0xFFF4F6FB);
  static const Color _cardBg = Colors.white;
  static const Color _textDark = Color(0xFF0D0D2B);

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _animController.forward();

    if (widget.isEdit && widget.vehicle != null) {
      final v = widget.vehicle!;
      name.text = v.name ?? '';
      number.text = v.number ?? '';
      capacity.text = v.capacity?.toString() ?? '';
      mileage.text = v.mileage ?? '';
      rcDocument.text = v.rcdocuments ?? '';
      selectedTypeId = v.TypeId;
      selectedFuelTypeId = v.FuelTypeId;
      selectedStatusId = v.StatusId;
    }

    Future.microtask(() {
      final n = ref.read(addVehicleViewModelProvider.notifier);
      n.fetchVehicleFuelTypeList();
      n.fetchVehicleTypeList();
      n.fetchstatusList();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    name.dispose();
    number.dispose();
    capacity.dispose();
    mileage.dispose();
    rcDocument.dispose();
    super.dispose();
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addVehicleViewModelProvider);

    ref.listen(addVehicleViewModelProvider, (prev, next) {
      if (prev == next) return;

      if (next.error != null) {
        String err = next.error!.toLowerCase();
        if (err.contains('unique') || err.contains('duplicate')) {
          err = 'Vehicle number already exists.';
        } else if (err.contains('foreign key')) {
          err = 'Selected record is linked and cannot be modified.';
        } else if (err.contains('not null')) {
          err = 'A required field is missing.';
        } else {
          err = next.error!;
        }
        _showSnack(err, isError: true);
      }

      if (next.data != null && prev?.data != next.data) {
        _showSnack(
          widget.isEdit
              ? 'Vehicle updated successfully'
              : 'Vehicle added successfully',
        );
        Future.delayed(
          const Duration(milliseconds: 400),
          () => Navigator.pop(context, true),
        );
      }
    });

    return Scaffold(
      backgroundColor: _surface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 4),
                        _buildClassificationCard(state),
                        const SizedBox(height: 12),
                        _buildDetailsCard(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(state),
    );
  }

  // ─── HEADER ──────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: _cardBg,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          Container(
            margin: const EdgeInsets.only(left: 8),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: _textDark),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: Text(
              widget.isEdit ? 'Edit Vehicle' : 'Add Vehicle',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _textDark,
                letterSpacing: -0.4,
              ),
            ),
          ),
          const SizedBox(width: 56),
        ],
      ),
    );
  }


  // ─── CLASSIFICATION CARD (Dropdowns) ─────────────────────────────────────────
  Widget _buildClassificationCard(AddVehicleState state) {
    return _formCard(
      children: [
        _sectionLabel('Classification'),
        const SizedBox(height: 16),
        _VehicleTypeDropdown(state),
        const SizedBox(height: 16),
        _FuelTypeDropdown(state),
        const SizedBox(height: 16),
        _StatusDropdown(state),
      ],
    );
  }

  // ─── DETAILS CARD (Text inputs) ───────────────────────────────────────────────
  Widget _buildDetailsCard() {
    return _formCard(
      children: [
        _sectionLabel('Vehicle Details'),
        const SizedBox(height: 16),

        _buildField(
          controller: name,
          label: 'Vehicle Name',
          hint: 'e.g. Toyota Innova',
          icon: Icons.badge_rounded,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),

        _buildField(
          controller: number,
          label: 'Vehicle Number',
          hint: 'e.g. MH12AB1234',
          icon: Icons.pin_rounded,
          textCapitalization: TextCapitalization.characters,
          readOnly: widget.isEdit,
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _buildField(
                controller: capacity,
                label: 'Capacity',
                hint: '0',
                icon: Icons.people_rounded,
                keyboardType: TextInputType.number,
                suffix: 'Seats',
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildField(
                controller: mileage,
                label: 'Mileage',
                hint: '0.0',
                icon: Icons.speed_rounded,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                suffix: 'km/l',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _buildField(
          controller: rcDocument,
          label: 'RC Document',
          hint: 'Document number or reference',
          icon: Icons.description_rounded,
          required: false,
        ),
      ],
    );
  }

  // ─── BOTTOM BAR ───────────────────────────────────────────────────────────────
  Widget _buildBottomBar(AddVehicleState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: _cardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: state.isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            disabledBackgroundColor: _primary.withOpacity(0.45),
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
          child: state.isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.isEdit
                          ? Icons.check_circle_rounded
                          : Icons.directions_car_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.isEdit ? 'Update Vehicle' : 'Save Vehicle',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final vehicle = Vehicles(
        vehicleId: widget.isEdit ? widget.vehicle!.vehicleId : null,
        FuelTypeId: selectedFuelTypeId!,
        name: name.text.trim(),
        number: number.text.trim(),
        TypeId: selectedTypeId!,
        capacity: int.parse(capacity.text),
        mileage: mileage.text.trim(),
        StatusId: selectedStatusId!,
        rcdocuments: rcDocument.text.isEmpty ? null : rcDocument.text.trim(),
      );

      if (widget.isEdit) {
        ref.read(addVehicleViewModelProvider.notifier).updateVehicle(vehicle);
      } else {
        ref.read(addVehicleViewModelProvider.notifier).addVehicle(vehicle);
      }
    }
  }

  // ─── SHARED FORM CARD WRAPPER ─────────────────────────────────────────────────
  Widget _formCard({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  // ─── SECTION LABEL ────────────────────────────────────────────────────────────
  Widget _sectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_primary, _accent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _textDark,
          ),
        ),
      ],
    );
  }

  // ─── TEXT FIELD ───────────────────────────────────────────────────────────────
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    String? suffix,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.words,
    bool readOnly = false,
    bool required = true,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          textCapitalization: textCapitalization,
          onChanged: onChanged,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: readOnly ? Colors.grey.shade500 : _textDark,
          ),
          validator: required
              ? (v) =>
                  v == null || v.isEmpty ? 'This field is required' : null
              : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                TextStyle(color: Colors.grey.shade400, fontSize: 14),
            suffixText: suffix,
            suffixStyle: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: readOnly
                    ? Colors.grey.withOpacity(0.1)
                    : _primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  size: 18,
                  color: readOnly ? Colors.grey.shade400 : _primary),
            ),
            filled: true,
            fillColor: readOnly
                ? Colors.grey.shade50
                : _surface,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: Colors.grey.shade200, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _primary, width: 1.8),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Colors.red, width: 1.4),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Colors.red, width: 1.8),
            ),
          ),
        ),
      ],
    );
  }

  // ─── DROPDOWN DECORATION ──────────────────────────────────────────────────────
  InputDecoration _dropdownDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle:
          TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
      prefixIcon: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: _primary),
      ),
      filled: true,
      fillColor: _surface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.4),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.8),
      ),
      isDense: true,
    );
  }

  // ─── VEHICLE TYPE DROPDOWN ────────────────────────────────────────────────────
  Widget _VehicleTypeDropdown(AddVehicleState state) =>
      state.fetchVehicleTypeList.when(
        loading: () =>
            _dropdownLoading('Vehicle Type', Icons.category_rounded),
        error: (e, _) => _dropdownError('Vehicle Type',
            Icons.category_rounded, 'fetchVehicleTypeList', e),
        data: (List<VehicleType> types) {
          if (types.isEmpty) {
            return _dropdownEmpty('Vehicle Type', Icons.category_rounded);
          }
          return _styledDropdown<int>(
            label: 'Vehicle Type',
            icon: Icons.category_rounded,
            value: selectedTypeId,
            items: types
                .map((t) => DropdownMenuItem(
                      value: t.TypeId,
                      child: _dropdownItem(
                        t.Type ?? 'Unknown',
                        Icons.directions_car_rounded,
                        selected: selectedTypeId == t.TypeId,
                      ),
                    ))
                .toList(),
            selectedItemBuilder: (_) => types
                .map((t) => _selectedItemText(t.Type ?? 'Unknown'))
                .toList(),
            onChanged: (v) => setState(() => selectedTypeId = v),
            validator: (v) =>
                v == null ? 'Please select vehicle type' : null,
          );
        },
      );

  // ─── FUEL TYPE DROPDOWN ───────────────────────────────────────────────────────
  Widget _FuelTypeDropdown(AddVehicleState state) =>
      state.fetchFuelTypeList.when(
        loading: () =>
            _dropdownLoading('Fuel Type', Icons.local_gas_station_rounded),
        error: (e, _) => _dropdownError('Fuel Type',
            Icons.local_gas_station_rounded, 'fetchVehicleFuelTypeList', e),
        data: (List<Fueltype> types) {
          if (types.isEmpty) {
            return _dropdownEmpty(
                'Fuel Type', Icons.local_gas_station_rounded);
          }
          return _styledDropdown<int>(
            label: 'Fuel Type',
            icon: Icons.local_gas_station_rounded,
            value: selectedFuelTypeId,
            items: types
                .map((t) => DropdownMenuItem(
                      value: t.FuelTypeId,
                      child: _dropdownItem(
                        t.FuelType ?? 'Unknown',
                        Icons.local_gas_station_rounded,
                        selected: selectedFuelTypeId == t.FuelTypeId,
                      ),
                    ))
                .toList(),
            selectedItemBuilder: (_) => types
                .map((t) => _selectedItemText(t.FuelType ?? 'Unknown'))
                .toList(),
            onChanged: (v) => setState(() => selectedFuelTypeId = v),
            validator: (v) =>
                v == null ? 'Please select fuel type' : null,
          );
        },
      );

  // ─── STATUS DROPDOWN ──────────────────────────────────────────────────────────
  Widget _StatusDropdown(AddVehicleState state) =>
      state.fetchstatusList.when(
        loading: () =>
            _dropdownLoading('Status', Icons.info_rounded),
        error: (e, _) =>
            _dropdownError('Status', Icons.info_rounded, 'fetchstatusList', e),
        data: (List<Status> statuses) {
          if (statuses.isEmpty) {
            return _dropdownEmpty('Status', Icons.info_rounded);
          }
          return _styledDropdown<int>(
            label: 'Status',
            icon: Icons.info_rounded,
            value: selectedStatusId,
            items: statuses
                .map((s) => DropdownMenuItem(
                      value: s.StatusId,
                      child: _dropdownItem(
                        s.StatusName ?? 'Unknown',
                        _getStatusIcon(s.StatusName ?? ''),
                        color: _getStatusColor(s.StatusName ?? ''),
                        selected: selectedStatusId == s.StatusId,
                      ),
                    ))
                .toList(),
            selectedItemBuilder: (_) => statuses
                .map((s) => _selectedItemText(s.StatusName ?? 'Unknown'))
                .toList(),
            onChanged: (v) => setState(() => selectedStatusId = v),
            validator: (v) => v == null ? 'Please select status' : null,
          );
        },
      );

  // ─── SHARED DROPDOWN WIDGET ───────────────────────────────────────────────────
  Widget _styledDropdown<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required List<Widget> Function(BuildContext) selectedItemBuilder,
    required ValueChanged<T?> onChanged,
    required String? Function(T?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          selectedItemBuilder: selectedItemBuilder,
          onChanged: onChanged,
          validator: validator,
          decoration: _dropdownDecoration(label, icon),
          isExpanded: true,
          isDense: true,
          menuMaxHeight: 320,
          borderRadius: BorderRadius.circular(16),
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              size: 22, color: Colors.grey.shade500),
          dropdownColor: Colors.white,
          elevation: 8,
        ),
      ],
    );
  }

  Widget _dropdownItem(String label, IconData icon,
      {bool selected = false, Color? color}) {
    final c = color ?? _primary;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: c.withOpacity(selected ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: c),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight:
                  selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? _textDark : Colors.grey.shade700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (selected)
          Icon(Icons.check_rounded, size: 18, color: _primary),
      ],
    );
  }

  Widget _selectedItemText(String label) => Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _textDark,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      );

  // ─── DROPDOWN STATE WIDGETS ───────────────────────────────────────────────────
  Widget _dropdownLoading(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: _primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500)),
          ),
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation(_primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdownError(
      String label, IconData icon, String fetchKey, Object error) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.error_rounded,
                size: 18, color: Colors.red.shade700),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Failed to load $label',
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () {
              final n =
                  ref.read(addVehicleViewModelProvider.notifier);
              if (fetchKey == 'fetchVehicleTypeList') {
                n.fetchVehicleTypeList();
              } else if (fetchKey == 'fetchVehicleFuelTypeList') {
                n.fetchVehicleFuelTypeList();
              } else {
                n.fetchstatusList();
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              backgroundColor: Colors.red.shade100,
            ),
            child: const Text('Retry',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _dropdownEmpty(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.inbox_rounded,
                size: 18, color: Colors.amber.shade800),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('No $label available',
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.amber.shade900,
                      fontWeight: FontWeight.w600)),
              Text('Please add data first',
                  style: TextStyle(
                      fontSize: 12, color: Colors.amber.shade700)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── STATUS HELPERS ───────────────────────────────────────────────────────────
  IconData _getStatusIcon(String s) {
    switch (s.toLowerCase()) {
      case 'active':
      case 'available':
        return Icons.check_circle_rounded;
      case 'inactive':
      case 'unavailable':
        return Icons.cancel_rounded;
      case 'maintenance':
      case 'under maintenance':
        return Icons.build_circle_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  Color _getStatusColor(String s) {
    switch (s.toLowerCase()) {
      case 'active':
      case 'available':
        return const Color(0xFF00BFA5);
      case 'inactive':
      case 'unavailable':
        return Colors.red.shade500;
      case 'maintenance':
      case 'under maintenance':
        return Colors.orange.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  // ─── SNACKBAR ─────────────────────────────────────────────────────────────────
  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_rounded
                  : Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor:
            isError ? Colors.red.shade600 : _accent,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}