import 'package:flutter/material.dart';
import '../services/api_service.dart';

class JoinPartyScreen extends StatefulWidget {

  final Map userData;

  const JoinPartyScreen({
    super.key,
    required this.userData,
  });

  @override
  State<JoinPartyScreen> createState() =>
      _JoinPartyScreenState();
}

class _JoinPartyScreenState
    extends State<JoinPartyScreen> {

  final TextEditingController
      phoneController =
      TextEditingController();

  late Map userData;

  List committees = [];

  bool isLoading = false;

  // committeeId -> selected count
  Map<String, int> selectedNumbers = {};

  @override
  void initState() {
    super.initState();
    userData = widget.userData;
  }

  // =========================
  // SEARCH
  // =========================

  void searchCommittees() async {

    setState(() {
      isLoading = true;
    });

    final data =
        await ApiService()
            .getCommitteesByPhone(
      phoneController.text,
    );

    if (!mounted) return;

    setState(() {

      committees = data;

      isLoading = false;
    });
  }

  // =========================
  // JOIN REQUEST
  // =========================

  void joinCommittee(
    Map committee,
    int selectedNumber,
  ) async {

    final String userId =
        userData["_id"];

    final String committeeId =
        committee["committee_detail"]["_id"];

    final String adminId =
        committee["committee_detail"]["admin_id"];

    final response =
        await ApiService()
            .sendJoinRequest(

      committeeId: committeeId,

      adminId: adminId,

      userId: userId,

      selectedNumber:
          selectedNumber,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(response),
      ),
    );
  }

  // =========================
  // COMMITTEE TYPE
  // =========================

  String getCommitteeType(dynamic type) {

  int parsedType = int.parse(type.toString());

  if (parsedType == 1) {
    return "Simple";
  }

  if (parsedType == 2) {
    return "Bidding";
  }

  if (parsedType == 3) {
    return "Spin";
  }

  return "Unknown";
}

  // =========================
  // UI
  // =========================

  @override
  Widget build(
      BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title:
            const Text("Join Party"),
      ),

      body: Padding(

        padding:
            const EdgeInsets.all(20),

        child: Column(

          children: [

            // =====================
            // PHONE FIELD
            // =====================

            TextField(

              controller:
                  phoneController,

              decoration:
                  const InputDecoration(

                labelText:
                    "Enter Admin Phone Number",

                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(
                height: 14),

            // =====================
            // SEARCH BUTTON
            // =====================

            SizedBox(

              width: double.infinity,

              child: ElevatedButton(

                onPressed:
                    searchCommittees,

                child:
                    const Text("Search"),
              ),
            ),

            const SizedBox(
                height: 20),

            // =====================
            // BODY
            // =====================

            isLoading

                ? const Expanded(
                    child: Center(
                      child:
                          CircularProgressIndicator(),
                    ),
                  )

                : committees.isEmpty

                    ? const Expanded(
                        child: Center(
                          child: Text(
                            "No Committees Found",
                          ),
                        ),
                      )

                    : Expanded(

                        child:
                            ListView.builder(

                          itemCount:
                              committees.length,

                          itemBuilder:
                              (context, index) {

                            final committee =
                                committees[index];

                            final detail =
                                committee[
                                    "committee_detail"];

                            final String id =
                                detail["_id"];

                            selectedNumbers[id] ??=
                                1;

                            return Card(

                              margin:
                                  const EdgeInsets.only(
                                bottom: 16,
                              ),

                              elevation: 3,

                              child: Padding(

                                padding:
                                    const EdgeInsets.all(
                                  16,
                                ),

                                child: Column(

                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,

                                  children: [

                                    // =================
                                    // NAME
                                    // =================

                                    Text(

                                      detail[
                                          "committee_name"],

                                      style:
                                          const TextStyle(
                                        fontSize: 20,
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(
                                        height: 10),

                                    // =================
                                    // TYPE
                                    // =================

                                    Text(
                                      "Type: ${getCommitteeType(detail["committee_type"])}",
                                    ),

                                    const SizedBox(
                                        height: 6),

                                    // =================
                                    // AMOUNT
                                    // =================

                                    Text(
                                      "Amount: ${detail["amount"]}",
                                    ),

                                    const SizedBox(
                                        height: 6),

                                    // =================
                                    // MEMBERS
                                    // =================

                                    Text(
                                      "Members: ${detail["number_of_member"]}",
                                    ),

                                    const SizedBox(
                                        height: 16),

                                    // =================
                                    // COUNTER
                                    // =================

                                    Row(

                                      children: [

                                        const Text(
                                          "No. of Committees:",
                                        ),

                                        const Spacer(),

                                        IconButton(

                                          onPressed: () {

                                            if ((selectedNumbers[id] ??
                                                    1) >
                                                1) {

                                              setState(() {

                                                selectedNumbers[id] =
                                                    (selectedNumbers[id] ??
                                                            1) -
                                                        1;
                                              });
                                            }
                                          },

                                          icon:
                                              const Icon(
                                            Icons.remove_circle,
                                          ),
                                        ),

                                        Text(

                                          selectedNumbers[id]
                                              .toString(),

                                          style:
                                              const TextStyle(
                                            fontSize:
                                                18,
                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                        ),

                                        IconButton(

                                          onPressed: () {

                                            setState(() {

                                              selectedNumbers[id] =
                                                  (selectedNumbers[id] ??
                                                          1) +
                                                      1;
                                            });
                                          },

                                          icon:
                                              const Icon(
                                            Icons.add_circle,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(
                                        height: 14),

                                    // =================
                                    // REQUEST BUTTON
                                    // =================

                                    SizedBox(

                                      width:
                                          double.infinity,

                                      child:
                                          ElevatedButton(

                                        onPressed: () {

                                          joinCommittee(

                                            committee,

                                            selectedNumbers[
                                                id]!,
                                          );
                                        },

                                        child:
                                            const Text(
                                          "Send Join Request",
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ],
        ),
      ),
    );
  }
}