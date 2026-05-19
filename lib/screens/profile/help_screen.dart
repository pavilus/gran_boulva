import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_colors.dart';
import '../../widgets/common/app_back_button.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final Set<int> _expanded = {};

  static const _faqs = [
    (
      'Kijan mwen ka vote nan yon matchup?',
      'Chwazi yon matchup nan paj prensipal la, apre klike sou opsyon ou vle sipòte a. Ou dwe ekri yon agimantasyon tou (omwen 10 karaktè) anvan ou ka soumèt vwa ou.'
    ),
    (
      'Kijan mwen ka chanje modpas mwen?',
      'Ale nan Pwofil → Sekirite ak vi prive, apre antre nouvo modpas ou. Modpas la dwe gen omwen 8 karaktè.'
    ),
    (
      'Kisa "Booste" yon agimantasyon vle di?',
      'Booste yon agimantasyon ba li plis vizibilite pou yon peryòd tan. Sa ede plis moun wè agimantasyon ou an.'
    ),
    (
      'Kijan mwen ka rapòte yon kontni ennapwopye?',
      'Klike sou ikonn "..." ki bò kote nenpòt agimantasyon oswa matchup, epi chwazi "Rapòte". Ekip nou an ap revize li.'
    ),
    (
      'Eske done mwen yo an sekirite?',
      'Wi. Nou itilize Supabase pou estoke done yo ak chifre yo. Nou pa janm pataje enfòmasyon pèsonèl ou avèk tyes pati san pèmisyon ou.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        backgroundColor: AppColors.bg0,
        surfaceTintColor: Colors.transparent,
        leading: AppBackButton(
          onTap: () => Navigator.of(context).pop(),
        ),
        title: const Text('Èd ak sipò',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins')),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Contact card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Ou bezwen èd?',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Poppins')),
                      const SizedBox(height: 4),
                      const Text('Ekip nou an la pou ede ou',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontFamily: 'Poppins')),
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: () => launchUrl(
                            Uri.parse('mailto:support@granboulva.com')),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('Kontakte nou',
                              style: TextStyle(
                                  color: AppColors.purple,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Poppins')),
                        ),
                      ),
                    ]),
              ),
              const Text('🎧', style: TextStyle(fontSize: 48)),
            ]),
          ),
          const SizedBox(height: 24),
          const Text('Kesyon yo poze souvan (FAQ)',
              style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.1,
                  fontFamily: 'Poppins')),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: _faqs.asMap().entries.map((e) {
                final i = e.key;
                final (question, answer) = e.value;
                final isExpanded = _expanded.contains(i);
                return Column(children: [
                  GestureDetector(
                    onTap: () => setState(() {
                      if (isExpanded) {
                        _expanded.remove(i);
                      } else {
                        _expanded.add(i);
                      }
                    }),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(children: [
                        Expanded(
                          child: Text(question,
                              style: TextStyle(
                                  color: isExpanded
                                      ? AppColors.purpleLight
                                      : AppColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins')),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                      ]),
                    ),
                  ),
                  if (isExpanded)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: Text(answer,
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontFamily: 'Poppins',
                              height: 1.5)),
                    ),
                  if (i < _faqs.length - 1)
                    const Divider(
                        height: 1,
                        color: AppColors.borderDim,
                        indent: 16,
                        endIndent: 16),
                ]);
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          // Legal links
          const Text('Done legal yo',
              style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.1,
                  fontFamily: 'Poppins')),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Column(
              children: [
                _LegalLink(label: 'Politik sou Vi Prive / Privacy Policy', url: 'https://www.granboulva.com/privacy'),
                Divider(height: 1, color: AppColors.borderDim, indent: 16, endIndent: 16),
                _LegalLink(label: 'Tèm ak Kondisyon / Terms of Service', url: 'https://www.granboulva.com/terms'),
                Divider(height: 1, color: AppColors.borderDim, indent: 16, endIndent: 16),
                _LegalLink(label: 'Règleman Bon Itilizasyon / Acceptable Use', url: 'https://www.granboulva.com/aup'),
                Divider(height: 1, color: AppColors.borderDim, indent: 16, endIndent: 16),
                _LegalLink(label: 'Règleman DMCA', url: 'https://www.granboulva.com/dmca'),
                Divider(height: 1, color: AppColors.borderDim, indent: 16, endIndent: 16),
                _LegalLink(label: 'Règleman Koki / Cookie Policy', url: 'https://www.granboulva.com/cookies'),
                Divider(height: 1, color: AppColors.borderDim, indent: 16, endIndent: 16),
                _LegalLink(label: 'Deklare / Disclaimer', url: 'https://www.granboulva.com/disclaimer'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'Gran Boulva v1.0.0\nsupport@granboulva.com',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textDim,
                  fontSize: 11,
                  fontFamily: 'Poppins',
                  height: 1.6),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _LegalLink extends StatelessWidget {
  final String label;
  final String url;

  const _LegalLink({required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins')),
          ),
          const Icon(Icons.open_in_new_rounded, color: AppColors.textMuted, size: 16),
        ]),
      ),
    );
  }
}
