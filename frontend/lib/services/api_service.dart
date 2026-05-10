import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'dart:convert';
import 'package:http/http.dart' as http;


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
        baseUrl: "http://192.168.18.99:8080",
        headers: {"Content-Type": "application/json"},
        validateStatus: (status) => true,
      ),
    );

    dio.interceptors.add(CookieManager(cookieJar));

    _isInitialized = true;
  }

  Future<String> login(String phone, String password) async {
    await init();

    final response = await dio.post(
      "/login",
      data: {"phoneno": phone, "password": password},
    );

    return response.data.toString();
  }



Future getNotifications(String userId) async {
  final res = await http.get(
    Uri.parse("$baseUrl/get-notifications/$userId"),
  );

  return jsonDecode(res.body);
}

Future<String> approveJoinRequest(
  String notificationId,
) async {

  final res = await http.post(
    Uri.parse(
      "$baseUrl/approve-join-request/$notificationId",
    ),
  );

  return res.body;
}

Future<String> rejectJoinRequest(
  String notificationId,
) async {

  final res = await http.post(
    Uri.parse(
      "$baseUrl/reject-join-request/$notificationId",
    ),
  );

  return res.body;
}

Future<String> acceptInvite(
  String notificationId,
) async {

  final res = await http.post(
    Uri.parse(
      "$baseUrl/accept-invite/$notificationId",
    ),
  );

  return res.body;
}

Future<String> clearNotification(
  String id,
) async {

  final res = await http.delete(
    Uri.parse(
      "$baseUrl/clear-notification/$id",
    ),
  );

  return res.body;
}

Future<List> getCycles(String committeeId) async {
  final res = await http.get(
    Uri.parse("$baseUrl/all-cycle-till-now-committee/$committeeId"),
  );
  return jsonDecode(res.body);
}

Future<List> getPayments(String cycleId) async {
  final res = await http.get(
    Uri.parse("$baseUrl/get-payment-of-cycle/$cycleId"),
  );
  return jsonDecode(res.body);
}

  Future<dynamic> getProfile() async {
    await init();

    print("CALLING GET PROFILE");

    final response = await dio.get("/getprofile");

    print('API Response: $response');

    return response.data;
  }

  Future<String> verifyLogin() async {
    await init();
    final response = await dio.post("/verify-login");
    return response.data.toString();
  }

  Future<void> logout() async {
    await init();
    await dio.get("/logout");
  }

  Future<List<dynamic>> getJoinedCommittees(String userId) async {
    await init();

    final response = await dio.get("/get-all-joined-committees/$userId");

    return response.data;
  }

  Future<List<dynamic>> getThisMonthDues({
    required String committeeId,
    required String committeeMemberId,
  }) async {
    await init();

    final response = await dio.post(
      "/this-month-dues",
      data: {
        "today": DateTime.now().toIso8601String(),
        "committee_id": committeeId,
        "committee_member_id": committeeMemberId,
      },
    );

    return response.data;
  }

  Future<String> signup({
    required String name,
    required String phone,
    required String password,
    required String income,
    File? imageFile,
  }) async {
    await init();

    FormData formData = FormData.fromMap({
      "name": name,
      "phoneno": phone,
      "password": password,
      "monthly_income": income,
      if (imageFile != null)
        "profile_img": await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
    });

    final response = await dio.post("/create_user", data: formData);

    return response.data.toString();
  }
Future<List<dynamic>> getCommitteesByPhone(String phone) async {
  await init();

  final response = await dio.get(
    "/committee-of-this-no/$phone",
  );

  return response.data;
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
  await init();

  final response = await dio.post(
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
      "admin_id": adminId, // ✅ NOW CORRECT
    },
  );

  return response.data.toString();
}



Future<String> sendJoinRequest({

  required String committeeId,
  required String adminId,
  required String userId,
  required int selectedNumber,

}) async {

  await init();

  final response = await dio.post(

    "/join-request",

    data: {

      "committee_id": committeeId,

      "admin_id": adminId,

      "user_id": userId,

      "number_of_committee": selectedNumber,
    },
  );

  return response.data.toString();
}

Future<dynamic> findUser(String phone) async {
  final res = await http.get(
    Uri.parse("http://localhost:3000/invite-member/$phone"),
  );

  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  }
  return null;
}



Future<List<dynamic>> getMembers(String committeeId) async {
  await init();

  final response = await dio.get(
    "/get-all-members-of-committee/$committeeId",
  );

  return response.data;
}

Future<List<dynamic>> getAdminCommittees(String userId) async {
  await init();

  final response = await dio.get(
    "/get-all-committees-of-admin/$userId",
  );

  return response.data;
}

Future deleteCommittee(String id) async {
  await init();

  final response = await dio.delete("/delete-committee/$id");

  return response.data;
}

Future approvePayment(String cycleId,
  String memberId,
  String userId,
  String committeeId,) async {
  await http.put(
    Uri.parse("$baseUrl/approve-payment"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "cycle_id": cycleId,
      "member_id": memberId,
      "user_id": userId,
      "committee_id": committeeId,
    }),
  );
}

