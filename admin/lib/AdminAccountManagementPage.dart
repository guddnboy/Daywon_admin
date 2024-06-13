import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminAccountManagementPage extends StatefulWidget {
  final String apiUrl;

  const AdminAccountManagementPage({Key? key, required this.apiUrl})
      : super(key: key);

  @override
  _AdminAccountManagementPageState createState() =>
      _AdminAccountManagementPageState();
}

class _AdminAccountManagementPageState
    extends State<AdminAccountManagementPage> {
  List<Account> accounts = [];
  List<Account> filteredAccounts = [];
  int? selectedFilterLevel;

  @override
  void initState() {
    super.initState();
    fetchAccounts();
  }

  Future<void> fetchAccounts() async {
    final response =
        await http.get(Uri.parse('${widget.apiUrl}/read_admins_list/'));
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      setState(() {
        accounts = data.map((json) => Account.fromJson(json)).toList();
        filterAccounts();
      });
    } else {
      throw Exception('Failed to load accounts');
    }
  }

  void filterAccounts() {
    setState(() {
      if (selectedFilterLevel == null) {
        filteredAccounts = accounts;
      } else {
        filteredAccounts = accounts
            .where(
                (account) => account.qualificationLevel == selectedFilterLevel)
            .toList();
      }
    });
  }

  Future<String> updateAccount(Account account) async {
    final url = Uri.parse('${widget.apiUrl}/update_admins/${account.adminId}');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'admin_id': account.adminId,
        'qualification_level': account.qualificationLevel,
        'account_status': account.accountStatus,
      }),
    );

    final responseData = jsonDecode(response.body);
    if (response.statusCode == 200 && responseData['status'] == 'success') {
      return 'success';
    } else {
      return 'error';
    }
  }

  Future<String> createAccount(
      String adminName, String password, int qualificationLevel) async {
    final url = Uri.parse('${widget.apiUrl}/create_admin/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'admin_name': adminName,
        'password': password,
        'qualification_level': qualificationLevel,
        'account_status': true, // Default to active status
      }),
    );

    final responseData = jsonDecode(response.body);
    if (response.statusCode == 200 && responseData['status'] == 'success') {
      return 'success';
    } else {
      return 'error';
    }
  }

  void showResultDialog(String title, String message, bool shouldPopUntilMain) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('확인'),
              onPressed: () {
                if (shouldPopUntilMain) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  fetchAccounts();
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Image.asset(
                      'assets/img/backbtn.png',
                      width: 45,
                      height: 45,
                    ),
                  ),
                  const Text(
                    '계정 관리',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 45, height: 45), // Placeholder for spacing
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  DropdownButton<int>(
                    value: selectedFilterLevel,
                    hint: const Text("레벨 선택: 전체"),
                    items: [
                      DropdownMenuItem<int>(
                        value: null,
                        child: const Text('전체'),
                      ),
                      DropdownMenuItem<int>(
                        value: 1,
                        child: const Text('1'),
                      ),
                      DropdownMenuItem<int>(
                        value: 2,
                        child: const Text('2'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedFilterLevel = value;
                        filterAccounts();
                      });
                    },
                  ),
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          String? adminName;
                          String? password;
                          int? selectedLevel;
                          return AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: const Text('계정 등록'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    labelText: '아이디',
                                  ),
                                  onChanged: (value) {
                                    adminName = value;
                                  },
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  obscureText: true,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    labelText: '비밀번호',
                                  ),
                                  onChanged: (value) {
                                    password = value;
                                  },
                                ),
                                const SizedBox(height: 10),
                                DropdownButtonFormField<int>(
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    labelText: '레벨 선택',
                                  ),
                                  items: [
                                    DropdownMenuItem<int>(
                                      value: 1,
                                      child: const Text('1'),
                                    ),
                                    DropdownMenuItem<int>(
                                      value: 2,
                                      child: const Text('2'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    selectedLevel = value;
                                  },
                                  hint: const Text("레벨"),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                child: const Text('등록'),
                                onPressed: () async {
                                  if (adminName != null &&
                                      password != null &&
                                      selectedLevel != null) {
                                    String result = await createAccount(
                                        adminName!, password!, selectedLevel!);
                                    if (result == 'success') {
                                      fetchAccounts();
                                      showResultDialog(
                                          '성공', '계정이 성공적으로 등록되었습니다.', true);
                                    } else {
                                      showResultDialog(
                                          '실패', '계정 등록에 실패하였습니다.', false);
                                    }
                                  } else {
                                    showResultDialog(
                                        '실패', '모든 필드를 입력해주세요.', false);
                                  }
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: const Text('계정 등록'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white, // 텍스트 색상을 흰색으로 설정
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(0), // 직각 모서리
                      ),
                      minimumSize: const Size(100, 40),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: const [
                          Expanded(
                              child: Center(
                                  child: Text('아이디',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)))),
                          Expanded(
                              child: Center(
                                  child: Text('레벨',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)))),
                          Expanded(
                              child: Center(
                                  child: Text('상태',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)))),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.black),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: filteredAccounts
                              .map((account) => Column(
                                    children: [
                                      AccountRow(
                                        account: account,
                                        onUpdate: (updatedAccount) async {
                                          String result = await updateAccount(
                                              updatedAccount);
                                          showResultDialog(
                                              result == 'success'
                                                  ? '업데이트 완료'
                                                  : '업데이트 실패',
                                              result == 'success'
                                                  ? '업데이트가 완료되었습니다.'
                                                  : '업데이트가 실패하였습니다.',
                                              false);
                                          return result;
                                        },
                                      ),
                                      const Divider(color: Colors.black),
                                    ],
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Account {
  String adminName;
  int qualificationLevel;
  bool accountStatus;
  int adminId;

  Account({
    required this.adminName,
    required this.qualificationLevel,
    required this.accountStatus,
    required this.adminId,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      adminName: json['admin_name'],
      qualificationLevel: json['qualification_level'],
      accountStatus: json['account_status'],
      adminId: json['admin_id'],
    );
  }
}

class AccountRow extends StatefulWidget {
  final Account account;
  final Future<String> Function(Account) onUpdate;

  const AccountRow({Key? key, required this.account, required this.onUpdate})
      : super(key: key);

  @override
  _AccountRowState createState() => _AccountRowState();
}

class _AccountRowState extends State<AccountRow> {
  int? selectedLevel;
  bool isActive = true;

  @override
  void initState() {
    super.initState();
    selectedLevel = widget.account.qualificationLevel;
    isActive = widget.account.accountStatus;
  }

  @override
  void didUpdateWidget(covariant AccountRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.account.qualificationLevel !=
        oldWidget.account.qualificationLevel) {
      selectedLevel = widget.account.qualificationLevel;
    }
    if (widget.account.accountStatus != oldWidget.account.accountStatus) {
      isActive = widget.account.accountStatus;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4.0), // 간격을 줄이기 위해 수정
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: Center(
              child: Text(widget.account.adminName),
            ),
          ),
          Expanded(
            child: Center(
              child: DropdownButton<int>(
                value: selectedLevel,
                hint: const Text("레벨"),
                isExpanded: true,
                items: [
                  DropdownMenuItem<int>(
                    value: 1,
                    child: const Center(child: Text('1')),
                  ),
                  DropdownMenuItem<int>(
                    value: 2,
                    child: const Center(child: Text('2')),
                  ),
                ],
                onChanged: (value) async {
                  final previousLevel = selectedLevel;
                  setState(() {
                    selectedLevel = value;
                  });
                  widget.account.qualificationLevel = value!;
                  final result = await widget.onUpdate(widget.account);
                  if (result != 'success') {
                    setState(() {
                      selectedLevel = previousLevel;
                      widget.account.qualificationLevel = previousLevel!;
                    });
                  }
                },
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Checkbox(
                value: isActive,
                onChanged: (bool? value) async {
                  final previousStatus = isActive;
                  setState(() {
                    isActive = value ?? false;
                  });
                  widget.account.accountStatus = isActive;
                  final result = await widget.onUpdate(widget.account);
                  if (result != 'success') {
                    setState(() {
                      isActive = previousStatus;
                      widget.account.accountStatus = previousStatus;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
