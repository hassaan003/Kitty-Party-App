import 'package:flutter/material.dart';
import 'package:kittypartyapp/screens/admin_committee_screen.dart';
import 'package:kittypartyapp/screens/committee_detail.dart';
import 'package:kittypartyapp/screens/create_party_screen.dart';
import 'package:kittypartyapp/screens/join_party_screen.dart';
import 'package:kittypartyapp/screens/login_screen.dart';
import 'package:kittypartyapp/screens/notification_screen.dart';
import 'package:kittypartyapp/screens/personal_committee_admin_screen.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoading = true;
  Map<String, dynamic>? userData;
  List<dynamic> committees = [];
  List<dynamic> dues = [];
  List adminCommittees = [];

  @override
  void initState() {
    super.initState();
    print("Yahn aya");
    print(isLoading);
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    try {
      var profile = await ApiService().getProfile();

      var joined = await ApiService().getJoinedCommittees(profile["_id"]);

      Map<String, dynamic> response = await ApiService().getAllAdminCommittees(
        profile["_id"],
      );
      print("heelo");
      print(response);

      List<dynamic> shared = response["shared"] ?? [];
      List<dynamic> personal = response["personal"] ?? [];

      List<dynamic> created = [...shared, ...personal];

      if (!mounted) return;

      setState(() {
        userData = profile;
        committees = joined;
        adminCommittees = created;
        isLoading = false;
      });
    } catch (e) {
      print("ERROR: $e");

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              child: Text(
                "Kitty Party",
                style: TextStyle(color: Colors.white, fontSize: 22),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: () async {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),

      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// HEADER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Kitty Party",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        Builder(
                          builder: (context) => IconButton(
                            icon: const Icon(Icons.menu, size: 28),
                            onPressed: () {
                              Scaffold.of(context).openDrawer();
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    /// PROFILE ROW
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundImage: userData != null
                              ? NetworkImage(
                                  (() {
                                    String img = userData!["profile_img"] ?? "";

                                    if (img.startsWith("http")) {
                                      return img;
                                    } else if (img.startsWith("/")) {
                                      return "http://192.168.18.99:8080$img";
                                    } else {
                                      return "http://192.168.18.99:8080/$img";
                                    }
                                  })(),
                                )
                              : null,
                          child: userData == null
                              ? const Icon(Icons.person) // fallback icon
                              : null,
                        ),
                        const SizedBox(width: 15),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  color: Colors.orange,
                                  size: 18,
                                ),
                                Icon(
                                  Icons.star,
                                  color: Colors.orange,
                                  size: 18,
                                ),
                                Icon(
                                  Icons.star,
                                  color: Colors.orange,
                                  size: 18,
                                ),
                                Icon(
                                  Icons.star,
                                  color: Colors.orange,
                                  size: 18,
                                ),
                                Icon(
                                  Icons.star,
                                  color: Colors.orange,
                                  size: 18,
                                ),
                              ],
                            ),

                            const SizedBox(height: 5),

                            Text(
                              "Welcome ${userData?["name"] ?? ""}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),

                            Text(
                              "User id : ${userData?['phoneno'] ?? 'N/A'}",
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    /// BUTTONS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CreateCommitteeScreen(
                                  userId: userData!["_id"],
                                ),
                              ),
                            );
                          },
                          child: const Text("Create Party"),
                        ),

                        ElevatedButton(
                          onPressed: () {
                            if (userData != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      JoinPartyScreen(userData: userData!),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text("Join Party"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    const Text(
                      "Joined Committees",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    committees.isEmpty
                        ? const Text("No Joined Committees")
                        : Column(
                            children: committees.map((item) {
                              var committee = item["committee_details"];
                              if (committee == null) return const SizedBox();

                              return Container(
                                margin: const EdgeInsets.only(bottom: 15),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      committee["committee_name"] ?? "No Name",
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                CommitteeDetailScreen(
                                                  committee: committee,
                                                ),
                                          ),
                                        );
                                      },
                                      child: const Text("Open"),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),

                    const SizedBox(height: 30),

                    const Text(
                      "Your Created Committees",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    adminCommittees.isEmpty
                        ? const Text("No Created Committees")
                        : Column(
                            children: adminCommittees.map((committee) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 15),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      committee["committee_name"],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),

                                    ElevatedButton(
                                      onPressed: () {
                                        bool isPersonal =
                                            committee["total_cycle"] != null;

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => isPersonal
                                                ? PersonalCommitteeAdminScreen(
                                                    committee: committee,
                                                  )
                                                : AdminCommitteeScreen(
                                                    committee: committee,
                                                  ),
                                          ),
                                        );
                                      },
                                      child: const Text("Manage"),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: () async {
                        print("ADMIN ID: ${userData!["_id"]}");
                        final data = await ApiService().getJoinRequests(
                          userData!["_id"],
                        );
                        if (!mounted) return;

                        showDialog(
                          // ignore: use_build_context_synchronously
                          context: context,
                          builder: (dialogContext) {
                            return StatefulBuilder(
                              builder: (context, setDialogState) {
                                return AlertDialog(
                                  title: const Text("Join Requests"),
                                  content: SizedBox(
                                    width: double.maxFinite,
                                    child: data.isEmpty
                                        ? const Text("No Requests")
                                        : ListView(
                                            shrinkWrap: true,
                                            children: data.map<Widget>((req) {
                                              final user = req["user_detail"];

                                              return ListTile(
                                                title: Text(user["name"]),
                                                subtitle: Text(
                                                  "Requested Slots: ${req["number_of_committee"]}",
                                                ),

                                                trailing: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    ElevatedButton(
                                                      onPressed: () async {
                                                        await ApiService()
                                                            .approveRequest(
                                                              req["_id"],
                                                            );

                                                        if (!mounted) return;

                                                        final updatedData =
                                                            await ApiService()
                                                                .getJoinRequests(
                                                                  req["admin_id"], // ✅ FIX
                                                                );

                                                        if (!mounted) return;

                                                        data.clear();
                                                        data.addAll(
                                                          updatedData,
                                                        );

                                                        setDialogState(() {});
                                                        if (!mounted) return;

                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          const SnackBar(
                                                            content: Text(
                                                              "Approved",
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                      child: const Text(
                                                        "Accept",
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    ElevatedButton(
                                                      onPressed: () async {
                                                        await ApiService()
                                                            .rejectRequest(
                                                              req["_id"],
                                                            );

                                                        data.remove(
                                                          req,
                                                        ); // 🔥 remove instantly
                                                        setDialogState(() {});
                                                        if (!mounted) return;

                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          const SnackBar(
                                                            content: Text(
                                                              "Rejected",
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                      style:
                                                          ElevatedButton.styleFrom(
                                                            backgroundColor:
                                                                Colors.red,
                                                          ),
                                                      child: const Text(
                                                        "Reject",
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                      child: const Text("View Requests"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NotificationScreen(),
                          ),
                        );
                      },
                      child: const Text("Notifications"),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
