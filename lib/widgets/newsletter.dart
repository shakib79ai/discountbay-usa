import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repository.dart';
import '../theme/tokens.dart';
import 'decor.dart';

/// Mustard "Never miss a drop" newsletter band.
class NewsletterBand extends StatefulWidget {
  const NewsletterBand({super.key, this.storeName});

  /// When set, copy changes to "Get new {store} codes".
  final String? storeName;

  @override
  State<NewsletterBand> createState() => _NewsletterBandState();
}

class _NewsletterBandState extends State<NewsletterBand> {
  final _ctrl = TextEditingController();
  bool _busy = false;
  bool _done = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _ctrl.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid email address')));
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await context.read<Repository>().subscribeNewsletter(email);
      if (mounted) setState(() => _done = true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Couldn't subscribe right now — try again")));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.storeName == null ? 'Never miss a drop' : 'Get new ${widget.storeName} codes';
    final sub = widget.storeName == null
        ? 'The week’s best verified codes, every Friday. Unsubscribe any time.'
        : "We'll email you when new verified codes land. Unsubscribe any time.";
    return Column(
      children: [
        const Perforation(background: DB.mustard),
        Container(
          width: double.infinity,
          color: DB.mustard,
          padding: const EdgeInsets.fromLTRB(DB.gutter, 22, DB.gutter, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title.toUpperCase(), style: DB.display(28, color: DB.ink)),
              const SizedBox(height: 6),
              Text(sub, style: DB.body(14, color: DB.ink.withValues(alpha: 0.8))),
              const SizedBox(height: 16),
              if (_done)
                Row(children: [
                  const Icon(Icons.check_circle, color: DB.ink),
                  const SizedBox(width: 8),
                  Text("You're in! Check your inbox.", style: DB.body(15, weight: FontWeight.w700)),
                ])
              else
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
                  decoration: BoxDecoration(color: DB.paper, borderRadius: BorderRadius.circular(999)),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ctrl,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _submit(),
                          style: DB.body(15),
                          cursorColor: DB.coral,
                          decoration: InputDecoration(
                            hintText: 'Email address',
                            hintStyle: DB.body(15, color: DB.ink.withValues(alpha: 0.45)),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      FilledButton(
                        onPressed: _busy ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: DB.ink,
                          foregroundColor: DB.paper,
                          shape: const StadiumBorder(),
                        ),
                        child: _busy
                            ? const SizedBox(
                                width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: DB.paper))
                            : Text('Subscribe', style: DB.body(14, color: DB.paper, weight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const Perforation(background: DB.mustard),
      ],
    );
  }
}