Future rejectPayment(
  String cycleId,
  String memberId,
  String userId,
  String committeeId,
  String reason,
) async {
  await http.put(
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
}

Future<dynamic> getAllAdminCommittees(String id) async {
  final response = await http.get(
    Uri.parse("$baseUrl/get-all-admin-committees/$id"),
  );

  return jsonDecode(response.body);
}


Future<dynamic> createPersonalCommittee(Map data) async {
  final response = await http.post(
    Uri.parse("$baseUrl/personal-committee"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(data),
  );

  try {
    return jsonDecode(response.body);
  } catch (e) {
    return response.body; // plain text support
  }
}

Future<dynamic> getPersonalProgress(String id) async {
  final response = await http.get(
    Uri.parse("$baseUrl/personal-progress/$id"),
  );

  return jsonDecode(response.body);
}

Future<dynamic> createSharedCommittee(Map data) async {
  final response = await http.post(
    Uri.parse("$baseUrl/shared-committee"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(data),
  );

  try {
    return jsonDecode(response.body);
  } catch (e) {
    return response.body; // plain text support
  }
}

Future<dynamic> personalPay(
    String committeeId,
    int cycleNo,
) async {
  final response = await http.post(
    Uri.parse("$baseUrl/personal-pay"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "committee_id": committeeId,
      "cycle_no": cycleNo,
    }),
  );

  return jsonDecode(response.body);
}

Future<List> getRefunds(String committeeId) async {
  final res = await http.get(
    Uri.parse("$baseUrl/get-all-refunds/$committeeId"),
  );
  return jsonDecode(res.body);
}

Future<List> getMembersForAdminTransfer(
    String committeeId, String adminId) async {
  final res = await http.post(
    Uri.parse("$baseUrl/get-all-member-comittee"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "committee_id": committeeId,
      "admin_id": adminId,
    }),
  );

  return jsonDecode(res.body);
}

Future transferAdmin(
    String committeeId, String oldAdminId, String newAdminId) async {
  await http.post(
    Uri.parse("$baseUrl/new-committee-admin"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "committee_id": committeeId,
      "old_admin_id": oldAdminId,
      "new_admin_id": newAdminId,
    }),
  );
}

Future approveRefund(Map data) async {
  var request = http.MultipartRequest(
    "PUT",
    Uri.parse("$baseUrl/pay-refund"),
  );

  request.fields.addAll({
    "committee_id": data["committee_id"],
    "user_id": data["user_id"],
    "payment_type": data["payment_type"],
    "message": data["message"],
    "amount": data["amount"].toString(),
    "committee_detail": jsonEncode(data["committee_detail"]),
  });

  await request.send();
}

Future rejectRefund(Map data) async {
  await http.put(
    Uri.parse("$baseUrl/reject-refund"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(data),
  );
}



Future<List> getAllMembers(String committeeId) async {
  final res = await http.get(
    Uri.parse("$baseUrl/get-all-members-of-committee/$committeeId"),
  );
  return jsonDecode(res.body);
}

Future incrementRating(String userId, String memberId) async {
  await http.put(
    Uri.parse("$baseUrl/increment-member-rating"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "user_id": userId,
      "member_id": memberId,
    }),
  );
}
Future decrementRating(String userId, String memberId) async {
  await http.put(
    Uri.parse("$baseUrl/decrement-member-rating"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "user_id": userId,
      "member_id": memberId,
    }),
  );
}

Future<List<dynamic>> getRemainingMembers(String committeeId) async {
  final res = await http.get(
    Uri.parse("$baseUrl/remaining-members/$committeeId"),
  );

  return jsonDecode(res.body);
}

Future<dynamic> getCurrentWinner(String committeeId) async {
  final res = await http.post(
    Uri.parse("$baseUrl/current-cycle-committee-winner"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "today": DateTime.now().toIso8601String(),
      "committee_id": committeeId,
    }),
  );

  return jsonDecode(res.body);
}

Future<dynamic> placeBid(
  String committeeId,
  String amount,
) async {
  final res = await http.post(
    Uri.parse("$baseUrl/current-bidding-cycle"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "committee_id": committeeId,
      "amount": int.parse(amount),
    }),
  );

  try {
    return jsonDecode(res.body);
  } catch (e) {
    return res.body;
  }
}

Future paymentHandle({
  required Map committee,
  required String memberId,
  required String cycleId,
  required String paymentType,
  File? imageFile,
}) async {
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

  await request.send();
}

Future<dynamic> getHighestBidder(String committeeId) async {
  final res = await http.get(
    Uri.parse("$baseUrl/current-cycle-winner-bidder-of-committee/$committeeId"),
  );

  try {
    return jsonDecode(res.body);
  } catch (e) {
    return null;
  }
}

Future<dynamic> exitCommittee(Map committeeData) async {
  final res = await http.post(
    Uri.parse("$baseUrl/exit-committee"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(committeeData),
  );

  return res.body;
}

}
