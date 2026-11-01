import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'app_links.dart';
import 'growth_content.dart';
import 'growth_home.dart';
import '../account/account_controller.dart';
import '../account/account_page.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onOpenInterview, onOpenBible, onOpenSettings;
  final VoidCallback? onOpenVisualisasi;
  final Function(String query)? onFilterInterview;
  final Future<List<NewsArticle>> Function()? newsLoader;

  const HomeScreen({
    super.key,
    required this.onOpenInterview,
    required this.onOpenBible,
    required this.onOpenSettings,
    this.onOpenVisualisasi,
    this.onFilterInterview,
    this.newsLoader,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.background,
    body: SafeArea(
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          ((MediaQuery.sizeOf(context).width - 880) / 2).clamp(
            20.0,
            double.infinity,
          ),
          20,
          ((MediaQuery.sizeOf(context).width - 880) / 2).clamp(
            20.0,
            double.infinity,
          ),
          28,
        ),
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/logo_pmk.png',
                width: 46,
                height: 46,
                semanticLabel: 'Logo PMK Daniel',
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daniels App',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Together to be Better.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: AccountScope.maybeOf(context) == null
                    ? onOpenSettings
                    : () => openAccount(context),
                tooltip: 'Akun saya',
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.primarySurface,
                ),
                icon: const Icon(Icons.person_outline, color: AppTheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 24),
          GrowthHome(
            onOpenBible: onOpenBible,
            newsLoader: newsLoader,
            displayName: AccountScope.maybeOf(context)?.user?.name,
          ),
          const SizedBox(height: 32),
          const Text(
            'Akses cepat',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryDark,
            ),
          ),
          const SizedBox(height: 16),
          Material(
            color: AppTheme.primarySurface,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => AppLinks.openWebsite(context),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.language, color: AppTheme.primary, size: 28),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Web PMK',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Kenali komunitas dan kegiatan kami.',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12),
                    Icon(Icons.open_in_new, color: AppTheme.primary, size: 20),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            'PMK Daniel FILKOM UB',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    ),
  );
}
