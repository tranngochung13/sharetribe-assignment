import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../bloc/listing_bloc.dart';
import '../bloc/listing_event.dart';
import '../bloc/listing_state.dart';

class ListingsPage extends StatefulWidget {
  const ListingsPage({super.key});

  @override
  State<ListingsPage> createState() => _ListingsPageState();
}

class _ListingsPageState extends State<ListingsPage> {
  @override
  void initState() {
    super.initState();

    context.read<ListingBloc>().add(const ListingsRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listings'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () {
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: BlocBuilder<ListingBloc, ListingState>(
        buildWhen: (previous, current) =>
            !(previous is ListingLoaded && current is ListingLoading),
        builder: (context, state) {
          if (state is ListingLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ListingFailure) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.message),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      context.read<ListingBloc>().add(
                        const ListingsRequested(),
                      );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is ListingLoaded) {
            if (state.listings.isEmpty) {
              return const Center(child: Text('No listings found.'));
            }

            return RefreshIndicator(
              onRefresh: () async {
                final bloc = context.read<ListingBloc>();
                final completed = bloc.stream.firstWhere(
                  (state) => state is ListingLoaded || state is ListingFailure,
                );
                bloc.add(const ListingsRequested());
                await completed;
              },
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: state.listings.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final listing = state.listings[index];

                  return Card(
                    child: ListTile(
                      title: Text(
                        listing.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: listing.description.isNotEmpty
                          ? Text(
                              listing.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                    ),
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
