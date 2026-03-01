import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../providers/plates_provider.dart';
import '../router/route_paths.dart';
import '../utils/plate_formatter.dart';
import '../utils/validators.dart';
import '../widgets/error_view.dart';
import '../widgets/plate_input_field.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final platesState = ref.watch(platesProvider);
    final theme = Theme.of(context);

    final user = authState.value?.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User info section
          Semantics(
            label: 'Profile: ${user?.displayName ?? 'Unknown'}, '
                '${user?.email ?? ''}',
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ExcludeSemantics(
                      child: CircleAvatar(
                        radius: 36,
                        child: Text(
                          user?.displayName.isNotEmpty == true
                              ? user!.displayName[0].toUpperCase()
                              : '?',
                          style: theme.textTheme.headlineMedium,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.displayName ?? '',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Plates section header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Plates',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Semantics(
                button: true,
                label: 'Add a new license plate',
                child: FilledButton.tonalIcon(
                  onPressed: () => _showAddPlateDialog(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Plate'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Plates list
          platesState.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) => ErrorView(
              message: error.toString(),
              onRetry: () => ref.invalidate(platesProvider),
            ),
            data: (plates) {
              if (plates.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No plates claimed yet.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return Column(
                children: plates
                    .map(
                      (plate) => Card(
                        child: ListTile(
                          leading: const ExcludeSemantics(
                            child: Icon(Icons.directions_car),
                          ),
                          title: Text(plate.plateNumber),
                          subtitle: plate.stateOrRegion != null
                              ? Text(plate.stateOrRegion!)
                              : null,
                          trailing: Semantics(
                            button: true,
                            label:
                                'Release plate ${plate.plateNumber}',
                            child: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Release plate',
                              onPressed: () =>
                                  _confirmReleasePlate(context, ref, plate.id),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          // App version
          Center(
            child: Text(
              'Version 1.0.0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Logout button
          Semantics(
            button: true,
            label: 'Log out of your account',
            child: OutlinedButton(
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  context.go(RoutePaths.login);
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error),
              ),
              child: const Text('Logout'),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddPlateDialog(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final plateController = TextEditingController();
    final stateRegionController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Plate'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PlateInputField(
                controller: plateController,
                validator: validatePlate,
                label: 'License Plate',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: stateRegionController,
                decoration: const InputDecoration(
                  labelText: 'State / Region (optional)',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final stateOrRegion = stateRegionController.text.trim();
              try {
                await ref.read(platesProvider.notifier).claimPlate(
                      plateNumber: normalizePlate(plateController.text),
                      stateOrRegion:
                          stateOrRegion.isEmpty ? null : stateOrRegion,
                    );
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Failed to claim plate: $e')),
                  );
                }
              }
            },
            child: const Text('Claim'),
          ),
        ],
      ),
    );
  }

  void _confirmReleasePlate(BuildContext context, WidgetRef ref, String id) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Release Plate'),
        content:
            const Text('Are you sure you want to release this license plate?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await ref.read(platesProvider.notifier).releasePlate(id);
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Failed to release plate: $e')),
                  );
                }
              }
            },
            child: const Text('Release'),
          ),
        ],
      ),
    );
  }
}
