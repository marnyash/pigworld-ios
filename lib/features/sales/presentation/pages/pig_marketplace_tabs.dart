import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../data/pig_listing.dart';
import '../providers/pig_marketplace_provider.dart';

class ForBuyersTab extends ConsumerWidget {
  const ForBuyersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmName = ref.watch(authProvider).valueOrNull?.selectedFarm?.name;
    final listings = ref.watch(pigMarketplaceProvider);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(pigMarketplaceProvider.future),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppDimensions.pagePadding),
        children: [
          Card(
            color: AppColors.deepGreen,
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your farm on the pig marketplace',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.inverseText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Buyers can browse available pigs and send a purchase request. '
                    'Requests appear in My sales.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.inverseMutedText,
                    ),
                  ),
                  if (farmName != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      farmName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.inverseMutedText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingLarge),
          Text(
            'Available to buyers',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppDimensions.spacingSmall),
          listings.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) => _MarketplaceError(
              error: error,
              onRetry: () => ref.invalidate(pigMarketplaceProvider),
            ),
            data: (items) {
              final available = items
                  .where((listing) => listing.status == 'available')
                  .toList();
              if (available.isEmpty) {
                return const _InfoCard(
                  icon: Icons.storefront_outlined,
                  message:
                      'No pigs are listed yet. Post a pig to make it visible to buyers.',
                );
              }
              return Column(
                children: [
                  for (final listing in available)
                    _ListingCard(listing: listing),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class PostPigTab extends ConsumerStatefulWidget {
  const PostPigTab({required this.canManage, super.key});

  final bool canManage;

  @override
  ConsumerState<PostPigTab> createState() => _PostPigTabState();
}

class _PostPigTabState extends ConsumerState<PostPigTab> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _breed = TextEditingController();
  final _quantity = TextEditingController(text: '1');
  final _price = TextEditingController();
  final _age = TextEditingController();
  final _weight = TextEditingController();
  final _location = TextEditingController();
  final _description = TextEditingController();
  String _currency = 'KES';
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _breed.dispose();
    _quantity.dispose();
    _price.dispose();
    _age.dispose();
    _weight.dispose();
    _location.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasFarm = ref.watch(authProvider).valueOrNull?.selectedFarm != null;
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.pagePadding),
      children: [
        Text(
          'Post a pig for sale',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppDimensions.spacingSmall),
        const Text('Create a listing that buyers can find in the buyer app.'),
        const SizedBox(height: AppDimensions.spacingLarge),
        if (!hasFarm)
          const _InfoCard(
            icon: Icons.agriculture_outlined,
            message: 'Select a farm before posting pigs.',
          )
        else if (!widget.canManage)
          const _InfoCard(
            icon: Icons.lock_outline,
            message: 'You need Manage sales permission to post pigs.',
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingLarge),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _title,
                      decoration: const InputDecoration(
                        labelText: 'Listing title',
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _breed,
                      decoration: const InputDecoration(labelText: 'Breed'),
                      textCapitalization: TextCapitalization.words,
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _quantity,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Number available',
                            ),
                            validator: _positiveInteger,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _age,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Age (weeks)',
                            ),
                            validator: _optionalPositiveInteger,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _price,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Price per pig',
                            ),
                            validator: _positiveNumber,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _currency,
                            decoration: const InputDecoration(
                              labelText: 'Currency',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'KES',
                                child: Text('KES'),
                              ),
                              DropdownMenuItem(
                                value: 'UGX',
                                child: Text('UGX'),
                              ),
                              DropdownMenuItem(
                                value: 'TZS',
                                child: Text('TZS'),
                              ),
                              DropdownMenuItem(
                                value: 'USD',
                                child: Text('USD'),
                              ),
                            ],
                            onChanged: (value) =>
                                setState(() => _currency = value ?? _currency),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _weight,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Average weight (kg, optional)',
                      ),
                      validator: _optionalPositiveNumber,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _location,
                      decoration: const InputDecoration(
                        labelText: 'Location (optional)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _description,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppDimensions.spacingLarge),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _submit,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.publish_outlined),
                        label: Text(_saving ? 'Posting…' : 'Publish listing'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;

  String? _positiveInteger(String? value) {
    final number = int.tryParse(value?.trim() ?? '');
    return number == null || number < 1 ? 'Enter a number above zero.' : null;
  }

  String? _optionalPositiveInteger(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return _positiveInteger(value);
  }

  String? _positiveNumber(String? value) {
    final number = double.tryParse(value?.trim() ?? '');
    return number == null || number <= 0 ? 'Enter an amount above zero.' : null;
  }

  String? _optionalPositiveNumber(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return _positiveNumber(value);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(pigMarketplaceProvider.notifier)
          .createListing(
            title: _title.text.trim(),
            breed: _breed.text.trim(),
            quantity: int.parse(_quantity.text.trim()),
            pricePerPig: double.parse(_price.text.trim()),
            currency: _currency,
            ageWeeks: int.tryParse(_age.text.trim()),
            weightKg: double.tryParse(_weight.text.trim()),
            location: _location.text.trim(),
            description: _description.text.trim(),
          );
      if (!mounted) return;
      _formKey.currentState!.reset();
      _title.clear();
      _breed.clear();
      _quantity.text = '1';
      _price.clear();
      _age.clear();
      _weight.clear();
      _location.clear();
      _description.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pig listing published for buyers.')),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not publish listing: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class MyMarketplaceSalesSection extends ConsumerWidget {
  const MyMarketplaceSalesSection({required this.canManage, super.key});

  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pigMarketplaceProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppDimensions.spacingLarge),
        Text(
          'Marketplace listings & buyer requests',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppDimensions.spacingSmall),
        state.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(18),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => _MarketplaceError(
            error: error,
            onRetry: () => ref.invalidate(pigMarketplaceProvider),
          ),
          data: (items) => items.isEmpty
              ? const _InfoCard(
                  icon: Icons.storefront_outlined,
                  message: 'You have not posted any pigs yet.',
                )
              : Column(
                  children: [
                    for (final listing in items)
                      _ManageListingCard(
                        listing: listing,
                        canManage: canManage,
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.listing});

  final PigListing listing;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const CircleAvatar(child: Icon(Icons.pets_outlined)),
      title: Text(listing.title),
      subtitle: Text(
        '${listing.breed} · ${listing.quantity} available'
        '${listing.location == null || listing.location!.isEmpty ? '' : ' · ${listing.location}'}',
      ),
      trailing: Text(
        '${listing.currency} ${listing.pricePerPig.toStringAsFixed(0)}',
        style: Theme.of(context).textTheme.titleSmall,
      ),
    ),
  );
}

