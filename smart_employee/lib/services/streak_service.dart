import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Service to calculate attendance streaks and punctuality patterns
class StreakService {
  final FirebaseFirestore _firestore;

  StreakService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Calculate consecutive on-time days for an employee
  /// Returns the current streak count
  Future<int> calculateCurrentStreak({
    required String employeeId,
    required String companyId,
  }) async {
    try {
      // Get last 90 days of attendance records
      final cutoffDate = DateTime.now().subtract(const Duration(days: 90));

      final snapshot = await _firestore
          .collection('attendance')
          .where('employeeId', isEqualTo: employeeId)
          .where('companyId', isEqualTo: companyId)
          .where('checkInTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(cutoffDate))
          .orderBy('checkInTime', descending: true)
          .get();

      if (snapshot.docs.isEmpty) return 0;

      // Group records by date
      final Map<String, Map<String, dynamic>> recordsByDate = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final checkInTime = (data['checkInTime'] as Timestamp).toDate();
        final dateKey = DateFormat('yyyy-MM-dd').format(checkInTime);

        if (!recordsByDate.containsKey(dateKey)) {
          recordsByDate[dateKey] = {
            'checkInTime': checkInTime,
            'isLate': data['isLate'] ?? false,
            'status': data['status'] ?? 'present',
          };
        }
      }

      // Sort dates descending
      final sortedDates = recordsByDate.keys.toList()
        ..sort((a, b) => b.compareTo(a));

      // Calculate streak from most recent date
      int streak = 0;
      DateTime? expectedDate = DateTime.now();

      for (var dateKey in sortedDates) {
        final record = recordsByDate[dateKey]!;
        final recordDate = record['checkInTime'] as DateTime;

        // Normalize to date only (ignore time)
        final normalizedRecord = DateTime(
          recordDate.year,
          recordDate.month,
          recordDate.day,
        );
        final normalizedExpected = DateTime(
          expectedDate!.year,
          expectedDate.month,
          expectedDate.day,
        );

        // Check if this record is for the expected date or within 1 day
        final daysDiff =
            normalizedExpected.difference(normalizedRecord).inDays.abs();

        if (daysDiff > 1) {
          // Gap found, streak ends
          break;
        }

        // Count as streak day if on-time and present
        if (!(record['isLate'] as bool) && record['status'] == 'present') {
          streak++;
          expectedDate = normalizedRecord.subtract(const Duration(days: 1));
        } else {
          // Late or absent, streak breaks
          break;
        }
      }

      return streak;
    } catch (e) {
      print('Error calculating streak: $e');
      return 0;
    }
  }

  /// Get punctuality stats for badge evaluation
  Future<Map<String, dynamic>> getPunctualityStats({
    required String employeeId,
    required String companyId,
    int days = 30,
  }) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));

      final snapshot = await _firestore
          .collection('attendance')
          .where('employeeId', isEqualTo: employeeId)
          .where('companyId', isEqualTo: companyId)
          .where('checkInTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(cutoffDate))
          .get();

      if (snapshot.docs.isEmpty) {
        return {
          'totalDays': 0,
          'onTimeDays': 0,
          'lateDays': 0,
          'punctualityRate': 0.0,
          'earlyCheckIns': 0,
        };
      }

      int totalDays = snapshot.docs.length;
      int onTimeDays = 0;
      int lateDays = 0;
      int earlyCheckIns = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final isLate = data['isLate'] ?? false;

        if (!isLate) {
          onTimeDays++;

          // Check if checked in early (more than 10 minutes before work start)
          final checkInTime = (data['checkInTime'] as Timestamp).toDate();
          final workStartTime = data['workStartTime'] as String?;
          if (workStartTime != null) {
            final startParts = workStartTime.split(':');
            final startDateTime = DateTime(
              checkInTime.year,
              checkInTime.month,
              checkInTime.day,
              int.parse(startParts[0]),
              int.parse(startParts[1]),
            );

            if (checkInTime.isBefore(
                startDateTime.subtract(const Duration(minutes: 10)))) {
              earlyCheckIns++;
            }
          }
        } else {
          lateDays++;
        }
      }

      return {
        'totalDays': totalDays,
        'onTimeDays': onTimeDays,
        'lateDays': lateDays,
        'punctualityRate': totalDays > 0 ? (onTimeDays / totalDays * 100) : 0.0,
        'earlyCheckIns': earlyCheckIns,
      };
    } catch (e) {
      print('Error calculating punctuality stats: $e');
      return {
        'totalDays': 0,
        'onTimeDays': 0,
        'lateDays': 0,
        'punctualityRate': 0.0,
        'earlyCheckIns': 0,
      };
    }
  }

  /// Determine which badge the employee has earned
  Future<String?> getCurrentBadge({
    required String employeeId,
    required String companyId,
  }) async {
    final streak = await calculateCurrentStreak(
      employeeId: employeeId,
      companyId: companyId,
    );

    final stats = await getPunctualityStats(
      employeeId: employeeId,
      companyId: companyId,
      days: 30,
    );

    // Badge hierarchy (return best badge)
    if (streak >= 30) return '🏆 30-Day Champion';
    if (streak >= 21) return '💎 Consistency Master';
    if (streak >= 14) return '⭐ Two-Week Star';
    if (streak >= 7) return '🔥 Week Perfect';
    if (stats['punctualityRate'] >= 95.0 && stats['totalDays'] >= 20) {
      return '🎯 95% Club';
    }
    if (stats['earlyCheckIns'] >= 15) return '🌅 Early Bird';
    if (streak >= 3) return '✅ On Track';

    return null;
  }
}
