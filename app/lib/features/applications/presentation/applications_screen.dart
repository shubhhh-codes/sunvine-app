import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/widgets.dart';
import 'controllers/applications_controller.dart';
import 'widgets/application_card_widget.dart';

/// Presentation screen for tracking active consumer installation applications.
class ApplicationsScreen extends StatefulWidget {
  final ApplicationsController? controller;

  const ApplicationsScreen({super.key, this.controller});

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  late final ApplicationsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller!;
    if (_controller.status == ApplicationsStatus.initial) {
      _controller.loadApplications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Applications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _controller.loadApplications(),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  if (_controller.isLoading &&
                      _controller.applications.isEmpty) {
                    return const SunLoadingIndicator(
                      message: 'Loading active applications...',
                    );
                  }

                  if (_controller.status == ApplicationsStatus.error &&
                      _controller.applications.isEmpty) {
                    return SunErrorView(
                      message:
                          _controller.errorMessage ??
                          'Unable to fetch applications',
                      onRetry: () => _controller.loadApplications(),
                    );
                  }

                  if (_controller.applications.isEmpty) {
                    return const SunEmptyState(
                      icon: Icons.assignment_outlined,
                      title: 'No applications in pipeline',
                      description:
                          'Active installation pipelines will appear here.',
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.emerald,
                    backgroundColor: AppColors.surface,
                    onRefresh: () => _controller.loadApplications(),
                    child: ListView.separated(
                      itemCount: _controller.applications.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final app = _controller.applications[index];
                        return ApplicationCardWidget(application: app);
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
