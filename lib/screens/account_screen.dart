import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/api_config.dart';
import '../data/content.dart';
import '../theme/tokens.dart';
import '../widgets/brand_logo.dart';
import '../widgets/components.dart';
import '../widgets/decor.dart';
import 'home_screen.dart' show FaqSection;

/// Account & info: sign-in (on the web for now), help, legal, contact and socials.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  static Route<void> route() => MaterialPageRoute(builder: (_) => const AccountScreen());

  String _page(String path) => '${ApiConfig.siteUrl}/$path';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ACCOUNT', style: DB.display(24)),
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: DashedLine(color: DB.lineOnInk)),
      ),
      body: ListView(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + 24),
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 24, bottom: 4),
            child: Center(child: BrandLogo.full(height: 120, onDark: true)),
          ),
          Padding(
            padding: const EdgeInsets.all(DB.gutter),
            child: ClipPath(
              clipper: TicketClipper(notchY: 96),
              child: Container(
                color: DB.paper,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 62,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SAVE MORE WITH AN ACCOUNT', style: DB.display(20, color: DB.ink)),
                          const SizedBox(height: 4),
                          Text('Sync saved codes across devices and get store alerts.',
                              style: DB.body(13, color: DB.ink.withValues(alpha: 0.7))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const DashedLine(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: PillButton('Sign up free',
                              style: PillStyle.coral,
                              expand: true,
                              onPressed: () => openExternal(context, _page('profile'))),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: PillButton('Log in',
                              style: PillStyle.outlineInk,
                              expand: true,
                              onPressed: () => openExternal(context, _page('profile'))),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          _group('Explore', [
            _link(context, Icons.local_offer_outlined, 'Top offers', _page('top-offers')),
            _link(context, Icons.article_outlined, 'Blog', _page('blog')),
          ]),
          _group('Company', [
            _link(context, Icons.info_outline, 'About us', _page('about-us')),
            _link(context, Icons.help_outline, 'Help & FAQ', _page('faq')),
            _link(context, Icons.mail_outline, 'Contact us', _page('contact-us')),
            _link(context, Icons.privacy_tip_outlined, 'Privacy policy', _page('privacy-policy')),
            _link(context, Icons.gavel_outlined, 'Terms & conditions', _page('terms-and-conditions')),
          ]),
          _group('Contact', [
            _link(context, Icons.place_outlined, Content.contactAddress,
                'https://maps.google.com/?q=${Uri.encodeComponent(Content.contactAddress)}'),
            _link(context, Icons.phone_outlined, Content.contactPhone,
                'tel:${Content.contactPhone.replaceAll(RegExp(r'[^0-9+]'), '')}'),
            _link(context, Icons.alternate_email, Content.contactEmail, 'mailto:${Content.contactEmail}'),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(DB.gutter, 18, DB.gutter, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (name, url) in Content.socials)
                  PillButton(name, style: PillStyle.outlinePaper, dense: true, onPressed: () => openExternal(context, url)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const FaqSection(),
          Center(
            child: Text('DiscountBay v1.0.0', style: DB.mono(10, color: DB.paper.withValues(alpha: 0.4))),
          ),
        ],
      ),
    );
  }

  Widget _group(String title, List<Widget> children) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(DB.gutter, 12, DB.gutter, 4),
              child: Text(title.toUpperCase(), style: DB.mono(11, color: DB.mustard)),
            ),
            ...children,
          ],
        ),
      );

  Widget _link(BuildContext context, IconData icon, String label, String url) => ListTile(
        leading: Icon(icon, color: DB.paper.withValues(alpha: 0.8)),
        title: Text(label, style: DB.body(15, color: DB.paper, weight: FontWeight.w500)),
        trailing: Icon(Icons.chevron_right, color: DB.paper.withValues(alpha: 0.4)),
        onTap: () => url.startsWith('http')
            ? openExternal(context, url)
            : launchUrl(Uri.parse(url)),
      );
}
