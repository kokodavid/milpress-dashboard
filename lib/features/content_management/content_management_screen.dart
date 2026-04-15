import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import 'widgets/video_fields_section.dart';
import 'widgets/resources_list_section.dart';
import 'widgets/step_types_section.dart';

class ContentManagementScreen extends StatelessWidget {
  const ContentManagementScreen({super.key});

  BoxDecoration get _cardDecoration => BoxDecoration(
        color: AppColors.faintGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1000;

          final videoCard = Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration,
            child: const VideoFieldsSection(),
          );

          final resourcesCard = Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration,
            child: const ResourcesListSection(),
          );

          final stepTypesCard = Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration,
            child: const StepTypesSection(),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            videoCard,
                            const SizedBox(height: 16),
                            resourcesCard,
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: stepTypesCard),
                    ],
                  )
                : Column(
                    children: [
                      videoCard,
                      const SizedBox(height: 16),
                      resourcesCard,
                      const SizedBox(height: 16),
                      stepTypesCard,
                    ],
                  ),
          );
        },
      ),
    );
  }
}
