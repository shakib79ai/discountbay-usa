import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/api_config.dart';
import '../data/content.dart';
import '../state/saved.dart';
import '../theme/identity.dart';
import '../theme/tokens.dart';
import '../widgets/components.dart' show openExternal;
import '../widgets/shop.dart';
import 'home_screen.dart' show FaqSection;
import 'store_screen.dart';

/// Account: sign-in (on the website for now), your saves and follows, help, legal, contact, socials, FAQ.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  static Route<void> route() => MaterialPageRoute(builder: (_) => const AccountScreen());

  String _page(String path) => '${ApiConfig.siteUrl}/$path';

  @override
  Widget build(BuildContext context) {
    final saved = context.watch<SavedState>();
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + 24),
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(12, top + 8, DB.gutter, 60),
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [DB.ink, DB.inkSoft])),
            child: Row(children: [
              const BackSquare(),
              const SizedBox(width: 10),
              Text('Account', style: DB.headline(24, color: Colors.white)),
            ]),
          ),
          Transform.translate(
            offset: const Offset(0, -44),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: DB.gutter),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: DB.border),
                boxShadow: DB.cardShadow,
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Save more with a free account', style: DB.heading(16)),
                const SizedBox(height: 4),
                Text('Sync saved deals across devices and get alerts from stores you follow.',
                    style: DB.body(12.5, color: DB.body2)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: SolidButton('Sign up free', bg: DB.orange, onPressed: () => openExternal(context, _page('profile')))),
                  const SizedBox(width: 8),
                  Expanded(child: SolidButton('Log in', outline: true, onPressed: () => openExternal(context, _page('profile')))),
                ]),
              ]),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -32),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: DB.gutter),
                child: Row(children: [
                  _Stat(value: '${saved.offers.length}', label: 'Saved deals', color: DB.sale),
                  const SizedBox(width: 8),
                  _Stat(value: '${saved.stores.length}', label: 'Following', color: const Color(0xFF1D4ED8)),
                ]),
              ),
              if (saved.stores.isNotEmpty) ...[
                const SectionTitle('Stores you follow', top: 18),
                SizedBox(
                  height: 92,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: DB.gutter),
                    itemCount: saved.stores.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) {
                      final s = saved.stores[i];
                      return InkWell(
                        onTap: () => Navigator.of(context).push(StoreScreen.route(s.slug)),
                        child: SizedBox(
                          width: 70,
                          child: Column(children: [
                            StoreBadge(look: StoreLook.of(s), logoUrl: s.logoUrl, size: 56, ring: 2),
                            const SizedBox(height: 5),
                            Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: DB.body(10.5, weight: FontWeight.w700)),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
              ],
              _group(context, 'Explore', [
                (Icons.local_offer_outlined, 'Top deals', _page('top-offers')),
                (Icons.article_outlined, 'Blog & saving tips', _page('blog')),
              ]),
              _group(context, 'Company', [
                (Icons.info_outline, 'About DiscountBay', _page('about-us')),
                (Icons.help_outline, 'Help & FAQ', _page('faq')),
                (Icons.mail_outline, 'Contact us', _page('contact-us')),
                (Icons.privacy_tip_outlined, 'Privacy policy', _page('privacy-policy')),
                (Icons.gavel_outlined, 'Terms & conditions', _page('terms-and-conditions')),
              ]),
              _group(context, 'Contact', [
                (Icons.place_outlined, Content.contactAddress, 'https://maps.google.com/?q=${Uri.encodeComponent(Content.contactAddress)}'),
                (Icons.phone_outlined, Content.contactPhone, 'tel:${Content.contactPhone.replaceAll(RegExp(r'[^0-9+]'), '')}'),
                (Icons.alternate_email, Content.contactEmail, 'mailto:${Content.contactEmail}'),
              ]),
              Padding(
                padding: const EdgeInsets.fromLTRB(DB.gutter, 14, DB.gutter, 0),
                child: Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final (name, url) in Content.socials)
                    SizedBox(width: 110, child: SolidButton(name, outline: true, height: 40, onPressed: () => openExternal(context, url))),
                ]),
              ),
              const SectionTitle('Questions? We’ve got answers'),
              const FaqSection(),
              const SizedBox(height: 16),
              Center(child: Text('DiscountBay v1.1.0', style: DB.body(11, color: DB.muted))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _group(BuildContext context, String title, List<(IconData, String, String)> links) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionTitle(title, top: 18),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: DB.gutter),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: DB.border)),
        child: Column(children: [
          for (var i = 0; i < links.length; i++)
            InkWell(
              onTap: () => links[i].$3.startsWith('http') ? openExternal(context, links[i].$3) : launchUrl(Uri.parse(links[i].$3)),
              child: Container(
                constraints: const BoxConstraints(minHeight: 52),
                decoration: BoxDecoration(
                  border: i < links.length - 1 ? const Border(bottom: BorderSide(color: Color(0xFFEEF2F6))) : null,
                ),
                child: Row(children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: DB.orangeSoft, borderRadius: BorderRadius.circular(9)),
                    child: Icon(links[i].$1, size: 17, color: DB.orange),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(links[i].$2, style: DB.body(14, weight: FontWeight.w600))),
                  const Icon(Icons.chevron_right_rounded, color: DB.muted),
                ]),
              ),
            ),
        ]),
      ),
    ]);
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.color});
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: DB.border)),
          child: Column(children: [
            Text(value, style: DB.headline(20, color: color)),
            Text(label, style: DB.body(11, color: DB.muted, weight: FontWeight.w700)),
          ]),
        ),
      );
}
