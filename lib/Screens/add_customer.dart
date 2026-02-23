import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:travel_agency_app/core/storage/constant.dart';
import 'package:travel_agency_app/domain/models/customers.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';
import 'package:url_launcher/url_launcher.dart';

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

class _AddCustomerPageState extends ConsumerState<AddCustomerPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final name = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();

  File? _selectedIdProofFile;
  String? _existingIdProofUrl;
  bool _idProofRemoved = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  static const Color _primary = Color(0xFF3D5AFE);
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

    if (widget.isEdit && widget.customer != null) {
      final c = widget.customer!;
      name.text = c.name ?? '';
      phone.text = c.phone ?? '';
      address.text = c.address ?? '';
      _existingIdProofUrl = _normalizeDocUrl(c.documents);
      _selectedIdProofFile = null;
      _idProofRemoved = false;
    }

    Future.microtask(_refreshExistingIdProofFromApi);
  }

  @override
  void dispose() {
    _animController.dispose();
    name.dispose();
    phone.dispose();
    address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerViewModelProvider);

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
                            _sectionLabel('Customer Information'),
                            const SizedBox(height: 14),
                            _buildField(
                              label: 'Full Name',
                              controller: name,
                              icon: Icons.person_rounded,
                            ),
                            const SizedBox(height: 16),
                            _buildField(
                              label: 'Phone Number',
                              controller: phone,
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
                              controller: address,
                              icon: Icons.location_on_rounded,
                              maxLines: 3,
                            ),
                            const SizedBox(height: 20),
                            _sectionLabel('ID Proof'),
                            const SizedBox(height: 12),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: state.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  )
                : Text(widget.isEdit ? 'Update Customer' : 'Save Customer'),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final hasExisting = !_idProofRemoved &&
        _existingIdProofUrl != null &&
        _existingIdProofUrl!.isNotEmpty;
    if (_selectedIdProofFile == null && !hasExisting) {
      _showSnack('ID Proof upload is required', isError: true);
      return;
    }

    final agencyId = ref.read(loginViewModelProvider).agencyId;
    if (agencyId == null ||
        agencyId.trim().isEmpty ||
        agencyId.trim().toLowerCase() == 'null') {
      _showSnack('Agency ID is missing. Please login again.', isError: true);
      return;
    }

    final customer = Customer(
      customerId: widget.isEdit ? widget.customer?.customerId : 0,
      name: name.text.trim(),
      phone: phone.text.trim(),
      address: address.text.trim(),
      documents: (!_idProofRemoved && _selectedIdProofFile == null)
          ? _existingIdProofUrl
          : null,
      agencyId: agencyId,
    );

    try {
      final vm = ref.read(customerViewModelProvider.notifier);
      int customerId;
      if (widget.isEdit) {
        customerId = customer.customerId ?? 0;
        await vm.updateCustomer(customer);
      } else {
        customerId = await vm.addcustomer(customer);
      }

      if (_selectedIdProofFile != null) {
        if (agencyId.trim().isEmpty || agencyId.trim().toLowerCase() == 'null') {
          throw Exception('Agency ID is missing. Please login again.');
        }
        await vm.uploadCustomerDocument(
          _selectedIdProofFile!,
          customerId,
          agencyId,
        );
      }

      _showSnack(widget.isEdit
          ? 'Customer updated successfully'
          : 'Customer added successfully');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnack(e.toString(), isError: true);
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
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: _textDark),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: Text(
                widget.isEdit ? 'Edit Customer' : 'Add Customer',
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
    final bool hasNewFile = _selectedIdProofFile != null;
    final bool hasExistingDoc = !_idProofRemoved &&
        _existingIdProofUrl != null &&
        _existingIdProofUrl!.isNotEmpty &&
        !hasNewFile;
    final bool showEmpty = !hasNewFile && !hasExistingDoc;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('ID Proof Document',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700)),
            const SizedBox(width: 6),
            if (!widget.isEdit)
              Text('*',
                  style: TextStyle(
                      color: Colors.red.shade500, fontWeight: FontWeight.w700))
            else
              Text(
                '(Optional)',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w400),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (hasExistingDoc) _buildExistingDocPreview(),
        if (hasNewFile) _buildNewFilePreview(),
        if (showEmpty) _buildPickerArea(),
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

  Widget _buildExistingDocPreview() {
    final url = _existingIdProofUrl!;
    final isPdf = _isPdfUrl(url);
    debugPrint('[AddCustomer][preview] existingDoc url=$url, isPdf=$isPdf');

    return Stack(
      children: [
        GestureDetector(
          onTap: () => _openRemote(url),
          child: Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200, width: 1),
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
                        '[AddCustomer][preview] Image.network failed url=$url error=$err',
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
                _idProofRemoved = true;
                _existingIdProofUrl = null;
                _selectedIdProofFile = null;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNewFilePreview() {
    final ext = _selectedIdProofFile!.path.split('.').last.toLowerCase();
    final isImage = ['jpg', 'jpeg', 'png', 'webp', 'heic'].contains(ext);
    final isPdf = ext == 'pdf';

    return Stack(
      children: [
        GestureDetector(
          onTap: isImage
              ? () => _openImageFullscreen(_selectedIdProofFile)
              : (isPdf ? () => _openLocal(_selectedIdProofFile!) : null),
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
                ? Image.file(_selectedIdProofFile!, fit: BoxFit.cover)
                : _docFileWidget(ext),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: _removeButton(
            onTap: () => setState(() => _selectedIdProofFile = null),
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
                fontSize: 12, fontWeight: FontWeight.w600, color: _textDark),
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
            isPdf ? Icons.picture_as_pdf_rounded : Icons.insert_drive_file_rounded,
            size: 36,
            color: _primary,
          ),
          const SizedBox(height: 8),
          Text(
            isPdf ? 'Tap to Open PDF' : 'Document Selected',
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: _textDark),
          ),
        ],
      ),
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
              child: const Icon(Icons.upload_file_rounded,
                  size: 28, color: _primary),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Upload ID Proof',
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
              'Select ID Proof',
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
            Text(label,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCamera() async {
    final file = await ImagePicker()
        .pickImage(source: ImageSource.camera, imageQuality: 85);
    if (file != null) {
      setState(() {
        _selectedIdProofFile = File(file.path);
        _idProofRemoved = false;
      });
    }
  }

  Future<void> _pickGallery() async {
    final file = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file != null) {
      setState(() {
        _selectedIdProofFile = File(file.path);
        _idProofRemoved = false;
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
        _selectedIdProofFile = File(result.files.single.path!);
        _idProofRemoved = false;
      });
    }
  }

  Future<void> _openRemote(String url) async {
    debugPrint('[AddCustomer][openRemote] url=$url');
    if (_isPdfUrl(url)) {
      final uri = Uri.tryParse(url);
      if (uri == null) {
        _showSnack('Invalid document URL', isError: true);
        return;
      }
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        debugPrint(
          '[AddCustomer][openRemote] external launch failed, trying platformDefault',
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
    if (rawUrl == null || rawUrl.trim().isEmpty) return null;

    var cleaned = rawUrl.trim().replaceAll('\\', '/');
    if (cleaned.startsWith('http://') || cleaned.startsWith('https://')) {
      return cleaned;
    }

    final isFileNameOnly = !cleaned.contains('/') &&
        RegExp(r'\.(jpg|jpeg|png|webp|heic|pdf)$', caseSensitive: false)
            .hasMatch(cleaned);

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

    final base =
        baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

    if (isFileNameOnly) return '$base/upload/CustomerDocuments/$cleaned';
    if (cleaned.startsWith('/')) return '$base$cleaned';
    return '$base/$cleaned';
  }

  Future<void> _refreshExistingIdProofFromApi() async {
    if (!widget.isEdit) return;
    if (_existingIdProofUrl != null && _existingIdProofUrl!.isNotEmpty) return;

    final customerId = widget.customer?.customerId;
    if (customerId == null) return;

    final agencyId = ref.read(loginViewModelProvider).agencyId ?? '';
    if (agencyId.isEmpty) return;

    try {
      await ref.read(customerViewModelProvider.notifier).fetchCustomerslist(agencyId);
      final customers =
          ref.read(customerViewModelProvider).CustomerList.asData?.value;

      if (customers == null || customers.isEmpty) return;
      final matched = customers.where((c) => c.customerId == customerId);
      if (matched.isEmpty) return;

      final fetched = _normalizeDocUrl(matched.first.documents);
      if (!mounted) return;
      if (fetched != null && fetched.isNotEmpty) {
        setState(() {
          _existingIdProofUrl = fetched;
          _idProofRemoved = false;
        });
      }
    } catch (_) {}
  }

  void _openImageFullscreen(File? file, {String? networkUrl}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullscreenImagePage(file: file, networkUrl: networkUrl),
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
          Text(text,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: _textDark)),
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
    TextCapitalization textCapitalization = TextCapitalization.words,
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
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          validator: validator ??
              (v) => v == null || v.isEmpty ? 'This field is required' : null,
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
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
