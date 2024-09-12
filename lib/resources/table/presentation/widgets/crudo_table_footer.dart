import 'package:crud_o/resources/table/bloc/crudo_table_bloc.dart';
import 'package:crud_o/resources/table/bloc/crudo_table_event.dart';
import 'package:crud_o/resources/table/bloc/crudo_table_state.dart';
import 'package:flutter/material.dart';
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
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                disabledColor: Colors.grey,
                  onPressed: state.request.page == 1 ? null : () {
                    context.read<CrudoTableBloc>().add(UpdateTableEvent(
                        state.request.copyWith(page: state.request.page - 1)));
                  },
                  icon: const Icon(Icons.keyboard_arrow_left)),
              Text("Pagina ${state.request.page}"),
              IconButton(
                disabledColor: Colors.grey,
                  onPressed: !state.response.hasNextPage ? null : () {
                    context.read<CrudoTableBloc>().add(UpdateTableEvent(
                        state.request.copyWith(page: state.request.page + 1)));
                  },
                  icon: const Icon(Icons.keyboard_arrow_right)),
            ],
          );
        }
        else if (state is TableLoadingState) {
          return const LinearProgressIndicator();
        }
        return const SizedBox();
      },
    );
  }
}
