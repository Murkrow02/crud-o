import 'package:crud_o/resources/table/bloc/crudo_table_bloc.dart';
import 'package:crud_o/resources/table/bloc/crudo_table_event.dart';
import 'package:crud_o/resources/table/bloc/crudo_table_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

class CrudoTableFooter extends StatelessWidget {
  final PlutoGridStateManager tableManager;

  const CrudoTableFooter({super.key, required this.tableManager});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CrudoTableBloc, CrudoTableState>(
      builder: (context, state) {
        if (state is TableLoadedState) {
          final isFirstPage = state.request.page == 1;
          final isLastPage = !state.response.hasNextPage;
          final colorScheme = Theme.of(context).colorScheme;

          return Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: colorScheme.outlineVariant.withOpacity(0.5),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Previous page button
                _buildPaginationButton(
                  context: context,
                  icon: Icons.chevron_left_rounded,
                  enabled: !isFirstPage,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.read<CrudoTableBloc>().add(UpdateTableEvent(
                        request: state.request.copyWith(page: state.request.page - 1)));
                  },
                ),

                const SizedBox(width: 16),

                // Page indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Pagina ',
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '${state.request.page}',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Next page button
                _buildPaginationButton(
                  context: context,
                  icon: Icons.chevron_right_rounded,
                  enabled: !isLastPage,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.read<CrudoTableBloc>().add(UpdateTableEvent(
                        request: state.request.copyWith(page: state.request.page + 1)));
                  },
                ),
              ],
            ),
          );
        } else if (state is TableLoadingState) {
          return Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Center(
              child: SizedBox(
                height: 2,
                child: LinearProgressIndicator(),
              ),
            ),
          );
        }
        return const SizedBox(height: 52);
      },
    );
  }

  Widget _buildPaginationButton({
    required BuildContext context,
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: enabled
                ? colorScheme.primary.withOpacity(0.1)
                : colorScheme.onSurface.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            icon,
            color: enabled
                ? colorScheme.primary
                : colorScheme.onSurface.withOpacity(0.3),
            size: 24,
          ),
        ),
      ),
    );
  }
}
