import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vego/core/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  // ─── Palette (matches Settings screen) ─────────────────────────────
  static const Color _primary = AppColors.brandPrimary;
  static const Color _primaryLight = AppColors.brandSoft;
  static const Color _surface = Color(0xFFF6F7FF);
  static const Color _cardBg = Colors.white;
  static const Color _textDark = Color(0xFF1A1D3B);
  static const Color _textMid = Color(0xFF6B7280);
  static const Color _divider = Color(0xFFE7E9F5);

  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  _heroCard(),
                  const SizedBox(height: 18),
                  _searchBar(),
                  const SizedBox(height: 22),
                  ..._buildCategories(),
                  const SizedBox(height: 24),
                  _contactCard(),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────── HEADER ───────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: _cardBg,
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: _textDark),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Text(
              'Help Center',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _textDark,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────── HERO ───────────────────
  Widget _heroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.32),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.35)),
            ),
            child: const Icon(Icons.support_agent_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'How can we help?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Browse guides for every feature in the app.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────── SEARCH ───────────────────
  Widget _searchBar() {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _divider),
      ),
      child: TextField(
        controller: _searchCtrl,
        textCapitalization: TextCapitalization.words,
        onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _textDark,
        ),
        decoration: InputDecoration(
          hintText: 'Search FAQs and guides…',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.5),
          prefixIcon: const Icon(Icons.search_rounded,
              color: _textMid, size: 20),
          suffixIcon: _query.isEmpty
              ? null
              : GestureDetector(
                  onTap: () {
                    _searchCtrl.clear();
                    setState(() => _query = '');
                  },
                  child:
                      const Icon(Icons.cancel_rounded, color: _textMid, size: 18),
                ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
        ),
      ),
    );
  }

  // ─────────────────── CATEGORIES ───────────────────
  List<Widget> _buildCategories() {
    final categories = _faqData();
    final filtered = _query.isEmpty
        ? categories
        : categories
            .map((cat) => _HelpCategory(
                  title: cat.title,
                  icon: cat.icon,
                  faqs: cat.faqs.where((f) {
                    final q = _query;
                    return f.question.toLowerCase().contains(q) ||
                        f.answer.toLowerCase().contains(q);
                  }).toList(),
                ))
            .where((cat) => cat.faqs.isNotEmpty)
            .toList();

    if (filtered.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _divider),
          ),
          child: Column(
            children: [
              const Icon(Icons.search_off_rounded,
                  size: 36, color: _textMid),
              const SizedBox(height: 10),
              const Text('No results',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _textDark)),
              const SizedBox(height: 4),
              Text(
                'Try a different keyword, or contact us below.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: _textMid),
              ),
            ],
          ),
        ),
      ];
    }

    final widgets = <Widget>[];
    for (var i = 0; i < filtered.length; i++) {
      widgets.add(_categorySection(filtered[i]));
      if (i < filtered.length - 1) widgets.add(const SizedBox(height: 18));
    }
    return widgets;
  }

  Widget _categorySection(_HelpCategory cat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _primaryLight,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(cat.icon, size: 15, color: _primary),
              ),
              const SizedBox(width: 10),
              Text(
                cat.title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: _textMid,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: _primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${cat.faqs.length}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: _primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _divider),
          ),
          child: Column(
            children: List.generate(cat.faqs.length, (i) {
              final f = cat.faqs[i];
              return Column(
                children: [
                  _faqTile(f),
                  if (i < cat.faqs.length - 1)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: _divider,
                      indent: 16,
                      endIndent: 16,
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _faqTile(_Faq f) {
    return Theme(
      data:
          Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        childrenPadding:
            const EdgeInsets.fromLTRB(16, 0, 16, 14),
        iconColor: _primary,
        collapsedIconColor: _textMid,
        title: Text(
          f.question,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textDark,
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              f.answer,
              style: const TextStyle(
                fontSize: 13,
                color: _textMid,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────── CONTACT ───────────────────
  Widget _contactCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: _primaryLight,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.mail_outline_rounded,
                    color: _primary, size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Still need help?',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _textDark)),
                    SizedBox(height: 2),
                    Text(
                      'Our team usually replies within one business day.',
                      style: TextStyle(fontSize: 12, color: _textMid),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _contactButton(
            label: 'Email support',
            value: 'support@vengurlatech.com',
            icon: Icons.email_rounded,
            onTap: () => _launchUri(Uri(
                scheme: 'mailto',
                path: 'support@vengurlatech.com',
                query: Uri.encodeFull(
                    'subject=Help with Travel Agency App'))),
          ),
          const SizedBox(height: 10),
          _contactButton(
            label: 'View privacy policy',
            value: 'vego.vengurlatech.com/privacy',
            icon: Icons.shield_outlined,
            onTap: () => _launchUri(Uri.parse(
                'https://vego.vengurlatech.com/privacy')),
          ),
        ],
      ),
    );
  }

  Widget _contactButton({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _divider),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: _primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _textDark)),
                  Text(value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11.5, color: _textMid)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 12, color: _textMid),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUri(Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open $uri'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  // ════════════════════════════════════════════════════════════════════
  //  FAQ CONTENT — covers every feature in the app
  // ════════════════════════════════════════════════════════════════════
  List<_HelpCategory> _faqData() => const [
        _HelpCategory(
          title: 'Getting Started',
          icon: Icons.flag_rounded,
          faqs: [
            _Faq(
              'How do I create an account?',
              'Tap "Sign Up" on the login screen and fill in your name, mobile, email, '
                  'password, agency name, address and city. Accept the Terms & '
                  'Conditions (the Create Account button enables once you tick it) '
                  'and tap Create Account.',
            ),
            _Faq(
              'I forgot my password — what now?',
              'On the login screen tap "Forgot Password", enter your registered '
                  'mobile number, set a new password, and confirm. You can then '
                  'sign in with the new password right away.',
            ),
            _Faq(
              'How is my agency separated from others?',
              'Every record you create — customers, drivers, vehicles, trips — is '
                  'tagged with your unique Agency ID. You only ever see and edit '
                  'data that belongs to your agency.',
            ),
          ],
        ),
        _HelpCategory(
          title: 'Trip Bookings',
          icon: Icons.card_travel_rounded,
          faqs: [
            _Faq(
              'How do I create a new trip booking?',
              'Open the Trips tab and tap the "+" button (or use the dashboard '
                  '"New Booking" quick action). Fill in pickup/drop, distance, fuel '
                  'required, trip charges, schedule the start/end date-time, then '
                  'pick a customer, vehicle and driver. Tap Save Booking.',
            ),
            _Faq(
              'Why is the Trip Charges field showing a "Last fare" chip?',
              'When you enter a customer plus a pickup-drop combination that has '
                  'been billed before for that route, the app shows the last and '
                  'average fare from history. Tap "Use" to auto-fill the charge.',
            ),
            _Faq(
              'How does vehicle / driver availability work?',
              'After you pick a start and end date-time the form fetches only '
                  'vehicles and drivers that are NOT assigned to another trip in '
                  'that window. If a list is empty, no resources are free for those '
                  'dates — change the schedule or add a new vehicle/driver.',
            ),
            _Faq(
              'Can I book a trip in the past?',
              'No — past dates are blocked in the start/end pickers. The end date '
                  'also cannot be earlier than the chosen start date.',
            ),
            _Faq(
              'How do I edit or cancel a trip?',
              'Open the trip card from the Trips tab → three-dot menu → Edit or '
                  'Cancel. Cancelled trips move to the Cancelled tab and free up '
                  'the assigned vehicle and driver for that slot.',
            ),
            _Faq(
              'What do the tabs in the Trips page mean?',
              '"All" shows every trip. Active = currently running, Upcoming = '
                  'scheduled later, Paid = completed and fully paid, Unpaid = '
                  'completed but payment is partial or pending, Cancelled = '
                  'cancelled trips.',
            ),
            _Faq(
              'How do I mark a trip as paid?',
              'Open an unpaid trip → enter Toll / Repairing / Driver charges and '
                  'the amount received → tap "Mark Paid". When the received amount '
                  'matches the approved amount, the trip moves to the Paid tab.',
            ),
          ],
        ),
        _HelpCategory(
          title: 'Customers',
          icon: Icons.people_alt_rounded,
          faqs: [
            _Faq(
              'How do I add a new customer?',
              'Open the Customers tab and tap "Add Customer" at the bottom. Enter '
                  'name, phone and address. An ID-proof document is optional in '
                  'both add and edit. Tap Add Customer.',
            ),
            _Faq(
              'I get "A customer with this phone number already exists"',
              'The same phone number cannot be used twice within the same agency. '
                  'Search the existing customer instead, or use a different '
                  'number for the new customer.',
            ),
            _Faq(
              'Where can I see a customer\'s past trips?',
              'Tap any customer card on the Customers tab — the Customer History '
                  'page shows total trips, paid count, revenue, and every trip '
                  'they\'ve taken.',
            ),
            _Faq(
              'Can I delete a customer?',
              'Yes — tap the three-dot menu on a customer card → Delete. Deleted '
                  'customers no longer appear in the dropdown when creating new '
                  'trips, but you can review them under Settings → Deleted Records.',
            ),
          ],
        ),
        _HelpCategory(
          title: 'Vehicles & Drivers',
          icon: Icons.directions_car_rounded,
          faqs: [
            _Faq(
              'How do I add a vehicle?',
              'Vehicles tab → Vehicles sub-tab → "+ Add Vehicle". Enter name, '
                  'registration number, type, capacity, fuel type, mileage, '
                  'status, and optionally upload the RC document.',
            ),
            _Faq(
              'Where does the RC document go?',
              'It\'s stored against the vehicle and shown when you open the '
                  'vehicle details. You can replace or remove it any time by '
                  'editing the vehicle.',
            ),
            _Faq(
              'How do I add a driver?',
              'Vehicles tab → Drivers sub-tab → "+ Add Driver". Enter name, '
                  'phone, address, licence number and expiry, and (optionally) '
                  'upload the licence document.',
            ),
            _Faq(
              'How do I see a vehicle\'s or driver\'s history?',
              'Open the Vehicles or Drivers list and tap any card. The details '
                  'screen shows past trips, service records (for vehicles), and '
                  'utilisation.',
            ),
            _Faq(
              'I deleted a vehicle/driver by mistake.',
              'Open Settings → "Deleted Vehicles & Drivers" to see the list of '
                  'removed records. From there you can review or restore them '
                  '(if your version supports restore).',
            ),
            _Faq(
              'How are vehicle service records tracked?',
              'On a vehicle\'s details page, scroll to "Service Records". You '
                  'can add a service with name, cost, date and description. '
                  'Records are listed chronologically.',
            ),
          ],
        ),
        _HelpCategory(
          title: 'Documents & Uploads',
          icon: Icons.upload_file_rounded,
          faqs: [
            _Faq(
              'What document types can I upload?',
              'JPG, JPEG, PNG, WEBP, HEIC, and PDF files. The Camera option '
                  'captures a fresh photo, Gallery picks from existing images, '
                  'and Files lets you choose a PDF or scan.',
            ),
            _Faq(
              'Where are uploaded documents stored?',
              'On our servers in folders scoped to your agency and the entity '
                  'they belong to (e.g. customer / driver / vehicle / admin). '
                  'They are served over HTTPS and only visible to your agency.',
            ),
            _Faq(
              'Is uploading an ID proof required?',
              'No — ID Proof is optional for both adding and editing a customer. '
                  'You can save the customer without one and upload later.',
            ),
            _Faq(
              'A document failed to upload — what happens to the record?',
              'The customer (or driver/vehicle) itself is saved successfully. '
                  'Only the photo upload step failed; you\'ll see the exact '
                  'reason in the snackbar (network, server error, etc.) and you '
                  'can re-upload by editing the record.',
            ),
          ],
        ),
        _HelpCategory(
          title: 'Reports',
          icon: Icons.insights_rounded,
          faqs: [
            _Faq(
              'What reports can I generate?',
              'Booking, Driver, Vehicle, Customer and Revenue reports. Each tab '
                  'shows the relevant data with date filters.',
            ),
            _Faq(
              'How do I filter by date?',
              'Use the date filter at the top — All time, Today, This week, '
                  'This month, or a Custom range with explicit start and end '
                  'dates.',
            ),
            _Faq(
              'Can I export a report?',
              'Yes — pick the sections and items you want, then tap '
                  '"Generate PDF". The PDF opens in your device\'s default '
                  'reader and can be saved or shared.',
            ),
          ],
        ),
        _HelpCategory(
          title: 'Account & Security',
          icon: Icons.shield_outlined,
          faqs: [
            _Faq(
              'How do I update my profile or photo?',
              'Settings → Edit Profile. Update name, email, mobile, address, '
                  'agency name and profile picture, then save.',
            ),
            _Faq(
              'How does the app keep my session secure?',
              'You sign in once, and the app uses a short-lived access token '
                  'plus a rotated refresh token bound to the device. If the '
                  'refresh token is revoked or expires, you\'ll be returned to '
                  'the login screen automatically.',
            ),
            _Faq(
              'How do I log out?',
              'Settings → Logout. This signs you out on this device and '
                  'invalidates your refresh token on the server.',
            ),
            _Faq(
              'How do I delete my account?',
              'Settings → Delete Account. We send a one-time code to your '
                  'registered WhatsApp number to confirm it\'s you, then '
                  'permanently delete your account and all associated data '
                  '(trips, vehicles, drivers, customers, payments and reports) '
                  'within 30 days. You can also request this from '
                  'vego.vengurlatech.com/delete-account in any browser.',
            ),
            _Faq(
              'Where can I read your privacy policy?',
              'Settings → Privacy & Security, or visit '
                  'vego.vengurlatech.com/privacy in any browser.',
            ),
          ],
        ),
        _HelpCategory(
          title: 'Troubleshooting',
          icon: Icons.health_and_safety_rounded,
          faqs: [
            _Faq(
              'The app says "No internet connection"',
              'Your device is offline or our server is unreachable. The app '
                  'auto-retries when connectivity returns. If you have signal '
                  'but still see this, restart the app.',
            ),
            _Faq(
              'A list looks out of date',
              'Pull down on any list (trips, customers, vehicles, drivers) to '
                  'refresh from the server. Switching tabs also refetches.',
            ),
            _Faq(
              'I see "Server error (500)" or similar',
              'Something failed on the server side. The snackbar shows the '
                  'reason returned. Try again in a minute; if it persists, '
                  'contact support with the exact text shown.',
            ),
            _Faq(
              'A name I entered shows up truncated',
              'Long names should now save in full. If you still see a '
                  'truncated value, contact support with the original value — '
                  'we\'ll widen the affected database field.',
            ),
          ],
        ),
      ];
}

// ────────────────────────────────────────────────────────────────────
//  Data classes
// ────────────────────────────────────────────────────────────────────
class _HelpCategory {
  final String title;
  final IconData icon;
  final List<_Faq> faqs;
  const _HelpCategory({
    required this.title,
    required this.icon,
    required this.faqs,
  });
}

class _Faq {
  final String question;
  final String answer;
  const _Faq(this.question, this.answer);
}
