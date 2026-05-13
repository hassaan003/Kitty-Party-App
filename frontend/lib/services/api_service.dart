import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

import 'dart:convert';
import 'package:http/http.dart' as http;

/// Cross-platform basename for multipart uploads (Windows uses `\`).
String _basename(String path) {
  final normalized = path.replaceAll('\\', '/');
  final i = normalized.lastIndexOf('/');
  return i >= 0 ? normalized.substring(i + 1) : normalized;
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  final String baseUrl = "http://192.168.18.99:8080";
  factory ApiService() => _instance;

  late Dio dio;
  bool _isInitialized = false;

  ApiService._internal();

  Future<void> init() async {
    if (_isInitialized) return;

    final dir = await getApplicationDocumentsDirectory();

    final cookieJar = PersistCookieJar(
      storage: FileStorage("${dir.path}/.cookies/"),
    );

    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        headers: {"Content-Type": "application/json"},
        validateStatus: (status) => true,
      ),
    );

    dio.interceptors.add(CookieManager(cookieJar));

    _isInitialized = true;
  }

  void _throwIfBadStatus(http.Response res, String context) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        '$context: HTTP ${res.statusCode} — ${res.body.isEmpty ? "(empty body)" : res.body}',
      );
    }
  }

  dynamic _jsonDecodeBody(http.Response res, String context) {
    _throwIfBadStatus(res, context);
    if (res.body.isEmpty) return null;
    try {
      return jsonDecode(res.body);
    } catch (e) {
      throw Exception('$context: invalid JSON — $e');
    }
  }

  Future<Response> _dioExpectOk(
    Future<Response> Function() call,
    String context,
  ) async {
    await init();
    try {
      final response = await call();
      final code = response.statusCode;
      if (code != null && (code < 200 || code >= 300)) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: '$context failed: HTTP $code — ${response.data}',
        );
      }
      return response;
    } catch (e, st) {
      debugPrint('ApiService.$context: $e\n$st');
      rethrow;
    }
  }

  Future<String> login(String phone, String password) async {
    try {
      await init();
      final response = await _dioExpectOk(
        () => dio.post(
          "/login",
          data: {"phoneno": phone, "password": password},
        ),
        'login',
      );
      return response.data?.toString() ?? '';
    } catch (e, st) {
      debugPrint('ApiService.login: $e\n$st');
      return 'Error: $e';
    }
  }

  Future<dynamic> getNotifications(String userId) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/get-notifications/$userId"),
      );
      return _jsonDecodeBody(res, 'getNotifications');
    } catch (e, st) {
      debugPrint('ApiService.getNotifications: $e\n$st');
      rethrow;
    }
  }

  Future<String> approveJoinRequest(String notificationId) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/approve-join-request/$notificationId"),
      );
      _throwIfBadStatus(res, 'approveJoinRequest');
      return res.body;
    } catch (e, st) {
      debugPrint('ApiService.approveJoinRequest: $e\n$st');
      rethrow;
    }
  }

  Future<String> rejectJoinRequest(String notificationId) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/reject-join-request/$notificationId"),
      );
      _throwIfBadStatus(res, 'rejectJoinRequest');
      return res.body;
    } catch (e, st) {
      debugPrint('ApiService.rejectJoinRequest: $e\n$st');
      rethrow;
    }
  }

  Future<String> acceptInvite(String notificationId) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/accept-invite/$notificationId"),
      );
      _throwIfBadStatus(res, 'acceptInvite');
      return res.body;
    } catch (e, st) {
      debugPrint('ApiService.acceptInvite: $e\n$st');
      rethrow;
    }
  }

  Future<String> clearNotification(String id) async {
    try {
      final res = await http.delete(
        Uri.parse("$baseUrl/clear-notification/$id"),
      );
      _throwIfBadStatus(res, 'clearNotification');
      return res.body;
    } catch (e, st) {
      debugPrint('ApiService.clearNotification: $e\n$st');
      rethrow;
    }
  }

  Future<List<dynamic>> getCycles(String committeeId) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/all-cycle-till-now-committee/$committeeId"),
      );
      final decoded = _jsonDecodeBody(res, 'getCycles');
      if (decoded is! List) {
        throw Exception('getCycles: expected list, got ${decoded.runtimeType}');
      }
      return decoded;
    } catch (e, st) {
      debugPrint('ApiService.getCycles: $e\n$st');
      rethrow;
    }
  }

  Future<List<dynamic>> getPayments(String cycleId) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/get-payment-of-cycle/$cycleId"),
      );
      final decoded = _jsonDecodeBody(res, 'getPayments');
      if (decoded is! List) {
        throw Exception('getPayments: expected list, got ${decoded.runtimeType}');
      }
      return decoded;
    } catch (e, st) {
      debugPrint('ApiService.getPayments: $e\n$st');
      rethrow;
    }
  }

  Future<dynamic> getProfile() async {
    try {
      await init();
      final response = await _dioExpectOk(
        () => dio.get("/getprofile"),
        'getProfile',
      );
      return response.data;
    } catch (e, st) {
      debugPrint('ApiService.getProfile: $e\n$st');
      rethrow;
    }
  }

  Future<String> verifyLogin() async {
    try {
      await init();
      final response = await _dioExpectOk(
        () => dio.post("/verify-login"),
        'verifyLogin',
      );
      return response.data.toString();
    } catch (e, st) {
      debugPrint('ApiService.verifyLogin: $e\n$st');
      return 'Error: $e';
    }
  }

  Future<void> logout() async {
    try {
      await init();
      await _dioExpectOk(() => dio.get("/logout"), 'logout');
    } catch (e, st) {
      debugPrint('ApiService.logout: $e\n$st');
      rethrow;
    }
  }

  Future<List<dynamic>> getJoinedCommittees(String userId) async {
    try {
      final response = await _dioExpectOk(
        () => dio.get("/get-all-joined-committees/$userId"),
        'getJoinedCommittees',
      );
      final data = response.data;
      if (data is! List) {
        throw Exception('getJoinedCommittees: expected list, got ${data.runtimeType}');
      }
      return data;
    } catch (e, st) {
      debugPrint('ApiService.getJoinedCommittees: $e\n$st');
      rethrow;
    }
  }

  Future<List<dynamic>> getThisMonthDues({
    required String committeeId,
    required String committeeMemberId,
  }) async {
    try {
      final response = await _dioExpectOk(
        () => dio.post(
          "/this-month-dues",
          data: {
            "today": DateTime.now().toIso8601String(),
            "committee_id": committeeId,
            "committee_member_id": committeeMemberId,
          },
        ),
        'getThisMonthDues',
      );
      final data = response.data;
      if (data is! List) {
        throw Exception('getThisMonthDues: expected list, got ${data.runtimeType}');
      }
      return data;
    } catch (e, st) {
      debugPrint('ApiService.getThisMonthDues: $e\n$st');
      rethrow;
    }
  }

  Future<String> signup({
    required String name,
    required String phone,
    required String password,
    required String income,
    File? imageFile,
  }) async {
    try {
      await init();

      FormData formData = FormData.fromMap({
        "name": name,
        "phoneno": phone,
        "password": password,
        "monthly_income": income,
        if (imageFile != null)
          "profile_img": await MultipartFile.fromFile(
            imageFile.path,
            filename: _basename(imageFile.path),
          ),
      });

      final response = await _dioExpectOk(
        () => dio.post("/create_user", data: formData),
        'signup',
      );
      return response.data.toString();
    } catch (e, st) {
      debugPrint('ApiService.signup: $e\n$st');
      return 'Error: $e';
    }
  }

  Future<List<dynamic>> getCommitteesByPhone(String phone) async {
    try {
      final response = await _dioExpectOk(
        () => dio.get("/committee-of-this-no/$phone"),
        'getCommitteesByPhone',
      );
      final data = response.data;
      if (data is! List) {
        throw Exception('getCommitteesByPhone: expected list, got ${data.runtimeType}');
      }
      return data;
    } catch (e, st) {
      debugPrint('ApiService.getCommitteesByPhone: $e\n$st');
      rethrow;
    }
  }

  Future<String> createCommittee({
    required String name,
    required String amount,
    required DateTime startDate,
    required String daysGap,
    required String deadlineDay,
    required String committeeType,
    required String arrangeType,
    required String leavingType,
    required String adminId,
  }) async {
    try {
      final response = await _dioExpectOk(
        () => dio.post(
          "/shared-committee",
          data: {
            "committee_name": name,
            "amount": int.parse(amount),
            "start_date": startDate.toIso8601String(),
            "days_gap": int.parse(daysGap),
            "deadline_day": int.parse(deadlineDay),
            "committee_type": committeeType,
            "members_arrange_type": arrangeType,
            "committee_leaving_type": leavingType,
            "admin_id": adminId,
          },
        ),
        'createCommittee',
      );
      return response.data.toString();
    } catch (e, st) {
      debugPrint('ApiService.createCommittee: $e\n$st');
      return 'Error: $e';
    }
  }

  Future<String> sendJoinRequest({
    required String committeeId,
    required String adminId,
    required String userId,
    required int selectedNumber,
  }) async {
    try {
      final response = await _dioExpectOk(
        () => dio.post(
          "/join-request",
          data: {
            "committee_id": committeeId,
            "admin_id": adminId,
            "user_id": userId,
            "number_of_committee": selectedNumber,
          },
        ),
        'sendJoinRequest',
      );
      return response.data.toString();
    } catch (e, st) {
      debugPrint('ApiService.sendJoinRequest: $e\n$st');
      return 'Error: $e';
    }
  }

  Future<dynamic> findUser(String phone) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/invite-member/$phone"),
      );
      if (res.statusCode != 200) {
        debugPrint('findUser: HTTP ${res.statusCode}');
        return null;
      }
      if (res.body.isEmpty) return null;
      return jsonDecode(res.body);
    } catch (e, st) {
      debugPrint('ApiService.findUser: $e\n$st');
      return null;
    }
  }

  Future<List<dynamic>> getMembers(String committeeId) async {
    try {
      final response = await _dioExpectOk(
        () => dio.get("/get-all-members-of-committee/$committeeId"),
        'getMembers',
      );
      final data = response.data;
      if (data is! List) {
        throw Exception('getMembers: expected list, got ${data.runtimeType}');
      }
      return data;
    } catch (e, st) {
      debugPrint('ApiService.getMembers: $e\n$st');
      rethrow;
    }
  }

  Future<List<dynamic>> getAdminCommittees(String userId) async {
    try {
      final response = await _dioExpectOk(
        () => dio.get("/get-all-committees-of-admin/$userId"),
        'getAdminCommittees',
      );
      final data = response.data;
      if (data is! List) {
        throw Exception('getAdminCommittees: expected list, got ${data.runtimeType}');
      }
      return data;
    } catch (e, st) {
      debugPrint('ApiService.getAdminCommittees: $e\n$st');
      rethrow;
    }
  }

  Future<dynamic> deleteCommittee(String id) async {
    try {
      final response = await _dioExpectOk(
        () => dio.delete("/delete-committee/$id"),
        'deleteCommittee',
      );
      return response.data;
    } catch (e, st) {
      debugPrint('ApiService.deleteCommittee: $e\n$st');
      rethrow;
    }
  }

  Future<void> approvePayment(
    String cycleId,
    String memberId,
    String userId,
    String committeeId,
  ) async {
    try {
      final res = await http.put(
        Uri.parse("$baseUrl/approve-payment"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "cycle_id": cycleId,
          "member_id": memberId,
          "user_id": userId,
          "committee_id": committeeId,
        }),
      );
      _throwIfBadStatus(res, 'approvePayment');
    } catch (e, st) {
      debugPrint('ApiService.approvePayment: $e\n$st');
      rethrow;
    }
  }

  Future<void> rejectPayment(
    String cycleId,
    String memberId,
    String userId,
    String committeeId,
    String reason,
  ) async {
    try {
      final res = await http.put(
        Uri.parse("$baseUrl/reject-payment"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "cycle_id": cycleId,
          "member_id": memberId,
          "user_id": userId,
          "committee_id": committeeId,
          "message": "Payment rejected.\nReason: $reason"
        }),
      );
      _throwIfBadStatus(res, 'rejectPayment');
    } catch (e, st) {
      debugPrint('ApiService.rejectPayment: $e\n$st');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAllAdminCommittees(String id) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/get-all-admin-committees/$id"),
      );
      final decoded = _jsonDecodeBody(response, 'getAllAdminCommittees');
      if (decoded is! Map) {
        throw Exception('getAllAdminCommittees: expected map, got ${decoded.runtimeType}');
      }
      return Map<String, dynamic>.from(decoded);
    } catch (e, st) {
      debugPrint('ApiService.getAllAdminCommittees: $e\n$st');
      rethrow;
    }
  }

  Future<dynamic> createPersonalCommittee(Map data) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/personal-committee"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );
      _throwIfBadStatus(response, 'createPersonalCommittee');
      try {
        return jsonDecode(response.body);
      } catch (_) {
        return response.body;
      }
    } catch (e, st) {
      debugPrint('ApiService.createPersonalCommittee: $e\n$st');
      rethrow;
    }
  }

  Future<dynamic> getPersonalProgress(String id) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/personal-progress/$id"),
      );
      return _jsonDecodeBody(response, 'getPersonalProgress');
    } catch (e, st) {
      debugPrint('ApiService.getPersonalProgress: $e\n$st');
      rethrow;
    }
  }

  Future<dynamic> createSharedCommittee(Map data) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/shared-committee"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );
      _throwIfBadStatus(response, 'createSharedCommittee');
      try {
        return jsonDecode(response.body);
      } catch (_) {
        return response.body;
      }
    } catch (e, st) {
      debugPrint('ApiService.createSharedCommittee: $e\n$st');
      rethrow;
    }
  }

  Future<dynamic> personalPay(String committeeId, int cycleNo) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/personal-pay"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "committee_id": committeeId,
          "cycle_no": cycleNo,
        }),
      );
      return _jsonDecodeBody(response, 'personalPay');
    } catch (e, st) {
      debugPrint('ApiService.personalPay: $e\n$st');
      rethrow;
    }
  }

  Future<List<dynamic>> getRefunds(String committeeId) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/get-all-refunds/$committeeId"),
      );
      final decoded = _jsonDecodeBody(res, 'getRefunds');
      if (decoded is! List) {
        throw Exception('getRefunds: expected list, got ${decoded.runtimeType}');
      }
      return decoded;
    } catch (e, st) {
      debugPrint('ApiService.getRefunds: $e\n$st');
      rethrow;
    }
  }

  Future<List<dynamic>> getMembersForAdminTransfer(
    String committeeId,
    String adminId,
  ) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/get-all-member-comittee"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "committee_id": committeeId,
          "admin_id": adminId,
        }),
      );
      final decoded = _jsonDecodeBody(res, 'getMembersForAdminTransfer');
      if (decoded is! List) {
        throw Exception(
          'getMembersForAdminTransfer: expected list, got ${decoded.runtimeType}',
        );
      }
      return decoded;
    } catch (e, st) {
      debugPrint('ApiService.getMembersForAdminTransfer: $e\n$st');
      rethrow;
    }
  }

  Future<void> transferAdmin(
    String committeeId,
    String oldAdminId,
    String newAdminId,
  ) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/new-committee-admin"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "committee_id": committeeId,
          "old_admin_id": oldAdminId,
          "new_admin_id": newAdminId,
        }),
      );
      _throwIfBadStatus(res, 'transferAdmin');
    } catch (e, st) {
      debugPrint('ApiService.transferAdmin: $e\n$st');
      rethrow;
    }
  }

  Future<void> approveRefund(Map data) async {
    try {
      var request = http.MultipartRequest(
        "PUT",
        Uri.parse("$baseUrl/pay-refund"),
      );

      request.fields.addAll({
        "committee_id": data["committee_id"].toString(),
        "user_id": data["user_id"].toString(),
        "payment_type": data["payment_type"].toString(),
        "message": data["message"].toString(),
        "amount": data["amount"].toString(),
        "committee_detail": jsonEncode(data["committee_detail"]),
      });

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);
      _throwIfBadStatus(res, 'approveRefund');
    } catch (e, st) {
      debugPrint('ApiService.approveRefund: $e\n$st');
      rethrow;
    }
  }

  Future<void> rejectRefund(Map data) async {
    try {
      final res = await http.put(
        Uri.parse("$baseUrl/reject-refund"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );
      _throwIfBadStatus(res, 'rejectRefund');
    } catch (e, st) {
      debugPrint('ApiService.rejectRefund: $e\n$st');
      rethrow;
    }
  }

  Future<List<dynamic>> getAllMembers(String committeeId) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/get-all-members-of-committee/$committeeId"),
      );
      final decoded = _jsonDecodeBody(res, 'getAllMembers');
      if (decoded is! List) {
        throw Exception('getAllMembers: expected list, got ${decoded.runtimeType}');
      }
      return decoded;
    } catch (e, st) {
      debugPrint('ApiService.getAllMembers: $e\n$st');
      rethrow;
    }
  }

  Future<void> incrementRating(String userId, String memberId) async {
    try {
      final res = await http.put(
        Uri.parse("$baseUrl/increment-member-rating"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "member_id": memberId,
        }),
      );
      _throwIfBadStatus(res, 'incrementRating');
    } catch (e, st) {
      debugPrint('ApiService.incrementRating: $e\n$st');
      rethrow;
    }
  }

  Future<void> decrementRating(String userId, String memberId) async {
    try {
      final res = await http.put(
        Uri.parse("$baseUrl/decrement-member-rating"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "member_id": memberId,
        }),
      );
      _throwIfBadStatus(res, 'decrementRating');
    } catch (e, st) {
      debugPrint('ApiService.decrementRating: $e\n$st');
      rethrow;
    }
  }

  Future<List<dynamic>> getRemainingMembers(String committeeId) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/remaining-members/$committeeId"),
      );
      final decoded = _jsonDecodeBody(res, 'getRemainingMembers');
      if (decoded is! List) {
        throw Exception(
          'getRemainingMembers: expected list, got ${decoded.runtimeType}',
        );
      }
      return decoded;
    } catch (e, st) {
      debugPrint('ApiService.getRemainingMembers: $e\n$st');
      rethrow;
    }
  }

  Future<dynamic> getCurrentWinner(String committeeId) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/current-cycle-committee-winner"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "today": DateTime.now().toIso8601String(),
          "committee_id": committeeId,
        }),
      );
      _throwIfBadStatus(res, 'getCurrentWinner');
      if (res.body.isEmpty || res.body == 'null') return null;
      return jsonDecode(res.body);
    } catch (e, st) {
      debugPrint('ApiService.getCurrentWinner: $e\n$st');
      rethrow;
    }
  }

  Future<dynamic> placeBid(
    String committeeId,
    String amount,
    String memberId,
  ) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/current-bidding-cycle"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "committee_id": committeeId,
          "member_id": memberId,
          "amount": int.parse(amount),
        }),
      );
      _throwIfBadStatus(res, 'placeBid');
      try {
        return jsonDecode(res.body);
      } catch (_) {
        return res.body;
      }
    } catch (e, st) {
      debugPrint('ApiService.placeBid: $e\n$st');
      rethrow;
    }
  }

  Future<void> paymentHandle({
    required Map committee,
    required String memberId,
    required String cycleId,
    required String paymentType,
    File? imageFile,
  }) async {
    try {
      var request = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/payment-handle"),
      );

      request.fields["payment_type"] = paymentType;
      request.fields["member_id"] = memberId;
      request.fields["committee_detail"] = jsonEncode(committee);

      request.fields["cycle_id"] = cycleId;

      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            "payment_img",
            imageFile.path,
          ),
        );
      }

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);
      _throwIfBadStatus(res, 'paymentHandle');
    } catch (e, st) {
      debugPrint('ApiService.paymentHandle: $e\n$st');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getHighestBidder(String committeeId) async {
    try {
      final res = await http.get(
        Uri.parse(
          "$baseUrl/current-cycle-winner-bidder-of-committee/$committeeId",
        ),
      );
      if (res.statusCode == 404) return null;
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('getHighestBidder: HTTP ${res.statusCode} ${res.body}');
      }
      if (res.body.isEmpty) return null;
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return null;
    } catch (e, st) {
      debugPrint('ApiService.getHighestBidder: $e\n$st');
      return null;
    }
  }

  Future<String> exitCommittee(Map committeeData) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/exit-committee"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(committeeData),
      );
      _throwIfBadStatus(res, 'exitCommittee');
      return res.body;
    } catch (e, st) {
      debugPrint('ApiService.exitCommittee: $e\n$st');
      rethrow;
    }
  }
}
