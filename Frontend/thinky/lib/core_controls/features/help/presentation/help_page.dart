import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/theme/app_colors_extension.dart';
import 'package:thinky/shared_controls/theme/app_dimens.dart';
import 'package:thinky/shared_controls/widgets/animations/animated_widgets.dart';

class _FaqItem {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});
}

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  int? _expandedIndex;

  static const _faqs = [
    _FaqItem(
      question: 'Ce este Thinky și pentru cine este?',
      answer:
          'Thinky este o aplicație educativă pentru copiii cu vârsta între 7 și 12 ani. Te ajută să înțelegi conceptele de bază din inteligența artificială prin jocuri interactive și prin antrenarea mascotei Pixy.',
    ),
    _FaqItem(
      question: 'Cum funcționează mascota Pixy?',
      answer:
          'Pixy este mascota ta digitală care „învață" din interacțiunile tale. Pe măsură ce completezi misiuni și îi dai feedback, Pixy simulează cum un model de IA se îmbunătățește din exemple. Poți și să vorbești cu Pixy în secțiunea de chat!',
    ),
    _FaqItem(
      question: 'Ce sunt misiunile și cum câștig puncte?',
      answer:
          'Misiunile sunt jocuri educative care te învață despre IA: recunoașterea imaginilor, culori, forme, animale, vocabular și multe altele. Fiecare misiune completată îți aduce puncte. Poți descărca și misiuni din Workshop pentru puncte bonus!',
    ),
    _FaqItem(
      question: 'Ce este Workshop-ul?',
      answer:
          'Workshop-ul este locul unde poți explora misiuni create de alți utilizatori sau crea propriile misiuni. Descarcă misiuni noi pentru a învăța și a câștiga puncte suplimentare în leaderboard.',
    ),
    _FaqItem(
      question: 'Cum funcționează leaderboard-ul?',
      answer:
          'Leaderboard-ul afișează top 20 jucători după puncte. Punctele provin din misiunile completate și din misiunile Workshop descărcate. Statisticile (număr total jucători, medie puncte) sunt calculate pentru toată comunitatea.',
    ),
    _FaqItem(
      question: 'Pot folosi aplicația fără cont?',
      answer:
          'Da! Poți juca ca invitat (Guest) introducând doar un nume. Progresul tău va fi salvat local. Pentru a sincroniza pe mai multe dispozitive și a participa la leaderboard, creează un cont.',
    ),
    _FaqItem(
      question: 'Cum schimb limba aplicației?',
      answer:
          'Mergi la Profil → Settings → Language și alege între English și Română. Setarea se aplică imediat în întreaga aplicație.',
    ),
    _FaqItem(
      question: 'Aplicația nu se încarcă corect. Ce fac?',
      answer:
          'Verifică conexiunea la internet. Asigură-te că backend-ul rulează dacă folosești versiunea de dezvoltare. Încearcă să închizi și redeschizi aplicația sau să ștergi cache-ul.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: colors.background,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: colors.textPrimary),
              ),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
              title: Text(
                'Help & FAQ',
                style: GoogleFonts.alata(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.lg,
                AppDimens.sm,
                AppDimens.lg,
                AppDimens.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: AppDimens.xl),
                  _buildFaqList(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colors = context.appColors;
    return FadeInWidget(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimens.xl),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusXl),
          border: Border.all(color: colors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryPurple.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.help_outline_rounded,
                size: 28,
                color: AppColors.primaryPurple,
              ),
            ),
            const SizedBox(width: AppDimens.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Întrebări frecvente',
                    style: GoogleFonts.alata(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Găsește răspunsuri la cele mai comune întrebări despre Thinky.',
                    style: GoogleFonts.alata(
                      fontSize: 13,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqList(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FAQ',
          style: GoogleFonts.alata(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimens.lg),
        ...List.generate(_faqs.length, (index) {
          return FadeInWidget(
            delay: Duration(milliseconds: 50 * index),
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppDimens.sm),
              child: _buildFaqTile(index),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFaqTile(int index) {
    final colors = context.appColors;
    final faq = _faqs[index];
    final isExpanded = _expandedIndex == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _expandedIndex = isExpanded ? null : index;
          });
        },
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(AppDimens.lg),
          decoration: BoxDecoration(
            color: isExpanded
                ? colors.cardColor
                : colors.surface,
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            border: Border.all(
              color: isExpanded
                  ? AppColors.primaryPurple.withValues(alpha: 0.2)
                  : colors.border,
              width: 1,
            ),
            boxShadow: isExpanded
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      faq.question,
                      style: GoogleFonts.alata(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.primaryPurple,
                      size: 24,
                    ),
                  ),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: AppDimens.md),
                  child: Text(
                    faq.answer,
                    style: GoogleFonts.alata(
                      fontSize: 14,
                      height: 1.5,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                crossFadeState:
                    isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 250),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