class _ManageListingCard extends ConsumerWidget {
  const _ManageListingCard({required this.listing, required this.canManage});

  final PigListing listing;
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    margin: const EdgeInsets.only(bottom: AppDimensions.spacingMedium),
    child: Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  listing.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (canManage)
                PopupMenuButton<String>(
                  onSelected: (status) async {
                    try {
                      await ref
                          .read(pigMarketplaceProvider.notifier)
                          .updateListingStatus(listing.id, status);
                    } catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Could not update listing: $error'),
                          ),
                        );
                      }
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'available', child: Text('Available')),
                    PopupMenuItem(
                      value: 'unavailable',
                      child: Text('Unavailable'),
                    ),
                    PopupMenuItem(value: 'sold', child: Text('Sold')),
                  ],
                  child: Chip(label: Text(listing.status)),
                )
              else
                Chip(label: Text(listing.status)),
            ],
          ),
          Text(
            '${listing.breed} · ${listing.quantity} available · '
            '${listing.currency} ${listing.pricePerPig.toStringAsFixed(0)} each',
          ),
          for (final inquiry in listing.inquiries)
            _InquiryRow(
              listing: listing,
              inquiry: inquiry,
              canManage: canManage,
            ),
          if (listing.inquiries.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text('No buyer requests yet.'),
            ),
        ],
      ),
    ),
  );
}

class _InquiryRow extends ConsumerWidget {
  const _InquiryRow({
    required this.listing,
    required this.inquiry,
    required this.canManage,
  });
  final PigListing listing;
  final PigInquiry inquiry;
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${inquiry.buyerName} · ${inquiry.quantity} requested',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (canManage)
                  PopupMenuButton<String>(
                    onSelected: (status) async {
                      try {
                        await ref
                            .read(pigMarketplaceProvider.notifier)
                            .updateInquiryStatus(
                              listing.id,
                              inquiry.id,
                              status,
                            );
                      } catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Could not update buyer request: $error',
                              ),
                            ),
                          );
                        }
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'pending', child: Text('Pending')),
                      PopupMenuItem(value: 'accepted', child: Text('Accepted')),
                      PopupMenuItem(value: 'rejected', child: Text('Rejected')),
                      PopupMenuItem(
                        value: 'completed',
                        child: Text('Completed'),
                      ),
                    ],
                    child: Chip(label: Text(inquiry.status)),
                  )
                else
                  Chip(label: Text(inquiry.status)),
              ],
            ),
            Text(inquiry.phone),
            if (inquiry.email?.isNotEmpty == true) Text(inquiry.email!),
            if (inquiry.message?.isNotEmpty == true) Text(inquiry.message!),
          ],
        ),
      ),
    ),
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingLarge),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryGreen),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class _MarketplaceError extends StatelessWidget {
  const _MarketplaceError({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Marketplace data could not be loaded.\n$error',
            textAlign: TextAlign.center,
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}
