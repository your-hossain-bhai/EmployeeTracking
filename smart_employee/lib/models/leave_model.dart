// leave_model.dart
// Leave/Absence Request Model

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum LeaveStatus { pending, approved, rejected }

enum LeaveType { sick, vacation, personal, unpaid, other }

/// Leave model representing employee leave requests
class LeaveModel extends Equatable {
  final String id;
  final String employeeId;
  final String companyId;
  final LeaveType type;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final LeaveStatus status;
  final String? approvedBy;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? approvedAt;

  const LeaveModel({
    required this.id,
    required this.employeeId,
    required this.companyId,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.reason,
    this.status = LeaveStatus.pending,
    this.approvedBy,
    this.rejectionReason,
    required this.createdAt,
    this.approvedAt,
  });

  /// Get number of days
  int get durationDays => endDate.difference(startDate).inDays + 1;

  /// Check if leave is in the past
  bool get isPast => endDate.isBefore(DateTime.now());

  /// Create from Firestore document
  factory LeaveModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LeaveModel(
      id: doc.id,
      employeeId: data['employeeId'] ?? '',
      companyId: data['companyId'] ?? '',
      type: LeaveType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => LeaveType.other,
      ),
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reason: data['reason'] ?? '',
      status: LeaveStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => LeaveStatus.pending,
      ),
      approvedBy: data['approvedBy'],
      rejectionReason: data['rejectionReason'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() => {
        'employeeId': employeeId,
        'companyId': companyId,
        'type': type.name,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'reason': reason,
        'status': status.name,
        'approvedBy': approvedBy,
        'rejectionReason': rejectionReason,
        'createdAt': Timestamp.fromDate(createdAt),
        'approvedAt':
            approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      };

  @override
  List<Object?> get props => [
        id,
        employeeId,
        companyId,
        type,
        startDate,
        endDate,
        reason,
        status,
        approvedBy,
        rejectionReason,
        createdAt,
        approvedAt,
      ];
}
