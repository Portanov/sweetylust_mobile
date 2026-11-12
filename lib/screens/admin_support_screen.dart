import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sweetylust/models/admin_support_model.dart';
import 'package:sweetylust/providers/admin_support_provider.dart';

class AdminSupportScreen extends ConsumerStatefulWidget {
  const AdminSupportScreen({super.key});

  @override
  ConsumerState<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends ConsumerState<AdminSupportScreen> {
  final _searchController = TextEditingController();
  SupportStatus? _statusFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReports());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadReports() {
    ref
        .read(adminSupportNotifierProvider.notifier)
        .fetchReports(search: _searchController.text, status: _statusFilter);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminSupportNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1020),
        foregroundColor: Colors.white,
        title: const Text('Soporte'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: state.isLoading ? null : _loadReports,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildFilters(),
            Expanded(child: _buildContent(state)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar reporte...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                suffixIcon: IconButton(
                  onPressed: _loadReports,
                  icon: const Icon(Icons.arrow_forward, color: Colors.white70),
                ),
                filled: true,
                fillColor: const Color(0xFF16213E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _loadReports(),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<SupportStatus?>(
            initialValue: _statusFilter,
            onSelected: (status) {
              setState(() => _statusFilter = status);
              _loadReports();
            },
            color: const Color(0xFF16213E),
            icon: const Icon(Icons.filter_list, color: Colors.white),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('Todos', style: TextStyle(color: Colors.white)),
              ),
              ...SupportStatus.values.map(
                (status) => PopupMenuItem(
                  value: status,
                  child: Text(
                    status.label,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AdminSupportState state) {
    if (state.isLoading && state.reports.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.lightBlueAccent),
      );
    }
    if (state.error != null && state.reports.isEmpty) {
      return _MessageView(
        message: state.error!,
        action: _loadReports,
        actionLabel: 'Reintentar',
      );
    }
    if (state.reports.isEmpty) {
      return const _MessageView(message: 'No hay reportes para mostrar.');
    }

    return RefreshIndicator(
      onRefresh: () async => _loadReports(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        itemCount: state.reports.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final report = state.reports[index];
          return _ReportCard(
            report: report,
            onTap: () => _showReportDetails(report),
          );
        },
      ),
    );
  }

  Future<void> _showReportDetails(AdminSupportReport report) async {
    var selectedStatus = report.status;
    final updatedStatus = await showModalBottomSheet<SupportStatus>(
      context: context,
      backgroundColor: const Color(0xFF16213E),
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Detalle del reporte',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(label: 'Asunto', value: report.subject),
                  _DetailRow(label: 'Nombre', value: report.name),
                  _DetailRow(label: 'Correo', value: report.email),
                  if (report.phone != null && report.phone!.isNotEmpty)
                    _DetailRow(label: 'Teléfono', value: report.phone!),
                  _DetailRow(label: 'Mensaje', value: report.message),
                  const SizedBox(height: 16),
                  const Text(
                    'Estatus',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  DropdownButton<SupportStatus>(
                    value: selectedStatus,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF0B1020),
                    iconEnabledColor: Colors.white,
                    style: const TextStyle(color: Colors.white),
                    items: SupportStatus.values
                        .map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(status.label),
                          ),
                        )
                        .toList(),
                    onChanged: (status) {
                      if (status != null) {
                        setModalState(() => selectedStatus = status);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, selectedStatus),
                      child: const Text('Guardar estatus'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (!mounted || updatedStatus == null || updatedStatus == report.status) {
      return;
    }

    final success = await ref
        .read(adminSupportNotifierProvider.notifier)
        .updateStatus(report.id, updatedStatus);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Estatus actualizado correctamente'
              : 'No se pudo actualizar el estatus',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final AdminSupportReport report;
  final VoidCallback onTap;

  const _ReportCard({required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (report.status) {
      SupportStatus.pending => Colors.orangeAccent,
      SupportStatus.reviewed => Colors.lightBlueAccent,
      SupportStatus.closed => Colors.greenAccent,
    };

    return Material(
      color: const Color(0xFF16213E),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: statusColor.withValues(alpha: 0.18),
                child: Icon(Icons.support_agent, color: statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.subject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${report.name} · ${report.email}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      report.status.label,
                      style: TextStyle(color: statusColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 15)),
        ],
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  final String message;
  final VoidCallback? action;
  final String? actionLabel;

  const _MessageView({required this.message, this.action, this.actionLabel});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, color: Colors.white54, size: 44),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            if (action != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(onPressed: action, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
