import 'package:flutter/material.dart';
import 'package:travel_agency_app/core/theme/app_colors.dart';

/// Terms & Conditions shown from the Sign Up page.
///
/// These are app-specific terms intended to protect the operator (VEGO /
/// VengurlaTech) by clearly stating that the app is provided as a record-keeping
/// tool, that the user is responsible for the data they enter, and that the
/// operator is not liable for business losses, data inaccuracies or misuse.
class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  static const _lastUpdated = "Last updated: 17 June 2026";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.brandHeader,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Terms & Conditions",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _lastUpdated,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
            const _Intro(
              "Welcome to VEGO. We've written these terms in plain, simple "
              "language so there's nothing to worry about — just a clear "
              "understanding of how we work together. VEGO (\"the App\") is built "
              "and cared for by VengurlaTech to make running your travel business "
              "easier. By creating an account, you're simply agreeing to use the "
              "App fairly, and we're committing to support you honestly.",
            ),

            _Section(
              number: "1",
              title: "A Simple Agreement",
              body:
                  "By creating an account and using the App, you're agreeing to "
                  "these friendly terms and to our Privacy Policy. There are no "
                  "hidden clauses or surprises here — if anything is ever "
                  "unclear, just reach out and we'll happily explain.",
            ),
            _Section(
              number: "2",
              title: "What VEGO Does for You",
              body:
                  "VEGO is your record-keeping and management companion for your "
                  "travel and transport business. It helps you keep customers, "
                  "drivers, vehicles, trips and transactions neatly organised in "
                  "one place. VEGO is a tool that supports your business — the "
                  "bookings and agreements you make with your customers and drivers "
                  "always remain yours, between you and them.",
            ),
            _Section(
              number: "3",
              title: "Your Account",
              body:
                  "To use the App you should be 18 or older. Please keep your "
                  "mobile number and PIN private, just as you would your house "
                  "keys — it keeps your business records safe. If you ever feel "
                  "someone else has accessed your account, let us know and we'll "
                  "help you secure it right away.",
            ),
            _Section(
              number: "4",
              title: "Your Data Stays Yours",
              body:
                  "Everything you enter into VEGO — your customers, drivers, "
                  "vehicles, trips and financial records — belongs to you. We "
                  "simply store and organise it so you can use it whenever you "
                  "need. Because you know your business best, you're the one who "
                  "decides what to record, and we trust you to enter information "
                  "you have the right to keep.",
            ),
            _Section(
              number: "5",
              title: "Using VEGO Fairly",
              body:
                  "We only ask that you use VEGO honestly — for genuine "
                  "business records, and not for anything unlawful or to disrupt "
                  "the App for others. As long as you use it in good faith, you "
                  "have nothing to worry about. This simply helps us keep VEGO safe "
                  "and pleasant for everyone.",
            ),
            _Section(
              number: "6",
              title: "Keeping VEGO Running & Your Backups",
              body:
                  "We work hard to keep VEGO fast, reliable and always available "
                  "to you. Occasionally we may pause briefly for updates and "
                  "improvements, or be affected by things outside our control like "
                  "internet outages. To give you complete peace of mind, we gently "
                  "encourage you to keep your own backup of important records too.",
            ),
            _Section(
              number: "7",
              title: "A Fair Note on Responsibility",
              body:
                  "We pour a lot of care into VEGO, and we want it to serve you "
                  "well. At the same time, like any software, we can't promise it "
                  "will be perfect at every moment, so VEGO is provided on an "
                  "\"as is\" basis. Where the law allows, VengurlaTech isn't liable "
                  "for indirect business losses that may arise from using or being "
                  "unable to use the App. This is standard and simply keeps things "
                  "fair for both of us — it doesn't take away any rights you "
                  "have under the law.",
            ),
            _Section(
              number: "8",
              title: "Looking Out for Each Other",
              body:
                  "If a problem ever arises because of how the App was used or the "
                  "information entered into it, you agree to support VengurlaTech "
                  "in resolving any related claims. In short: each of us takes "
                  "responsibility for our own part, which is what keeps a good "
                  "partnership healthy.",
            ),
            _Section(
              number: "9",
              title: "The App's Design & Branding",
              body:
                  "The VEGO name, design and software are lovingly created by "
                  "VengurlaTech and remain ours. You're warmly welcome to use the "
                  "App for your own business for as long as you like — we just "
                  "ask that it isn't copied, resold or rebuilt as another product.",
            ),
            _Section(
              number: "10",
              title: "You're Free to Leave Anytime",
              body:
                  "There's no lock-in. You're free to stop using VEGO whenever you "
                  "wish. We'd only ever pause an account in the rare case of misuse "
                  "or a serious breach of these terms — and even then, we'd aim "
                  "to talk it through with you first.",
            ),
            _Section(
              number: "11",
              title: "If These Terms Change",
              body:
                  "As VEGO grows and improves, we may update these terms now and "
                  "then. When we do, we'll keep them just as clear and fair, and "
                  "continuing to use the App means you're comfortable with the "
                  "updates.",
            ),
            _Section(
              number: "12",
              title: "Friendly Legal Footing",
              body:
                  "These terms follow the laws of India, and anything that ever "
                  "needs sorting out would be handled by the courts of Maharashtra, "
                  "India. We genuinely hope it never comes to that — we'd much "
                  "rather solve things with a simple conversation.",
            ),
            _Section(
              number: "13",
              title: "We're Here to Help",
              body:
                  "Have a question, a worry or an idea? We'd love to hear from "
                  "you. Reach us anytime at support@vengurlatech.com — a real "
                  "person will be glad to help.",
            ),

            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.brandSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                "Thank you for taking the time to read this. By creating an "
                "account, you're simply agreeing to these fair and friendly "
                "terms — and we're looking forward to helping your business "
                "run smoothly.",
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  final String text;
  const _Intro(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          height: 1.6,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String number;
  final String title;
  final String body;

  const _Section({
    required this.number,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
