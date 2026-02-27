import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_file/open_file.dart';
import 'package:travel_agency_app/core/storage/constant.dart';
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

  // ── RC Document State ──
  File? _selectedRcFile;
  String? _existingRcUrl;
  String? _existingRcRaw;
  bool _rcRemoved = false;

  int? selectedTypeId;
  int? selectedFuelTypeId;
  // int? selectedStatusId;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

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

      // ── FIX: Properly set existing RC URL for image display ──
      _existingRcRaw = v.rcdocuments;
      _existingRcUrl = _normalizeRcUrl(v.rcdocuments);
      debugPrint(
        'RC raw: ${v.rcdocuments} | normalized: $_existingRcUrl | vehicleId: ${v.vehicleId}',
      );
      _rcRemoved = false;
      _selectedRcFile = null;

      selectedTypeId = v.TypeId;
      selectedFuelTypeId = v.FuelTypeId;
      // selectedStatusId = v.StatusId;
    }

    Future.microtask(() {
      final n = ref.read(addVehicleViewModelProvider.notifier);
      n.fetchVehicleFuelTypeList();
      n.fetchVehicleTypeList();
      // n.fetchstatusList();
      _refreshExistingRcDocumentFromApi();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    name.dispose();
    number.dispose();
    capacity.dispose();
    mileage.dispose();
    super.dispose();
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addVehicleViewModelProvider);

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

  // ─── SUBMIT ───────────────────────────────────────────────────────────────────
  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (selectedTypeId == null) {
      _showSnack('Please select vehicle type', isError: true);
      return;
    }
    if (selectedFuelTypeId == null) {
      _showSnack('Please select fuel type', isError: true);
      return;
    }
    // if (selectedStatusId == null) {
    //   _showSnack('Please select status', isError: true);
    //   return;
    // }
    final int? parsedCapacity = int.tryParse(capacity.text.trim());
    if (parsedCapacity == null) {
      _showSnack('Enter valid capacity', isError: true);
      return;
    }

    // ── RC Document required on ADD mode ──
    if (!widget.isEdit && _selectedRcFile == null) {
      _showSnack('RC Document is required', isError: true);
      return;
    }

    // ── RC Document required if removed and nothing new selected ──
    if (widget.isEdit && _rcRemoved && _selectedRcFile == null) {
      _showSnack('Please upload RC Document', isError: true);
      return;
    }

    final agencyId = ref.read(loginViewModelProvider).agencyId;
    if (agencyId == null || agencyId.trim().isEmpty || agencyId.trim().toLowerCase() == 'null') {
      _showSnack('Agency ID is missing. Please login again.', isError: true);
      return;
    }

    final vehicle = Vehicles(
      vehicleId: widget.isEdit ? widget.vehicle!.vehicleId : null,
      FuelTypeId: selectedFuelTypeId!,
      name: name.text.trim(),
      number: number.text.trim(),
      TypeId: selectedTypeId!,
      capacity: parsedCapacity,
      mileage: mileage.text.trim(),
      StatusId: 1,
      rcdocuments: (!_rcRemoved && _selectedRcFile == null) ? _existingRcRaw : null,
      agencyId: agencyId,
    );

    _saveVehicle(vehicle);
  }

  // ─── SAVE VEHICLE ─────────────────────────────────────────────────────────────
  Future<void> _saveVehicle(Vehicles vehicle) async {
    try {
      int vehicleId;

      if (widget.isEdit) {
        vehicleId = vehicle.vehicleId!;
        await ref
            .read(addVehicleViewModelProvider.notifier)
            .updateVehicle(vehicle);
      } else {
        vehicleId = await ref
            .read(addVehicleViewModelProvider.notifier)
            .addVehicle(vehicle);
      }

      debugPrint("Vehicle saved with ID: $vehicleId");

      // Upload RC document if selected
      final agencyId = ref.read(loginViewModelProvider).agencyId;
      if (_selectedRcFile != null) {
        if (agencyId == null ||
            agencyId.trim().isEmpty ||
            agencyId.trim().toLowerCase() == 'null') {
          throw Exception('Agency ID is missing. Please login again.');
        }
        await ref
            .read(addVehicleViewModelProvider.notifier)
            .uploadVehicleDocument(
              _selectedRcFile!,
              vehicleId,
              agencyId,
            );
      }

      await ref.read(tripBookingViewModelProvider.notifier).vehicleList(ref.read(loginViewModelProvider).agencyId?? '');

      _showSnack(widget.isEdit
          ? 'Vehicle updated successfully'
          : 'Vehicle added successfully');

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      String err = e.toString().toLowerCase();
      if (err.contains('unique') || err.contains('duplicate')) {
        err = 'Vehicle number already exists.';
      } else if (err.contains('foreign key')) {
        err = 'Selected record is linked and cannot be modified.';
      } else if (err.contains('not null')) {
        err = 'A required field is missing.';
      } else {
        err = e.toString();
      }
      _showSnack(err, isError: true);
      debugPrint("Error saving vehicle or uploading document: $e");
    }
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

  // ─── CLASSIFICATION CARD ─────────────────────────────────────────────────────
  Widget _buildClassificationCard(AddVehicleState state) {
    return _formCard(
      children: [
        _sectionLabel('Classification'),
        const SizedBox(height: 16),
        _VehicleTypeDropdown(state),
        const SizedBox(height: 16),
        _FuelTypeDropdown(state),
        const SizedBox(height: 16),
        // _StatusDropdown(state),
      ],
    );
  }

  // ─── DETAILS CARD ────────────────────────────────────────────────────────────
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
        _buildRcDocumentPicker(),
      ],
    );
  }

  // ─── RC DOCUMENT PICKER ───────────────────────────────────────────────────────
  Widget _buildRcDocumentPicker() {
    final bool hasNewFile = _selectedRcFile != null;
    final bool hasExistingDoc =
        !_rcRemoved && _existingRcUrl != null && _existingRcUrl!.isNotEmpty && !hasNewFile;
    final bool showEmpty = !hasNewFile && !hasExistingDoc;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Label Row ──
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Text(
                'RC Document',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(width: 6),
              // ── Required on Add, Optional on Edit ──
              if (!widget.isEdit)
                Text(
                  '*',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red.shade500,
                    fontWeight: FontWeight.w700,
                  ),
                )
              else
                Text(
                  '(Optional)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w400,
                  ),
                ),
            ],
          ),
        ),

        // ── Show existing image from network ──
        if (hasExistingDoc) _buildExistingDocPreview(),

        // ── Show newly selected local file ──
        if (hasNewFile) _buildNewFilePreview(),

        // ── Show picker area when nothing selected ──
        if (showEmpty) _buildPickerArea(),

        // ── Change document button ──
        if (!showEmpty) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _showPickerOptions,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                border:
                    Border.all(color: _primary.withOpacity(0.4), width: 1.2),
                borderRadius: BorderRadius.circular(10),
                color: _primary.withOpacity(0.04),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_horiz_rounded, size: 16, color: _primary),
                  const SizedBox(width: 6),
                  Text(
                    'Change Document',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Existing network image preview ──
  Widget _buildExistingDocPreview() {
    final url = _existingRcUrl!;
    final isPdf = _isPdfUrl(url);

    return Stack(
      children: [
        GestureDetector(
          onTap: () => _openDocument(url),
          child: Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200, width: 1),
              color: Colors.grey.shade50,
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (isPdf)
                  _docUrlErrorWidget(url)
                else
                  Image.network(
                    url,
                    fit: BoxFit.cover,
                    headers: const {'Cache-Control': 'no-cache'},
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation(_primary),
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Loading document...',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('RC Image load error: $error');
                      return _docUrlErrorWidget(url);
                    },
                  ),
                if (!isPdf)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.55),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.zoom_in_rounded,
                              size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text('Tap to View Image',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // ── Remove button ──
        Positioned(
          top: 8,
          right: 8,
          child: _removeButton(() {
            setState(() {
              _rcRemoved = true;
              _existingRcUrl = null;
              _selectedRcFile = null;
            });
          }),
        ),
      ],
    );
  }

  // ── Widget shown when network image fails (could be PDF or broken URL) ──
  Widget _docUrlErrorWidget(String url) {
    final isPdf = url.toLowerCase().contains('.pdf');
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPdf ? Icons.picture_as_pdf_rounded : Icons.description_rounded,
              size: 36,
              color: _primary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isPdf ? 'PDF Document' : 'Document Attached',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _textDark),
          ),
          const SizedBox(height: 4),
          Text(
            url.split('/').last,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _primary.withOpacity(0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPdf ? Icons.open_in_new_rounded : Icons.zoom_in_rounded,
                  size: 14,
                  color: _primary,
                ),
                const SizedBox(width: 6),
                Text(
                  isPdf ? 'Tap to Open PDF' : 'Tap to View',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Newly selected local file preview ──
  Widget _buildNewFilePreview() {
    final ext = _selectedRcFile!.path.split('.').last.toLowerCase();
    final isImage = ['jpg', 'jpeg', 'png', 'webp', 'heic'].contains(ext);
    final isPdf = ext == 'pdf';

    return Stack(
      children: [
        GestureDetector(
          onTap: isImage
              ? () => _openImageFullscreen(_selectedRcFile)
              : (isPdf ? () => _openLocalDocument(_selectedRcFile!) : null),
          child: Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: _primary.withOpacity(0.3), width: 1.5),
              color: _primary.withOpacity(0.03),
            ),
            clipBehavior: Clip.antiAlias,
            child: isImage
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(_selectedRcFile!, fit: BoxFit.cover),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 6, horizontal: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.55),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.zoom_in_rounded,
                                  size: 14, color: Colors.white),
                              SizedBox(width: 4),
                              Text('Tap to view',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : _docFileWidget(ext),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: _removeButton(() {
            setState(() {
              _selectedRcFile = null;
              // If edit mode and we removed existing before, stay removed
              // If we're just clearing a newly picked file, restore existing if available
              if (widget.isEdit && !_rcRemoved) {
                // Nothing to restore - just clear selection
              }
            });
          }),
        ),
      ],
    );
  }

  Widget _buildPickerArea() {
    return GestureDetector(
      onTap: _showPickerOptions,
      child: Container(
        width: double.infinity,
        height: 130,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: (!widget.isEdit)
                ? _primary.withOpacity(0.4)
                : Colors.grey.shade300,
            width: 1.5,
            style: BorderStyle.solid,
          ),
          color: (!widget.isEdit)
              ? _primary.withOpacity(0.02)
              : _surface,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.upload_file_rounded,
                  size: 28, color: _primary),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Upload RC Document',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _textDark),
                ),
                if (!widget.isEdit) ...[
                  const SizedBox(width: 4),
                  Text('*',
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.red.shade500,
                          fontWeight: FontWeight.w700)),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Camera • Gallery • File',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _removeButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.red.shade600,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child:
            const Icon(Icons.close_rounded, size: 14, color: Colors.white),
      ),
    );
  }

  Widget _docFileWidget(String ext) {
    final isPdf = ext == 'pdf';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              ext == 'pdf'
                  ? Icons.picture_as_pdf_rounded
                  : Icons.description_rounded,
              size: 32,
              color: _primary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _selectedRcFile!.path.split('/').last,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _textDark),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(ext.toUpperCase(),
              style:
                  TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          if (isPdf) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _primary.withOpacity(0.25)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.open_in_new_rounded, size: 14, color: _primary),
                  SizedBox(width: 6),
                  Text(
                    'Tap to Open PDF',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _textDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── PICKER OPTIONS ───────────────────────────────────────────────────────────
  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select RC Document',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _textDark),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _pickerOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    color: _primary,
                    onTap: () {
                      Navigator.pop(context);
                      _pickFromCamera();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _pickerOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    color: _accent,
                    onTap: () {
                      Navigator.pop(context);
                      _pickFromGallery();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _pickerOption(
                    icon: Icons.folder_open_rounded,
                    label: 'Files',
                    color: Colors.orange.shade600,
                    onTap: () {
                      Navigator.pop(context);
                      _pickFromFiles();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pickerOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromCamera() async {
    final XFile? image = await ImagePicker()
        .pickImage(source: ImageSource.camera, imageQuality: 85);
    if (image != null) setState(() => _selectedRcFile = File(image.path));
  }

  Future<void> _pickFromGallery() async {
    final XFile? image = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null) setState(() => _selectedRcFile = File(image.path));
  }

  Future<void> _pickFromFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _selectedRcFile = File(result.files.single.path!));
    }
  }

  Future<void> _openDocument(String url) async {
    if (_isPdfUrl(url)) {
      final uri = Uri.tryParse(url);
      if (uri == null) {
        _showSnack('Invalid document URL', isError: true);
        return;
      }
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        final retry = await launchUrl(uri, mode: LaunchMode.platformDefault);
        if (!retry) {
          _showSnack('Could not open PDF document', isError: true);
        }
      }
      return;
    }
    _openImageFullscreen(null, networkUrl: url);
  }

  Future<void> _openLocalDocument(File file) async {
    final result = await OpenFile.open(file.path);
    if (result.type != ResultType.done) {
      _showSnack('Could not open PDF document', isError: true);
    }
  }

  bool _isPdfUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    final parsed = Uri.tryParse(url.trim());
    final path = Uri.decodeFull((parsed?.path ?? url)).toLowerCase();
    return path.endsWith('.pdf');
  }

  String? _normalizeRcUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return null;
    var cleaned = rawUrl.trim();

    // API sometimes sends serialized list/string values like:
    // ["uploads/VehicleDocuments/doc.pdf"] or "uploads/VehicleDocuments/doc.pdf"
    if (cleaned.startsWith('[') && cleaned.endsWith(']')) {
      cleaned = cleaned.substring(1, cleaned.length - 1);
    }
    cleaned = cleaned.replaceAll('"', '').replaceAll("'", '').trim();
    if (cleaned.contains(',')) {
      cleaned = cleaned
          .split(',')
          .map((e) => e.trim())
          .firstWhere((e) => e.isNotEmpty, orElse: () => cleaned);
    }

    cleaned = Uri.decodeFull(cleaned).replaceAll('\\', '/');

    if (cleaned.startsWith('http://') || cleaned.startsWith('https://')) {
      return cleaned;
    }

    // Some APIs return only file name: "abc123.jpg"
    final isFileNameOnly =
        !cleaned.contains('/') && RegExp(r'\.(jpg|jpeg|png|webp|heic|pdf)$', caseSensitive: false).hasMatch(cleaned);

    // Some APIs return local disk paths. Keep only from uploads/ segment.
    final uploadsIdx = cleaned.toLowerCase().indexOf('uploads/');
    if (uploadsIdx != -1) {
      cleaned = cleaned.substring(uploadsIdx);
    }

    if (cleaned.startsWith('./')) {
      cleaned = cleaned.substring(2);
    }

    final base =
        baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

    if (isFileNameOnly) {
      return '$base/uploads/VehicleDocuments/$cleaned';
    }

    if (cleaned.startsWith('/')) {
      return '$base$cleaned';
    }
    return '$base/$cleaned';
  }

  Future<void> _refreshExistingRcDocumentFromApi() async {
    if (!widget.isEdit) return;
    if (_existingRcUrl != null && _existingRcUrl!.isNotEmpty) return;
    final targetVehicleId = widget.vehicle?.vehicleId;
    if (targetVehicleId == null) return;

    final agencyId = ref.read(loginViewModelProvider).agencyId ?? '';
    if (agencyId.isEmpty) return;

    try {
      await ref.read(tripBookingViewModelProvider.notifier).vehicleList(agencyId);
      final vehicles = ref
          .read(tripBookingViewModelProvider)
          .fetchVehicleList
          .asData
          ?.value;

      if (vehicles == null || vehicles.isEmpty) return;

      final matched = vehicles.where((v) => v.vehicleId == targetVehicleId);
      if (matched.isEmpty) return;

      final fetchedRaw = matched.first.rcdocuments;
      final fetchedNormalized = _normalizeRcUrl(fetchedRaw);
      debugPrint(
        'RC fallback fetch -> raw: $fetchedRaw | normalized: $fetchedNormalized | vehicleId: $targetVehicleId',
      );

      if (!mounted) return;
      if (fetchedNormalized != null && fetchedNormalized.isNotEmpty) {
        setState(() {
          _existingRcRaw = fetchedRaw;
          _existingRcUrl = fetchedNormalized;
          _rcRemoved = false;
        });
      }
    } catch (e) {
      debugPrint('RC fallback fetch failed: $e');
    }
  }

  void _openImageFullscreen(File? file, {String? networkUrl}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _FullscreenImagePage(file: file, networkUrl: networkUrl),
      ),
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

  // ─── SHARED FORM CARD ─────────────────────────────────────────────────────────
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
        Text(text,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _textDark)),
      ],
    );
  }

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
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700)),
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
                fontWeight: FontWeight.w500),
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
            fillColor: readOnly ? Colors.grey.shade50 : _surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    BorderSide(color: Colors.grey.shade200, width: 1)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: _primary, width: 1.8)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: Colors.red, width: 1.4)),
            focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: Colors.red, width: 1.8)),
          ),
        ),
      ],
    );
  }

  InputDecoration _dropdownDecoration(String label, IconData icon) {
    return InputDecoration(
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
          borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primary, width: 1.8)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1.4)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1.8)),
      isDense: true,
    );
  }

  Widget _VehicleTypeDropdown(AddVehicleState state) =>
      state.fetchVehicleTypeList.when(
        loading: () =>
            _dropdownLoading('Vehicle Type', Icons.category_rounded),
        error: (e, _) => _dropdownError(
            'Vehicle Type', Icons.category_rounded, 'fetchVehicleTypeList', e),
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
                      child: _dropdownItem(t.Type ?? 'Unknown',
                          Icons.directions_car_rounded,
                          selected: selectedTypeId == t.TypeId),
                    ))
                .toList(),
            selectedItemBuilder: (_) => types
                .map((t) => _selectedItemText(t.Type ?? 'Unknown'))
                .toList(),
            onChanged: (v) => setState(() => selectedTypeId = v),
            validator: (v) => v == null ? 'Please select vehicle type' : null,
          );
        },
      );

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
                      child: _dropdownItem(t.FuelType ?? 'Unknown',
                          Icons.local_gas_station_rounded,
                          selected: selectedFuelTypeId == t.FuelTypeId),
                    ))
                .toList(),
            selectedItemBuilder: (_) => types
                .map((t) => _selectedItemText(t.FuelType ?? 'Unknown'))
                .toList(),
            onChanged: (v) => setState(() => selectedFuelTypeId = v),
            validator: (v) => v == null ? 'Please select fuel type' : null,
          );
        },
      );

  // Widget _StatusDropdown(AddVehicleState state) =>
  //     state.fetchstatusList.when(
  //       loading: () => _dropdownLoading('Status', Icons.info_rounded),
  //       error: (e, _) => _dropdownError(
  //           'Status', Icons.info_rounded, 'fetchstatusList', e),
  //       data: (List<Status> statuses) {
  //         if (statuses.isEmpty) {
  //           return _dropdownEmpty('Status', Icons.info_rounded);
  //         }
  //         return _styledDropdown<int>(
  //           label: 'Status',
  //           icon: Icons.info_rounded,
  //           value: selectedStatusId,
  //           items: statuses
  //               .map((s) => DropdownMenuItem(
  //                     value: s.StatusId,
  //                     child: _dropdownItem(
  //                         s.StatusName ?? 'Unknown',
  //                         _getStatusIcon(s.StatusName ?? ''),
  //                         color: _getStatusColor(s.StatusName ?? ''),
  //                         selected: selectedStatusId == s.StatusId),
  //                   ))
  //               .toList(),
  //           selectedItemBuilder: (_) => statuses
  //               .map((s) => _selectedItemText(s.StatusName ?? 'Unknown'))
  //               .toList(),
  //           onChanged: (v) => setState(() => selectedStatusId = v),
  //           validator: (v) => v == null ? 'Please select status' : null,
  //         );
  //       },
  //     );

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
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700)),
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
          child: Text(label,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? _textDark : Colors.grey.shade700),
              overflow: TextOverflow.ellipsis),
        ),
        if (selected) Icon(Icons.check_rounded, size: 18, color: _primary),
      ],
    );
  }

  Widget _selectedItemText(String label) => Align(
        alignment: Alignment.centerLeft,
        child: Text(label,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _textDark),
            overflow: TextOverflow.ellipsis),
      );

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
                valueColor: AlwaysStoppedAnimation(_primary)),
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
                borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.error_rounded,
                size: 18, color: Colors.red.shade700),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text('Failed to load $label',
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () {
              final n = ref.read(addVehicleViewModelProvider.notifier);
              if (fetchKey == 'fetchVehicleTypeList') {
                n.fetchVehicleTypeList();
              } else if (fetchKey == 'fetchVehicleFuelTypeList') {
                n.fetchVehicleFuelTypeList();
              } else {
                // n.fetchstatusList();
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
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                borderRadius: BorderRadius.circular(10)),
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

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_rounded : Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : _accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// ─── FULLSCREEN IMAGE PAGE ────────────────────────────────────────────────────
class _FullscreenImagePage extends StatelessWidget {
  final File? file;
  final String? networkUrl;

  const _FullscreenImagePage({this.file, this.networkUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('RC Document',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5.0,
          child: file != null
              ? Image.file(file!, fit: BoxFit.contain)
              : Image.network(
                  networkUrl!,
                  fit: BoxFit.contain,
                  headers: const {'Cache-Control': 'no-cache'},
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : const Center(
                          child: CircularProgressIndicator(
                              color: Colors.white)),
                  errorBuilder: (_, __, ___) => const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image_rounded,
                            size: 64, color: Colors.white38),
                        SizedBox(height: 12),
                        Text('Failed to load image',
                            style: TextStyle(color: Colors.white60)),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
