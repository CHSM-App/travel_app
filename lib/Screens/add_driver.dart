import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:travel_agency_app/core/storage/constant.dart';
import 'package:travel_agency_app/core/theme/app_colors.dart';
import 'package:travel_agency_app/domain/models/drivers.dart';
import 'package:travel_agency_app/core/network/error_messages.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class AddDriverPage extends ConsumerStatefulWidget {
  final Drivers? driver;
  final bool isEdit;

  const AddDriverPage({super.key, this.driver, this.isEdit = false});

  @override
  ConsumerState<AddDriverPage> createState() => _AddDriverPageState();
}

class _AddDriverPageState extends ConsumerState<AddDriverPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final licenceNoController = TextEditingController();
  final licenceExpiryController = TextEditingController();

  DateTime? selectedExpiryDate;

  File? _selectedLicenceFile;
  String? _existingLicenceUrl;
  String? _existingLicenceRaw;
  bool _licenceRemoved = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  static const Color _primary = AppColors.brandPrimary;
  static const Color _surface = Color(0xFFF4F6FB);
  static const Color _cardBg = Colors.white;
  static const Color _textDark = Color(0xFF0D0D2B);
  static const Color _accent = Color(0xFF00BFA5);

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();

    if (widget.isEdit && widget.driver != null) {
      final d = widget.driver!;
      debugPrint('[AddDriver][init] driverId=${d.driverId}, rawDoc=${d.photo}');
      nameController.text = d.name ?? '';
      phoneController.text = d.phone ?? '';
      addressController.text = d.address ?? '';
      licenceNoController.text = d.licenceNo ?? '';
      if (d.licenceExpiry != null) {
        selectedExpiryDate = d.licenceExpiry;
        licenceExpiryController.text = _formatDate(d.licenceExpiry!);
      }
      _existingLicenceRaw = d.photo;
      _existingLicenceUrl = _normalizeDocUrl(d.photo);
      debugPrint(
        '[AddDriver][init] normalizedExistingDoc=$_existingLicenceUrl',
      );
      _selectedLicenceFile = null;
      _licenceRemoved = false;
    }

    Future.microtask(_refreshExistingLicenceDocumentFromApi);
  }

  @override
  void dispose() {
    _animController.dispose();
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    licenceNoController.dispose();
    licenceExpiryController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';

  Future<void> _selectExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedExpiryDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        selectedExpiryDate = picked;
        licenceExpiryController.text = _formatDate(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addDriverViewModelProvider);

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
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      child: Container(
                        padding: const EdgeInsets.all(20),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionLabel('Personal Info'),
                            const SizedBox(height: 14),
                            _buildField(
                              label: 'Full Name',
                              controller: nameController,
                              icon: Icons.person_rounded,
                            ),
                            const SizedBox(height: 16),
                            _buildField(
                              label: 'Phone Number',
                              controller: phoneController,
                              icon: Icons.phone_rounded,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Phone number is required';
                                }
                                if (v.length != 10) return 'Must be 10 digits';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildField(
                              label: 'Address',
                              controller: addressController,
                              icon: Icons.location_on_rounded,
                              maxLines: 3,
                            ),
                            const SizedBox(height: 24),
                            _sectionLabel('Licence Details'),
                            const SizedBox(height: 14),
                            _buildField(
                              label: 'Licence Number',
                              controller: licenceNoController,
                              icon: Icons.credit_card_rounded,
                              textCapitalization: TextCapitalization.characters,
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: _selectExpiryDate,
                              child: AbsorbPointer(
                                child: _buildField(
                                  label: 'Expiry Date',
                                  controller: licenceExpiryController,
                                  icon: Icons.calendar_month_rounded,
                                  suffixIcon: Icons.chevron_right_rounded,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildDocumentPicker(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
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
               foregroundColor: Colors.white, 
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
           child: state.isLoading
    ? const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: Colors.white,
        ),
      )
    : Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.person_rounded,   // 👈 Driver icon
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            widget.isEdit ? 'Update Driver' : 'Save Driver',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedExpiryDate == null) {
      _showSnack('Please select licence expiry date', isError: true);
      return;
    }
    if (!widget.isEdit && _selectedLicenceFile == null) {
      _showSnack('Licence document is required', isError: true);
      return;
    }
    if (widget.isEdit && _licenceRemoved && _selectedLicenceFile == null) {
      _showSnack('Please upload licence document', isError: true);
      return;
    }

    final agencyId = ref.read(loginViewModelProvider).agencyId;
    if (agencyId == null ||
        agencyId.trim().isEmpty ||
        agencyId.trim().toLowerCase() == 'null') {
      _showSnack('Agency ID is missing. Please login again.', isError: true);
      return;
    }

    final driver = Drivers(
      driverId: widget.isEdit ? widget.driver?.driverId : 0,
      name: nameController.text.trim(),
      phone: phoneController.text.trim(),
      address: addressController.text.trim(),
      licenceNo: licenceNoController.text.trim(),
      licenceExpiry: selectedExpiryDate,
      photo: (!_licenceRemoved && _selectedLicenceFile == null)
          ? _existingLicenceRaw
          : null,
      agencyId: agencyId,
    );

    try {
      debugPrint(
        '[AddDriver][submit] isEdit=${widget.isEdit}, '
        'driverId=${driver.driverId}, '
        'existingDoc=$_existingLicenceUrl, '
        'selectedFile=${_selectedLicenceFile?.path}, '
        'removed=$_licenceRemoved',
      );
      final vm = ref.read(addDriverViewModelProvider.notifier);
      int driverId;
      if (widget.isEdit) {
        driverId = driver.driverId ?? 0;
        await vm.updateDriver(driver);
      } else {
        driverId = await vm.addDriver(driver);
      }

      if (_selectedLicenceFile != null) {
        if (agencyId.trim().isEmpty ||
            agencyId.trim().toLowerCase() == 'null') {
          throw Exception('Agency ID is missing. Please login again.');
        }
        await vm.uploadDriverDocument(
          _selectedLicenceFile!,
          driverId,
          agencyId,
        );
      }

      _showSnack(
        widget.isEdit
            ? 'Driver updated successfully'
            : 'Driver added successfully',
      );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnack(friendlyErrorMessage(e), isError: true);
    }
  }

  Widget _buildHeader() => Container(
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
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: _textDark,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        Expanded(
          child: Text(
            widget.isEdit ? 'Edit Driver' : 'Add Driver',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _textDark,
            ),
          ),
        ),
        const SizedBox(width: 56),
      ],
    ),
  );

  Widget _buildDocumentPicker() {
    final bool hasNewFile = _selectedLicenceFile != null;
    final bool hasExistingDoc =
        !_licenceRemoved &&
        _existingLicenceUrl != null &&
        _existingLicenceUrl!.isNotEmpty &&
        !hasNewFile;
    final bool showEmpty = !hasNewFile && !hasExistingDoc;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Licence Document',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(width: 6),
            if (!widget.isEdit)
              Text(
                '*',
                style: TextStyle(
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
        const SizedBox(height: 8),
        if (hasExistingDoc) _buildExistingDocPreview(),
        if (hasNewFile) _buildNewFilePreview(),
        if (showEmpty) _pickerArea(),
        if (!showEmpty) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _showPickerOptions,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _primary.withOpacity(0.4),
                  width: 1.2,
                ),
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

  Widget _buildExistingDocPreview() {
    final url = _existingLicenceUrl!;
    final isPdf = _isPdfUrl(url);
    debugPrint('[AddDriver][preview] existingDoc url=$url, isPdf=$isPdf');

    return Stack(
      children: [
        GestureDetector(
          onTap: () => _openRemote(url),
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
              color: Colors.grey.shade50,
            ),
            clipBehavior: Clip.antiAlias,
            child: isPdf
                ? _docUrlErrorWidget(url)
                : Image.network(
                    url,
                    fit: BoxFit.cover,
                    headers: const {'Cache-Control': 'no-cache'},
                    errorBuilder: (_, err, stack) {
                      debugPrint(
                        '[AddDriver][preview] Image.network failed url=$url error=$err',
                      );
                      return _docUrlErrorWidget(url);
                    },
                  ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: _removeButton(
            onTap: () {
              setState(() {
                _licenceRemoved = true;
                _existingLicenceUrl = null;
                _selectedLicenceFile = null;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNewFilePreview() {
    final ext = _selectedLicenceFile!.path.split('.').last.toLowerCase();
    final isImage = ['jpg', 'jpeg', 'png', 'webp', 'heic'].contains(ext);
    final isPdf = ext == 'pdf';

    return Stack(
      children: [
        GestureDetector(
          onTap: isImage
              ? () => _openImageFullscreen(_selectedLicenceFile)
              : (isPdf ? () => _openLocal(_selectedLicenceFile!) : null),
          child: Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _primary.withOpacity(0.3), width: 1.5),
              color: _primary.withOpacity(0.03),
            ),
            clipBehavior: Clip.antiAlias,
            child: isImage
                ? Image.file(_selectedLicenceFile!, fit: BoxFit.cover)
                : _docFileWidget(ext),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: _removeButton(
            onTap: () => setState(() => _selectedLicenceFile = null),
          ),
        ),
      ],
    );
  }

  Widget _docUrlErrorWidget(String url) {
    final isPdf = _isPdfUrl(url);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPdf ? Icons.picture_as_pdf_rounded : Icons.description_rounded,
            size: 36,
            color: _primary,
          ),
          const SizedBox(height: 8),
          Text(
            isPdf ? 'Tap to Open PDF' : 'Tap to View Document',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _docFileWidget(String ext) {
    final isPdf = ext == 'pdf';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPdf
                ? Icons.picture_as_pdf_rounded
                : Icons.insert_drive_file_rounded,
            size: 36,
            color: _primary,
          ),
          const SizedBox(height: 8),
          Text(
            isPdf ? 'Tap to Open PDF' : 'Document Selected',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _removeButton({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.red.shade600,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
      ),
    );
  }

  Widget _pickerArea() => GestureDetector(
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
        color: (!widget.isEdit) ? _primary.withOpacity(0.02) : _surface,
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
            child: const Icon(
              Icons.upload_file_rounded,
              size: 28,
              color: _primary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Upload Licence Document',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textDark,
                ),
              ),
              if (!widget.isEdit) ...[
                const SizedBox(width: 4),
                Text(
                  '*',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red.shade500,
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
              'Select Licence Document',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _textDark,
              ),
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
                      _pickCamera();
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
                      _pickGallery();
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
                      _pickFile();
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
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCamera() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (file != null) {
      setState(() {
        _selectedLicenceFile = File(file.path);
        _licenceRemoved = false;
      });
    }
  }

  Future<void> _pickGallery() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file != null) {
      setState(() {
        _selectedLicenceFile = File(file.path);
        _licenceRemoved = false;
      });
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedLicenceFile = File(result.files.single.path!);
        _licenceRemoved = false;
      });
    }
  }

  Future<void> _openRemote(String url) async {
    debugPrint('[AddDriver][openRemote] url=$url');
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
        debugPrint(
          '[AddDriver][openRemote] external launch failed, trying platformDefault',
        );
        final retry = await launchUrl(uri, mode: LaunchMode.platformDefault);
        if (!retry) {
          _showSnack('Could not open PDF document', isError: true);
        }
      }
      return;
    }

    _openImageFullscreen(null, networkUrl: url);
  }

  Future<void> _openLocal(File file) async {
    final result = await OpenFile.open(file.path);
    if (result.type != ResultType.done) {
      _showSnack('Could not open PDF document', isError: true);
    }
  }

  bool _isPdfUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    final parsed = Uri.tryParse(url.trim());
    final path = (parsed?.path ?? url).toLowerCase();
    return path.endsWith('.pdf');
  }

  String? _normalizeDocUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) {
      debugPrint('[AddDriver][normalize] raw is empty');
      return null;
    }

    var cleaned = rawUrl.trim().replaceAll('\\', '/');

    if (cleaned.startsWith('http://') || cleaned.startsWith('https://')) {
      debugPrint('[AddDriver][normalize] already absolute: $cleaned');
      return cleaned;
    }

    final isFileNameOnly =
        !cleaned.contains('/') &&
        RegExp(
          r'\.(jpg|jpeg|png|webp|heic|pdf)$',
          caseSensitive: false,
        ).hasMatch(cleaned);

    final uploadIdx = cleaned.toLowerCase().indexOf('upload/');
    if (uploadIdx != -1) {
      cleaned = cleaned.substring(uploadIdx);
    } else {
      final uploadsIdx = cleaned.toLowerCase().indexOf('uploads/');
      if (uploadsIdx != -1) {
        cleaned = cleaned.substring(uploadsIdx);
      }
    }

    if (cleaned.startsWith('./')) {
      cleaned = cleaned.substring(2);
    }

    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    if (isFileNameOnly) {
      final normalized = '$base/upload/DriverDocuments/$cleaned';
      debugPrint(
        '[AddDriver][normalize] filename-only raw="$rawUrl" normalized="$normalized"',
      );
      return normalized;
    }

    if (cleaned.startsWith('/')) {
      final normalized = '$base$cleaned';
      debugPrint(
        '[AddDriver][normalize] root-path raw="$rawUrl" normalized="$normalized"',
      );
      return normalized;
    }
    final normalized = '$base/$cleaned';
    debugPrint(
      '[AddDriver][normalize] raw="$rawUrl" cleaned="$cleaned" normalized="$normalized"',
    );
    return normalized;
  }

  Future<void> _refreshExistingLicenceDocumentFromApi() async {
    if (!widget.isEdit) return;
    if (_existingLicenceUrl != null && _existingLicenceUrl!.isNotEmpty) return;

    final targetDriverId = widget.driver?.driverId;
    if (targetDriverId == null) return;

    final agencyId = ref.read(loginViewModelProvider).agencyId ?? '';
    if (agencyId.isEmpty) return;

    try {
      await ref
          .read(tripBookingViewModelProvider.notifier)
          .driverList(agencyId);
      final drivers = ref
          .read(tripBookingViewModelProvider)
          .fetchDriverList
          .asData
          ?.value;

      if (drivers == null || drivers.isEmpty) return;

      final matched = drivers.where((d) => d.driverId == targetDriverId);
      if (matched.isEmpty) return;

      final fetchedRaw = matched.first.photo;
      final fetchedNormalized = _normalizeDocUrl(fetchedRaw);

      if (!mounted) return;

      if (fetchedNormalized != null && fetchedNormalized.isNotEmpty) {
        setState(() {
          _existingLicenceRaw = fetchedRaw;
          _existingLicenceUrl = fetchedNormalized;
          _licenceRemoved = false;
        });
      }
    } catch (_) {}
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

  Widget _sectionLabel(String text) => Row(
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

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    IconData? suffixIcon,
    TextCapitalization textCapitalization = TextCapitalization.words,
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
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          validator:
              validator ??
              (v) => v == null || v.isEmpty ? 'This field is required' : null,
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            suffixIcon: suffixIcon == null ? null : Icon(suffixIcon),
            filled: true,
            fillColor: _surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : _accent,
      ),
    );
  }
}

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
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: file != null
            ? Image.file(file!, fit: BoxFit.contain)
            : Image.network(networkUrl!, fit: BoxFit.contain),
      ),
    );
  }
}
